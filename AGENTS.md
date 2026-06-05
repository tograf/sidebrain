# Agent Instructions

This vault's instructions live in **[CLAUDE.md](CLAUDE.md)** — read that file first and follow it.
(This is a plain pointer file rather than a symlink so it works on Windows checkouts too.)

## Skills

Reusable procedures live in `.claude/skills/<name>/SKILL.md`. Claude Code invokes them
automatically; if you are a different agent, treat them as standard operating procedures: when a
user request matches a skill's description (in its frontmatter), read that SKILL.md and follow it.

- `setup` — guided interview that builds the personalized vault. Runs on the first session in a fresh vault; on an initialized vault only when the user explicitly asks to re-run setup
- `ingest` — turn a dropped file (PDF, e-book, image, article) into linked notes
- `query` — answer a question from the vault's notes, with citations
- `research` — deep multi-note analysis, written back into the vault
- `vault-lint` — health-check the vault, report before fixing
- `weekly-review` — week-level review: progress, stuck items, next week's focus
- `brainstorming` — refine an idea into an approved plan before writing anything
- `grill-me` — stress-test a plan with one question at a time
