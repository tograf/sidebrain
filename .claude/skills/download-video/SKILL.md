---
name: download-video
description: Download a video from a URL (YouTube, Instagram reel/post, TikTok, any yt-dlp site) into the vault and turn it into a note. Saves the video + thumbnail under 07-Attachments/, picks the best transcript source (creator subtitles → local Whisper → auto-captions), applies a quality gate, then hands the transcript to the ingest skill. Works with just yt-dlp + ffmpeg; uses Whisper (via uvx, GPU-accelerated when available) for spoken-word videos with no usable captions. Use when the user shares a video link or asks to download, save, or preserve a YouTube/Instagram/TikTok video, reel, or recipe.
allowed-tools: Read, Write, Edit, Glob, Grep, Skill, Bash(bash:*), Bash(yt-dlp:*), Bash(ffmpeg:*), Bash(ffprobe:*), Bash(python3:*), Bash(uvx:*), Bash(uv:*), Bash(command:*), Bash(nvidia-smi:*), Bash(ls:*), Bash(cat:*)
---

# download-video — preserve a web video as vault knowledge

Turn a video URL into vault knowledge: the **downloaded video** kept in attachments (so it
survives the post being deleted), plus a **note** built from its transcript and caption. The
heavy lifting — download, metadata, transcript selection, quality gate — runs in
`scripts/yt-fetch.sh`; this skill drives it and then hands the result to **`ingest`**, which
writes the actual source note. Follow the vault conventions in CLAUDE.md (frontmatter, naming,
todo rule, folder icons); do not restate them here.

Folder paths in this skill (`07-Attachments/`, `04-Resources/`, `05-Daily-Notes/`, …) are the
template defaults — the authoritative paths live in the **"Folder roles" table** in CLAUDE.md's
Vault structure section. Resolve folders by role there; never trust the literal defaults on a
renamed or non-English vault.

## Dependencies & graceful degradation

Probe with `command -v` — never assume. The script does this itself and prints platform-specific
install hints when something required is missing.

| Capability | Needs | If absent |
|---|---|---|
| Download + metadata + captions | **`yt-dlp`**, **`ffmpeg`**, `python3` (hard deps) | Script stops with install hints; nothing else works |
| Whisper transcription (spoken video, no captions) | **`uvx`** (ships with `uv`) | Falls back to auto-captions; if none, transcript is `poor` |
| Fast Whisper | NVIDIA GPU (auto-detected via `nvidia-smi`) | Runs on CPU (slower); auto-picks a smaller model |

| Platform | Install hard deps |
|---|---|
| Debian/Ubuntu/WSL | `sudo apt install yt-dlp ffmpeg python3` |
| macOS | `brew install yt-dlp ffmpeg python` |
| Arch | `sudo pacman -S yt-dlp ffmpeg python` |
| Whisper (any) | `curl -LsSf https://astral.sh/uv/install.sh \| sh` (provides `uvx`) |

Whisper's first run downloads the model (`large-v3` ≈ 3 GB on GPU, `small` ≈ 0.5 GB on CPU) —
mention this to the user before a long transcription so the wait isn't a surprise.

## Transcript source priority & quality gate

The script tries, in order, and stamps `transcript_quality` in the output frontmatter:

1. **Creator subtitles** → `good` — human-authored, trust them.
2. **Whisper** (local transcription of the audio) → `good` — preferred over auto-captions.
3. **Auto-captions** (platform ASR) → `fair` — usable but error-prone.
4. **Nothing** → `poor` — no transcript produced.

Act on the gate after the script returns (it prints `RESULT method=… quality=… dir=…`):

- **`good`** → proceed to ingest normally.
- **`fair`** → ingest, but treat technical terms, names, quantities, and numbers as
  low-confidence; keep the `[mm:ss]` anchors so claims can be checked against the video.
- **`poor`** → **do not ingest blindly.** Tell the user, and offer to re-run with `--whisper`
  (forces audio transcription) or `--cookies-from-browser <browser>` if the content was
  login-gated. Never build a note from a non-existent or garbled transcript.

## Steps

1. **Get the URL and intent.** Confirm what the user wants preserved — for a recipe, that's
   ingredients + steps; for a talk, the key points. Note the platform: YouTube usually has real
   captions; **Instagram/TikTok reels usually don't** — the recipe often lives in the post
   caption (the script captures it as `## Post caption / description`) and the spoken steps need
   Whisper.

2. **Resolve the attachments folder** by role from CLAUDE.md, then run the fetch script, passing
   it as the parent dir. The script creates `yt-<id>-<slug>/` inside it:

   ```bash
   bash .claude/skills/download-video/scripts/yt-fetch.sh "<URL>" --out "07-Attachments"
   ```

   Useful flags: `--whisper` (force transcription, skip captions), `--no-whisper` (captions
   only), `--cookies-from-browser firefox` (private/login-gated), `--model <name>`,
   `--force` (overwrite). For a typical Instagram reel where you expect no captions, go straight
   to `--whisper`.

3. **Read `RESULT` and apply the quality gate** above. If `poor`, stop and offer the re-run
   options instead of ingesting.

4. **Read `<dir>/transcript.md`.** It carries the metadata frontmatter, the post caption, and
   the anchored transcript. For a recipe, distil it into clean **ingredients** and **numbered
   steps** — the caption and transcript together, not one or the other.

5. **Hand off to `ingest`.** Invoke the `ingest` skill on `<dir>/transcript.md` so the source
   note lands in the right resource topic (or area — a recipe belongs in the cooking area, not
   resources; place by content). Embed **both** the cover image (`![[video.jpg]]`, the post's
   hero shot — for a recipe this is usually the finished dish) **and** the saved video
   (`![[video.<ext>]]`), and carry the `source_url` into the frontmatter. For more pictures
   (e.g. step-by-step stills), grab frames from the video with ffmpeg:
   `ffmpeg -i <dir>/video.<ext> -vf fps=1/5 <dir>/frame-%02d.jpg` (one frame every 5s; tune the
   rate), eyeball them, and embed only the useful ones. Ingest also handles the daily-note log
   entry and any follow-up todos per the vault's two-place todo rule.

6. **Confirm** what was saved: the note path, where the video lives, and the transcript quality
   so the user knows how much to trust the text.

## Notes

- The raw downloaded files (`video.*`, `video.info.json`, thumbnail) stay in the attachments
  subfolder — they are the evidence. Don't delete them.
- yt-dlp tags and many site URLs are case-sensitive; pass the URL verbatim.
- This skill is intentionally generic (it resolves folders by role and hardcodes no personal
  paths) so it can be contributed back to the upstream template.
