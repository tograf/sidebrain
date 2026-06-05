---
name: ingest
description: Ingest a source (PDF, EPUB, image, article, transcript) into the vault. Read the file, summarize it into a source note under 04-Resources/<Topic>/, optionally split key concepts into atomic linked notes, wire up wikilinks, and log the ingest in today's daily note. Works with zero extra tools for small PDFs and images; uses poppler/pandoc/tesseract for big books, e-books, and scans when installed. Use when the user drops a file into the vault or asks to ingest / add / process a source, article, book, paper, or screenshot.
allowed-tools: Read, Write, Edit, Glob, Grep, Bash(pdftotext:*), Bash(pdfinfo:*), Bash(pdftoppm:*), Bash(pdfimages:*), Bash(tesseract:*), Bash(pandoc:*), Bash(unzip:*), Bash(command:*), Bash(qmd:*), Bash(npx qmd:*)
---

# ingest — add a source to the vault

Turn an external source into vault knowledge: one **source note** that summarizes it, plus —
for substantial sources — **atomic concept notes**, all connected with wikilinks. Follow the
vault conventions in CLAUDE.md (frontmatter, naming, todo rule, folder icons); do not restate
them here.

Folder paths in this skill (04-Resources/, 05-Daily-Notes/, …) are the template defaults — the
authoritative paths live in the "Folder roles" table in CLAUDE.md's Vault structure section.
Look folders up there by role — never trust the literal defaults on a renamed or non-English
vault.

## Where things go

- **The raw file** stays where it is (usually `07-Attachments/` or wherever the user dropped it).
  Never modify, rename, or delete it.
- **The source note** goes to `04-Resources/<Topic>/<Readable Source Name>.md`. One source note
  per source. If no fitting topic folder exists, propose creating one (hyphenated name, plus its
  icon entry per the vault rules) and confirm.
- **Atomic concept notes** (only for substantial sources) go into the same topic folder, one
  concept per note, each linking back to the source note.

## Steps

1. **Identify the source.** If the user dropped a file without a path, look in `01-Inbox/` and
   `07-Attachments/` for recent additions (Glob). Determine the type: PDF, EPUB, image, markdown/
   text, or transcript.

2. **Probe before reading.** Use the extraction strategy table below — small files are read
   directly, large ones are sliced. Never load a whole book into context.

3. **Surface the key takeaways and confirm scope before writing.** Tell the user what the source
   contains, propose: the target topic folder, the source-note name, which concepts (if any)
   deserve atomic notes, and what you'd deliberately skip. Wait for the okay. Keep this lightweight
   for small sources (a screenshot needs one sentence, not a plan).

4. **Write the source note** with frontmatter (`tags: [resource, source]`, `status`, `created`),
   containing: a link or embed of the raw file (`![[file.pdf]]` / `![[screenshot.png]]`), what the
   source is (author/origin/date if known), the summary, and a "Key concepts" section linking the
   atomic notes. Mark interpretation as interpretation — reading a chart or diagram is your
   inference, not ground truth ("the screenshot shows …").

5. **Write the atomic concept notes** (if confirmed): one concept per note, each citing the source
   note via wikilink. Search the vault first (Grep, or qmd if installed) so you **extend existing
   notes rather than duplicate them**.

6. **Wire wikilinks both directions** so nothing is orphaned: source note → concept notes,
   concept notes → source note, and links into related existing notes (projects, areas) where
   they genuinely connect.

7. **Update the topic index.** Each resource topic's starter note
   (`04-Resources/<Topic>/<Topic>.md`) has a `## Index` section — the topic's catalog. Add a
   one-line entry there — `[[wikilink]]` plus a half-sentence summary — for the new source note
   and each new concept note. Always that section, never an improvised heading: query/research
   read exactly `## Index`, and vault-lint checks it for drift.

8. **Log the ingest in today's daily note** (`05-Daily-Notes/YYYY-MM-DD.md`, create it if
   missing): one line — what was ingested, linked to the source note. Any follow-up todos obey
   the vault's two-place todo rule.

9. **Re-index if qmd is installed** (`command -v qmd`): run `qmd update && qmd embed`. If qmd is
   not installed, skip silently — it's optional.

## Extraction strategy by source type

Probe for tools with `command -v <tool>` — never assume. When a needed tool is missing, tell the
user exactly what to install for *their* platform and offer the fallback:

| Platform | Install command |
|---|---|
| Debian/Ubuntu/WSL | `sudo apt install poppler-utils pandoc tesseract-ocr` |
| macOS | `brew install poppler pandoc tesseract` |
| Windows (native) | `winget install oschwartz10612.Poppler JohnMacFarlane.Pandoc UB-Mannheim.TesseractOCR` |
| Arch | `sudo pacman -S poppler pandoc-cli tesseract tesseract-data-eng` |

**Small PDFs (≲ 50 pages):** Read the file directly — no tools needed.

**Large PDFs / books:** A 500-page book is ~300k+ tokens — never read it whole.
1. `pdfinfo "<file>"` for page count; sniff the text layer: `pdftotext -f 1 -l 3 "<file>" -`.
   Empty/garbage output ⇒ scanned PDF → OCR route (below).
2. Extract once to a temp path: `pdftotext -layout "<file>" /tmp/<slug>.txt`.
3. Map chapters (PDF outline or grep headings), then summarize **section by section** (Read with
   offset/limit on the temp file). For very large works, scope each pass to a coherent unit and
   record what's deferred in the source note under "Not yet ingested", so a later pass can resume.
4. Delete the temp extract when done.
5. Without poppler: offer to ingest the table of contents + selected chapters via targeted Read
   calls, or ask the user to install poppler for the full pass.

**EPUB / e-books:** Convert once with pandoc, then slice like a large PDF:
`pandoc "<file>.epub" -t gfm -o /tmp/<slug>.md`. Fallback without pandoc: an `.epub` is a ZIP of
XHTML — `unzip -o "<file>.epub" -d /tmp/<slug>-epub` and Read the XHTML files (order via the spine
in `content.opf`). Messier — prefer pandoc.

**Images (screenshots, charts, diagrams, photos):** Read the image directly — the Read tool
renders it visually; no OCR needed for the general case. Embed the original in the source note
(`![[file.png]]`) — the image is the evidence, the prose is the extraction. Switch to real OCR
(`tesseract <img> stdout`) only for document scans of dense text or many images at once; for
scanned PDFs rasterize first: `pdftoppm -png <file> /tmp/<slug>` → `tesseract`.

**Markdown / text / transcripts:** Read directly; for transcripts treat technical terms, names,
and numbers as low-confidence — verify or mark as uncertain.

## Quality bar

- Every claim in concept notes ties back to the source note via wikilink — distinguish what the
  source *claims* from established fact.
- Keep concept notes atomic (one idea). If one starts covering two ideas, split and cross-link.
- Never fabricate content from unreadable input (garbled OCR, broken extraction) — flag it
  instead.
