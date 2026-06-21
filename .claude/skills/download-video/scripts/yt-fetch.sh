#!/usr/bin/env bash
# yt-fetch.sh — download a video (YouTube, Instagram, TikTok, any yt-dlp site)
# plus its metadata, and produce an ingest-ready transcript.md with a quality gate.
#
# Transcript source priority (issue tograf/sidebrain#1):
#   creator subtitles  -> Whisper (local, optional)  -> auto-captions
#   quality:   good            good                        fair
#   none of the above -> quality: poor (no transcript; do not ingest blindly)
#
# Hard deps: yt-dlp, ffmpeg, python3 (all probed; clear hints if missing).
# Optional:  uvx (from uv) -> Whisper transcription; nvidia GPU -> large-v3 fast.
#
# Outputs into <out>/yt-<id>-<slug>/ :
#   video.<ext>  video.info.json  video.<thumb>  description.txt  transcript.md
# Prints a final  RESULT method=.. quality=.. dir=..  line for the caller to parse.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ---------- args ----------
URL=""
PARENT="."
WHISPER_MODE="auto"   # auto | force | off
MODEL=""              # whisper model; empty => auto-pick by hardware
COOKIES=""            # browser name for --cookies-from-browser (private/login-gated)
FORCE=0

usage() {
  cat <<'EOF'
Usage: yt-fetch.sh <url> [options]
  --out DIR                 parent dir for the output folder (default: .)
  --whisper                 force Whisper, overriding the caption-first priority
  --no-whisper              never use Whisper (captions only; may end up 'poor')
  --model NAME              Whisper model (default: large-v3 on GPU, small on CPU)
  --cookies-from-browser B  pass browser cookies to yt-dlp (e.g. firefox, chrome)
  --force                   overwrite an existing output folder
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --out) PARENT="$2"; shift 2 ;;
    --whisper) WHISPER_MODE="force"; shift ;;
    --no-whisper) WHISPER_MODE="off"; shift ;;
    --model) MODEL="$2"; shift 2 ;;
    --cookies-from-browser) COOKIES="$2"; shift 2 ;;
    --force) FORCE=1; shift ;;
    -h|--help) usage; exit 0 ;;
    -*) echo "unknown option: $1" >&2; usage; exit 2 ;;
    *) if [ -z "$URL" ]; then URL="$1"; else echo "extra arg: $1" >&2; exit 2; fi; shift ;;
  esac
done

[ -n "$URL" ] || { echo "error: no URL given" >&2; usage; exit 2; }

# ---------- tool probes ----------
need() { command -v "$1" >/dev/null 2>&1; }
missing=()
for t in yt-dlp ffmpeg python3; do need "$t" || missing+=("$t"); done
if [ "${#missing[@]}" -gt 0 ]; then
  echo "error: missing required tool(s): ${missing[*]}" >&2
  echo "install hints:" >&2
  echo "  Debian/Ubuntu/WSL: sudo apt install yt-dlp ffmpeg python3" >&2
  echo "  macOS:             brew install yt-dlp ffmpeg python" >&2
  echo "  Arch:              sudo pacman -S yt-dlp ffmpeg python" >&2
  echo "  (yt-dlp also: pipx install yt-dlp  /  uv tool install yt-dlp)" >&2
  exit 3
fi

whisper_available() { command -v uvx >/dev/null 2>&1; }

GPU=0
if command -v nvidia-smi >/dev/null 2>&1 && nvidia-smi -L 2>/dev/null | grep -qi 'gpu'; then
  GPU=1
fi
if [ -z "$MODEL" ]; then
  if [ "$GPU" -eq 1 ]; then MODEL="large-v3"; else MODEL="small"; fi
fi

# ---------- yt-dlp arg base ----------
ydl=(yt-dlp --no-playlist --no-warnings)
if [ -n "$COOKIES" ]; then ydl+=(--cookies-from-browser "$COOKIES"); fi

# ---------- metadata first (to derive the folder name) ----------
META="$(mktemp -d)"
trap 'rm -rf "$META"' EXIT
echo ">> fetching metadata ..." >&2
"${ydl[@]}" --skip-download --write-info-json -o "$META/v.%(ext)s" "$URL" >&2 \
  || { echo "error: yt-dlp could not read this URL (private/region/login?). Try --cookies-from-browser." >&2; exit 4; }
INFO="$(find "$META" -maxdepth 1 -name '*.info.json' | head -1)"
[ -n "$INFO" ] || { echo "error: no info.json produced" >&2; exit 4; }

# parse scalar fields + sub availability; description -> file (keeps newlines).
# IFS=tab so multi-word titles/uploaders stay in one field (the python emits 8 tab-joined fields).
IFS=$'\t' read -r VID TITLE UPLOADER DUR WURL EXTRACTOR MANUAL AUTO < <(python3 - "$INFO" "$META/description.txt" <<'PY'
import json, sys
d = json.load(open(sys.argv[1], encoding="utf-8"))
open(sys.argv[2], "w", encoding="utf-8").write(d.get("description") or "")
def pick(m):
    m = m or {}
    for c in ("en", "en-US", "en-GB", "en-orig"):
        if c in m: return c
    for k in m:
        if k.startswith("en"): return k
    return ""
def g(*ks):
    for k in ks:
        v = d.get(k)
        if v not in (None, ""): return str(v).replace("\t", " ").replace("\n", " ")
    return ""
print("\t".join([
    g("id"), g("title") or "video", g("uploader", "channel", "uploader_id"),
    g("duration_string", "duration"), g("webpage_url", "original_url"),
    g("extractor_key", "extractor"), pick(d.get("subtitles")), pick(d.get("automatic_captions")),
]))
PY
)

slug="$(printf '%s' "$TITLE" | tr '[:upper:]' '[:lower:]' \
        | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//' | cut -c1-50)"
[ -n "$slug" ] || slug="video"
OUTDIR="$PARENT/yt-${VID}-${slug}"

if [ -d "$OUTDIR" ] && [ "$FORCE" -ne 1 ]; then
  echo "error: $OUTDIR already exists (use --force to overwrite)" >&2
  exit 5
fi
rm -rf "$OUTDIR"; mkdir -p "$OUTDIR"
cp "$INFO" "$OUTDIR/video.info.json"
cp "$META/description.txt" "$OUTDIR/description.txt"

# ---------- download video + thumbnail ----------
echo ">> downloading video ..." >&2
# cap at 1080p and prefer an mp4/h264 container — keep attachments a sane size & portable
"${ydl[@]}" -f "bv*+ba/b" -S "res:1080,ext:mp4:m4a" --merge-output-format mp4 \
  --write-thumbnail -o "$OUTDIR/video.%(ext)s" "$URL" >&2 \
  || { echo "error: video download failed" >&2; exit 4; }
VIDEO="$(find "$OUTDIR" -maxdepth 1 -type f -name 'video.*' \
          ! -name '*.info.json' ! -name '*.vtt' ! -name '*.srt' \
          ! -name '*.jpg' ! -name '*.jpeg' ! -name '*.png' ! -name '*.webp' ! -name '*.wav' \
          | head -1)"
[ -n "$VIDEO" ] || { echo "error: video file not found after download" >&2; exit 4; }

# ---------- transcript selection ----------
METHOD="none"; QUALITY="poor"; DONE=0

clean() {  # <subfile> -> transcript_body.md
  python3 "$SCRIPT_DIR/clean_captions.py" "$1" > "$OUTDIR/transcript_body.md" 2>/dev/null || return 1
  [ -s "$OUTDIR/transcript_body.md" ] || return 1
}

attempt_subs() {  # <lang> <"--write-subs"|"--write-auto-subs"> <method> <quality>
  "${ydl[@]}" --skip-download "$2" --sub-langs "$1" --convert-subs srt \
      -o "$OUTDIR/sub.%(ext)s" "$URL" >&2 || return 1
  local f; f="$(find "$OUTDIR" -maxdepth 1 -name 'sub*.srt' | head -1)"
  [ -n "$f" ] || return 1
  clean "$f" || return 1
  METHOD="$3"; QUALITY="$4"; return 0
}

run_whisper() {  # <device> <model>
  local dev="$1" model="$2"
  if [ "$dev" != "cpu" ]; then
    # GPU: pull the CUDA libs and run via the wrapper that puts them on LD_LIBRARY_PATH
    # (CTranslate2 won't find them in site-packages on its own). Force device=cuda.
    uv run --with whisper-ctranslate2 --with nvidia-cublas-cu12 --with nvidia-cudnn-cu12 \
        python "$SCRIPT_DIR/whisper_gpu.py" --model "$model" --device cuda \
        --output_format vtt --output_dir "$OUTDIR" --task transcribe "$AUDIO" >&2
  else
    uvx whisper-ctranslate2 --model "$model" --device cpu \
        --output_format vtt --output_dir "$OUTDIR" --task transcribe "$AUDIO" >&2
  fi
}

attempt_whisper() {
  whisper_available || { echo ">> Whisper unavailable (no uvx); skipping" >&2; return 1; }
  AUDIO="$OUTDIR/audio.wav"
  ffmpeg -y -loglevel error -i "$VIDEO" -ar 16000 -ac 1 -vn "$AUDIO" || return 1
  local dev=cpu; [ "$GPU" -eq 1 ] && dev=auto
  echo ">> transcribing with Whisper ($MODEL, ${dev}) — first run downloads the model ..." >&2
  if run_whisper "$dev" "$MODEL" && clean "$OUTDIR/audio.vtt"; then
    METHOD="whisper-$MODEL"; QUALITY="good"; return 0
  fi
  if [ "$GPU" -eq 1 ]; then
    echo ">> GPU transcription failed; retrying on CPU with 'small' ..." >&2
    if run_whisper cpu small && clean "$OUTDIR/audio.vtt"; then
      METHOD="whisper-small-cpu"; QUALITY="good"; return 0
    fi
  fi
  return 1
}

case "$WHISPER_MODE" in
  force)
    if attempt_whisper; then DONE=1; fi
    if [ $DONE -eq 0 ] && [ -n "$MANUAL" ] && attempt_subs "$MANUAL" --write-subs creator-subtitles good; then DONE=1; fi
    if [ $DONE -eq 0 ] && [ -n "$AUTO" ] && attempt_subs "$AUTO" --write-auto-subs auto-captions fair; then DONE=1; fi
    ;;
  off)
    if [ -n "$MANUAL" ] && attempt_subs "$MANUAL" --write-subs creator-subtitles good; then DONE=1; fi
    if [ $DONE -eq 0 ] && [ -n "$AUTO" ] && attempt_subs "$AUTO" --write-auto-subs auto-captions fair; then DONE=1; fi
    ;;
  auto)
    if [ -n "$MANUAL" ] && attempt_subs "$MANUAL" --write-subs creator-subtitles good; then DONE=1; fi
    if [ $DONE -eq 0 ] && attempt_whisper; then DONE=1; fi
    if [ $DONE -eq 0 ] && [ -n "$AUTO" ] && attempt_subs "$AUTO" --write-auto-subs auto-captions fair; then DONE=1; fi
    ;;
esac

# ---------- assemble transcript.md ----------
REL_VIDEO="$(basename "$VIDEO")"
{
  printf -- '---\n'
  printf 'source_url: %s\n' "${WURL:-$URL}"
  printf 'platform: %s\n' "$EXTRACTOR"
  printf 'title: %s\n' "$TITLE"
  printf 'uploader: %s\n' "$UPLOADER"
  printf 'duration: %s\n' "$DUR"
  printf 'video_file: %s\n' "$REL_VIDEO"
  printf 'transcript_method: %s\n' "$METHOD"
  printf 'transcript_quality: %s\n' "$QUALITY"
  printf 'fetched_with: yt-fetch.sh\n'
  printf -- '---\n\n'
  printf '# %s\n\n' "$TITLE"
  printf '[Source](%s) — %s · %s\n\n' "${WURL:-$URL}" "${UPLOADER:-unknown}" "$EXTRACTOR"
  printf '> Video file: `%s` (in this folder). Transcript quality: **%s** (via %s).\n\n' "$REL_VIDEO" "$QUALITY" "$METHOD"
  printf '## Post caption / description\n\n'
  if [ -s "$OUTDIR/description.txt" ]; then cat "$OUTDIR/description.txt"; else printf '(none)\n'; fi
  printf '\n\n## Transcript\n\n'
  if [ -s "$OUTDIR/transcript_body.md" ]; then
    cat "$OUTDIR/transcript_body.md"
  else
    printf '(No usable transcript: caption sources exhausted and Whisper unavailable or disabled. Re-run with --whisper to transcribe the audio.)\n'
  fi
  printf '\n'
} > "$OUTDIR/transcript.md"

# tidy intermediates
rm -f "$OUTDIR"/sub*.srt "$OUTDIR/audio.wav" "$OUTDIR/audio.vtt" "$OUTDIR/transcript_body.md" 2>/dev/null || true

echo "RESULT method=$METHOD quality=$QUALITY dir=$OUTDIR"
