---
name: weekly-review
description: Week-level review of the vault. Read the week's daily notes and active projects, assess real progress vs. stuck items, give honest feedback, write a weekly note, and plan next week's focus. Use when the user asks for a weekly review / weekly report / "how was my week", or when a week is wrapping up.
---

# weekly-review — close the week, plan the next

The weekly counterpart to the end-of-day feedback in CLAUDE.md: same honesty, one level up.
Vault conventions live in CLAUDE.md.

Folder paths in this skill are the template defaults — the authoritative paths live in the "Folder roles" table in CLAUDE.md's Vault structure section. Look folders up there by role — never trust the literal defaults on a renamed or non-English vault. Write everything in the vault's language.

## Steps

1. **Gather the week.** Read the last 7+ daily notes in `05-Daily-Notes/`, the active project
   files in `02-Projects/` (`status: active`), and skim area files touched this week. Note the
   inbox backlog size.

2. **Assess — real progress, not busyness:**
   - Which todos were completed; which are open, and crucially **how long** they've been open
     (a todo dragging through five daily notes is a finding, not a footnote).
   - Per active project: did it move? Stalled projects get named.
   - Which areas got attention; which were neglected.
   - Wins worth acknowledging — and whether anything was ingested/learned that should connect to
     ongoing work.

3. **Give honest feedback in the chat** (not in the note) — same tone rules as the end-of-day
   feedback in CLAUDE.md: volume matches significance, no coaching-speak, name what's stuck,
   genuinely celebrate real wins.

4. **Write the weekly note** to `05-Daily-Notes/YYYY-Www.md` (e.g., `2026-W23.md` — sorts
   alongside the daily notes), frontmatter `tags: [weekly]`. Sections:
   - **Highlights** — the 2-3 things that defined the week
   - **Progress by project** — one line each, linked `[[wikilinks]]`
   - **Stuck / overdue** — with how long, linked to detail pages
   - **Next week's focus** — 1-3 priorities, each linked; any new todos obey the two-place todo
     rule (detail page + today's daily note)
   - Links to the week's daily notes

5. **Offer a vault-lint pass.** Weekly is exactly the right lint cadence — one question, run it
   only on a yes.

## Quality bar

- Ground every statement in the notes — cite via wikilinks; no vague "good progress".
- The "Next week's focus" must be small (1-3 items). A ten-item focus is a backlog, not a focus.
