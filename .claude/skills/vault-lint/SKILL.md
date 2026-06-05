---
name: vault-lint
description: Health-check the vault. Scan for unresolved wikilinks, orphan notes, inbox backlog, todo-rule violations, naming-convention breaches, frontmatter drift, and unreferenced attachments, then report findings. Report only — confirm with the user before fixing anything. Use when asked to lint, audit, check, or tidy up the vault.
allowed-tools: Read, Grep, Glob, Bash(qmd:*), Bash(npx qmd:*)
---

# vault-lint — periodic health check

**Report findings; do not silently "fix" anything** — propose, then change only on confirmation.
Vault conventions live in CLAUDE.md.

Folder paths in this skill are the template defaults — the authoritative paths live in the "Folder roles" table in CLAUDE.md's Vault structure section. Look folders up there by role — never trust the literal defaults on a renamed or non-English vault.

## What to check

- **Contradictions & stale claims** — notes that disagree with each other or with the source they
  cite; dated statements that newer notes (or newer ingested sources) have superseded. Compare
  `created` dates when two notes clash — flag, don't auto-resolve: which claim wins is the user's
  call.
- **Unresolved wikilinks** — `[[targets]]` pointing at notes that don't exist. Valid as TODOs, but
  worth surfacing, especially ones dangling for a long time.
- **Orphan notes** — notes with no inbound `[[wikilink]]` from any other note (exempt: daily
  notes, the context files in `00-Context/`, and the root infrastructure files `CLAUDE.md` and
  `AGENTS.md` — they're entry points, not orphans).
- **Inbox backlog** — entries in `01-Inbox/` (including `Brain-Dump.md` content) that have sat
  unfiled; list them with a proposed destination each.
- **Todo-rule violations** — open todos (`- [ ]`) on detail pages that are missing from any daily
  note, and daily-note todos without a `[[wikilink]]` to their detail page. Also: stale todos that
  have been open across many daily notes — flag for a decision, don't nag.
- **Naming-convention breaches** — folders OR files containing spaces (both must be
  Capitalized-Hyphenated, e.g. `Content-Creation/`, `About-Me.md`), area/resource folders missing
  their same-named starter note, daily notes not matching `YYYY-MM-DD.md` (weekly notes
  `YYYY-Www.md` are also valid there).
- **Frontmatter drift** — notes missing frontmatter entirely, or missing `tags`/`status` where the
  vault templates define them; `status: completed` projects still sitting outside `06-Archive/`
  (flag only — archiving is the user's call, never automatic).
- **Topic-index drift** — for each resource topic: notes in the topic folder missing from the
  starter note's `## Index` section, and index entries whose `[[wikilink]]` points at a note that
  doesn't exist.
- **Unreferenced attachments** — files in `07-Attachments/` that no note embeds or links.
- **Icon drift** — folders missing an entry in `.obsidian/plugins/obsidian-icon-folder/data.json`
  (only if the icon plugin is present).

## Tactics

**Step 0 — resolve paths first (mandatory):** read the "Folder roles" table in CLAUDE.md's Vault
structure section and substitute the actual paths into every command below. The `<role>`
placeholders are NOT literal — on a renamed or non-English vault the literal English defaults
would silently scan nothing and produce a false-clean report.

Pure Grep/Glob — no external tools required:

```bash
# all wikilink targets referenced anywhere
grep -rhoE '\[\[[^]|#]+' --include='*.md' . | sed 's/\[\[//' | sort -u
# all existing note names (compare against the above for unresolved links / orphans)
# (Glob: **/*.md, take basenames without extension)
# open todos on detail pages vs. daily notes
grep -rn '^- \[ \]' --include='*.md' <projects>/ <areas>/ <resources>/
grep -rn '^- \[ \]' --include='*.md' <daily>/
# folders or files with spaces
find . -name '* *' -not -path './.git/*' -not -path './.obsidian/*'
# attachment references
grep -rhoE '\!\[\[[^]]+\]\]' --include='*.md' . | sort -u
```

If qmd is installed (`command -v qmd`), `qmd status` adds index health; optional.

## Output

A concise report grouped by the categories above, each finding naming the specific note(s)/
folder(s). Skip empty categories. End with a proposed, prioritized fix list and ask which to
apply — then make changes only on confirmation. If notes changed and qmd is installed, finish
with `qmd update && qmd embed`.
