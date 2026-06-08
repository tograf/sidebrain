#!/usr/bin/env python3
"""Drain Signal Note-to-Self captures into the vault inbox.

Installed by the setup skill to .claude/tools/signal-inbox.py — it must
live exactly there, the vault root is resolved relative to this file.

Runs `signal-cli receive`, keeps only messages the user sent to
themselves (Note to Self), appends them to <inbox>/Signal-Captures.md,
and prints a summary. Claude files the entries during the session-start
inbox check and clears the buffer file afterwards.

Receiving consumes Signal's server-side queue, so everything is parked
in the buffer file first; a crashed session never loses a capture.
"""

import datetime
import json
import pathlib
import subprocess
import sys

# Setup: replace with the vault's ACTUAL inbox folder name (translated
# in non-English vaults).
INBOX_FOLDER = "01-Inbox"

VAULT = pathlib.Path(__file__).resolve().parents[2]
BUFFER = VAULT / INBOX_FOLDER / "Signal-Captures.md"
HEADER = "# Signal Captures\n\nDrained from Note to Self. Claude files these at session start.\n\n---\n"


def receive():
    try:
        proc = subprocess.run(
            ["signal-cli", "-o", "json", "receive", "--timeout", "8"],
            capture_output=True, text=True, timeout=120,
        )
    except FileNotFoundError:
        sys.exit("signal-cli is not installed")
    except subprocess.TimeoutExpired:
        sys.exit("signal-cli receive timed out")
    if proc.returncode != 0:
        sys.exit(f"signal-cli failed: {proc.stderr.strip()}")
    return proc.stdout


def note_to_self_messages(raw):
    """Yield (timestamp, text) for synced messages whose destination is self."""
    for line in raw.splitlines():
        line = line.strip()
        if not line:
            continue
        try:
            event = json.loads(line)
        except json.JSONDecodeError:
            continue
        envelope = event.get("envelope", {})
        sent = envelope.get("syncMessage", {}).get("sentMessage")
        if not sent or sent.get("groupInfo"):
            continue
        # Sync messages are sourced from our own account; only keep the
        # ones addressed to ourselves (Note to Self), not regular
        # outgoing messages to other people.
        own_number = event.get("account")
        own_uuid = envelope.get("sourceUuid")
        dest_number = sent.get("destinationNumber") or sent.get("destination")
        dest_uuid = sent.get("destinationUuid")
        is_self = (own_number and dest_number == own_number) or (
            own_uuid and dest_uuid == own_uuid
        )
        if not is_self:
            continue
        text = sent.get("message")
        if not text:
            continue
        ts = sent.get("timestamp")
        when = (
            datetime.datetime.fromtimestamp(ts / 1000).strftime("%Y-%m-%d %H:%M")
            if ts
            else "unknown time"
        )
        yield when, text


def main():
    captures = list(note_to_self_messages(receive()))
    if not captures:
        print("No new Signal captures.")
        return
    if not BUFFER.exists():
        BUFFER.write_text(HEADER, encoding="utf-8")
    with BUFFER.open("a", encoding="utf-8") as f:
        for when, text in captures:
            f.write(f"\n- `{when}` {text}\n")
    print(f"{len(captures)} new Signal capture(s) appended to {BUFFER.relative_to(VAULT)}:")
    for when, text in captures:
        preview = text if len(text) <= 80 else text[:77] + "..."
        print(f"  [{when}] {preview}")
    print(
        f"\nACTION (Claude): file each capture above per the quick-capture rules in "
        f"CLAUDE.md; treat the rest as inbox notes; then clear "
        f"{BUFFER.relative_to(VAULT)} back to its header."
    )


if __name__ == "__main__":
    main()
