---
name: query
description: Answer a question from the vault. Search the notes (qmd if installed, otherwise Grep/Glob), read the top notes in full, and synthesize an answer with wikilink citations — then offer to file the answer back into the vault so explorations compound. Use whenever the user asks a question the vault may already cover.
allowed-tools: Read, Grep, Glob, Write, Edit, Bash(qmd:*), Bash(npx qmd:*), Bash(command:*)
---

<!-- Adapted from the query skill of a private LLM-wiki repo (see BACKLOG.md), following the
     LLM-wiki pattern (karpathy). Reworked for this PARA vault: qmd optional, Grep fallback. -->

# query — answer a question from the vault

Answer from what the vault *actually contains*, not from model memory. Vault conventions live in
CLAUDE.md.

Folder paths in this skill are the template defaults — the authoritative paths live in the "Folder roles" table in CLAUDE.md's Vault structure section. Look folders up there by role — never trust the literal defaults on a renamed or non-English vault.

## Steps

1. **Search the vault.** Probe once with `command -v qmd`:
   - **qmd installed:** `qmd query "<the user's question>" -n 10` (hybrid search + re-rank). For
     search syntax beyond that, defer to `qmd skill show`.
   - **No qmd (default path):** search in two passes — (a) scan the `## Index` sections of the
     topic starter notes (`04-Resources/<Topic>/<Topic>.md`) and the project/area files, (b) Grep key
     terms *and their synonyms* across `**/*.md` (a question about "clients" may be filed under
     "customers"). Follow `[[wikilinks]]` from the hits one hop out.

2. **Read the top notes in full** before answering — search snippets are only leads. Include the
   linked source note when a concept note cites one.

3. **Synthesize the answer** from the retrieved text, **citing notes as `[[wikilinks]]`**.
   Distinguish what a cited source claims from established fact. If the vault doesn't cover the
   question, say so plainly rather than inventing — and point out that the gap is an `ingest`
   candidate.

4. **Offer to file the answer back.** If the answer required real synthesis (a comparison, an
   analysis, a connection across notes), it shouldn't vanish into chat history — offer to save it
   as a note in the fitting `04-Resources/<Topic>/` (or the relevant project/area file). If
   accepted: write the note with frontmatter and wikilinks to everything it drew on, add it to
   the `## Index` section of the topic's starter note, log one line in today's daily note, and
   re-embed if qmd is installed. Skip the offer for trivial lookups.

## Quality bar

- Never present un-sourced recall as if it came from the vault — if you add general knowledge on
  top of vault content, label it as such.
- Cited notes must actually support the claim — re-read, don't pattern-match on titles.
