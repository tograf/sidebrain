---
name: research
description: Deep, multi-note research across the vault. Decompose a question into several searches, gather and read many related notes (following wikilinks and backlinks), then write a structured, cited analysis note into the fitting resource topic. Heavier than query, which gives a concise one-shot answer — use for "compare X and Y", "write an analysis of Z", "deep dive on…".
allowed-tools: Read, Grep, Glob, Write, Edit, Bash(qmd:*), Bash(npx qmd:*), Bash(command:*)
---

<!-- Adapted from the research skill of a private LLM-wiki repo (see BACKLOG.md), following the
     LLM-wiki pattern (karpathy). Reworked for this PARA vault: qmd optional, Grep fallback. -->

# research — deep multi-note study, written back into the vault

**`research` vs `query`:** `query` answers one question concisely from the top notes. `research`
deliberately sweeps *broadly* and produces a **persisted, structured analysis note**. Vault
conventions live in CLAUDE.md.

Folder paths in this skill are the template defaults — the authoritative paths live in the "Folder roles" table in CLAUDE.md's Vault structure section. Look folders up there by role — never trust the literal defaults on a renamed or non-English vault.

## Steps

1. **Scope & confirm.** Restate the research question, the angle, the intended sections/depth,
   and **where the analysis note will land** (usually `04-Resources/<Topic>/`; the relevant
   project file's folder when it's project-scoped; ask if there's no obvious home). Because this
   sweeps wide and writes a file, confirm before the heavy retrieval — this is the same gate the
   `brainstorming` skill uses.

2. **Broad retrieval.** Decompose the question into sub-questions and run *several* searches —
   never rely on one query. Probe `command -v qmd` once:
   - **qmd installed:** `qmd query "<sub-question>" -n 15` per sub-question.
   - **No qmd:** Grep key terms and synonyms across `**/*.md`; Glob the relevant topic folders;
     scan the `## Index` sections of the topic starter notes.
   Then widen beyond direct hits: follow `[[wikilinks]]` outward AND **backlinks** (Grep for the
   central notes' names inside `[[…]]`) so related material isn't missed.

3. **Read in full.** Fetch the gathered notes whole — snippets are only leads; synthesize from
   full text, including cited source notes.

4. **Synthesize a structured analysis:**
   - A clear **question/thesis** up front.
   - **Sections by sub-topic**, every claim carrying a `[[wikilink]]` citation. Separate what a
     source claims from established fact.
   - An explicit **Open questions / gaps** subsection and a **Contradictions** subsection
     (lint-minded: note where notes disagree or evidence is thin).
   - A **Sources** list of the notes drawn on.

5. **Write the note** to `04-Resources/<Topic>/Analysis - <Readable Name>.md` with frontmatter
   (`tags: [resource, analysis]`, `created`). Analysis notes are the **allowed exception to
   one-note-one-thought atomicity** — they are synthetic and longer by design.

6. **Cross-link & index.** Link the analysis to the notes it draws on (they gain a backlink
   automatically), add it to the `## Index` section of the topic starter note, and log one line
   in today's daily note. Follow-up todos obey the two-place todo rule.

7. **Re-embed if qmd is installed**; skip silently otherwise.

## Quality bar

- Cite every claim; never assert un-sourced statements as established. Label model knowledge
  added on top of vault content as such.
- Surface gaps and contradictions rather than papering over them — where the vault is thin on a
  sub-topic, say so and recommend an `ingest` to fill it.
