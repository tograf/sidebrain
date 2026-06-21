#!/usr/bin/env python3
"""Normalize a VTT or SRT subtitle file into anchored markdown.

Reads one subtitle file, strips formatting tags, de-duplicates the rolling
repeats typical of auto-captions, and emits paragraphs prefixed with [mm:ss]
time anchors. Stdlib only — no third-party deps, so the captions path needs
nothing beyond Python.

Usage: clean_captions.py <file.vtt|file.srt> [anchor_interval_seconds]
Output: cleaned markdown on stdout.
"""
import re
import sys

TAG_RE = re.compile(r"<[^>]+>")  # <c>, inline <00:00:01.000> word timings, <i> ...
CUE_RE = re.compile(
    r"(\d{1,2}:\d{2}(?::\d{2})?[.,]\d{1,3})\s*-->\s*(\d{1,2}:\d{2}(?::\d{2})?[.,]\d{1,3})"
)
ENTITIES = {
    "&nbsp;": " ", "&amp;": "&", "&lt;": "<", "&gt;": ">",
    "&#39;": "'", "&quot;": '"', "&apos;": "'",
}


def parse_ts(t):
    """HH:MM:SS.mmm / MM:SS.mmm (',' or '.' for the fraction) -> seconds (float)."""
    parts = [p for p in re.split(r"[:.,]", t.strip()) if p != ""]
    if len(parts) == 4:
        h, m, s, ms = parts
    elif len(parts) == 3:
        h, m, s, ms = "0", parts[0], parts[1], parts[2]
    else:
        return 0.0
    return int(h) * 3600 + int(m) * 60 + int(s) + int(ms) / 1000.0


def clean_text(s):
    s = TAG_RE.sub("", s)
    for k, v in ENTITIES.items():
        s = s.replace(k, v)
    return re.sub(r"\s+", " ", s).strip()


def parse_cues(lines):
    """Return [(start_seconds, [text_line, ...])]. Works for both VTT and SRT —
    VTT headers (WEBVTT/NOTE/Kind/Language) and SRT index lines are simply not
    matched by CUE_RE and get skipped."""
    cues = []
    i, n = 0, len(lines)
    while i < n:
        m = CUE_RE.search(lines[i])
        if not m:
            i += 1
            continue
        start = parse_ts(m.group(1))
        i += 1
        texts = []
        while i < n and lines[i].strip() != "" and not CUE_RE.search(lines[i]):
            t = clean_text(lines[i])
            if t:
                texts.append(t)
            i += 1
        cues.append((start, texts))
    return cues


def mmss(sec):
    sec = int(sec)
    h, rem = divmod(sec, 3600)
    m, s = divmod(rem, 60)
    return f"{h}:{m:02d}:{s:02d}" if h else f"{m}:{s:02d}"


def main():
    if len(sys.argv) < 2:
        sys.exit("usage: clean_captions.py <file.vtt|file.srt> [interval_seconds]")
    path = sys.argv[1]
    interval = float(sys.argv[2]) if len(sys.argv) > 2 else 30.0

    with open(path, encoding="utf-8", errors="replace") as f:
        cues = parse_cues(f.read().splitlines())

    paragraphs, cur, cur_anchor = [], [], None
    last_line, next_anchor = None, 0.0
    for start, texts in cues:
        for t in texts:
            if t == last_line:  # collapse the rolling duplicate lines auto-captions emit
                continue
            last_line = t
            if start >= next_anchor:
                if cur:
                    paragraphs.append((cur_anchor, " ".join(cur)))
                    cur = []
                cur_anchor = mmss(start)
                next_anchor = start + interval
            cur.append(t)
    if cur:
        paragraphs.append((cur_anchor, " ".join(cur)))

    out = [(f"[{a}] {txt}" if a is not None else txt) for a, txt in paragraphs]
    print("\n\n".join(out))


if __name__ == "__main__":
    main()
