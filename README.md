# Sidebrain

**Your second brain in Obsidian, maintained by Claude Code.** Download it, open it, and Claude walks you through a 10–15 minute interview — at the end you have a personalized vault: PARA-style folder structure, a context profile Claude reads before every content task, and a tailored `CLAUDE.md` so every future session knows who you are and what you're working on.

## What you get

- **Guided setup** — the `setup` skill interviews you about your projects, areas, and resource topics, then builds the vault from your answers, writes your personal `CLAUDE.md`, removes the template files, and resets git so the vault is fully yours. Re-runnable anytime ("run setup again").
- **Context profile** (`00-Context/`) — About Me and Writing Style for everyone; ICP, Offer, and Branding added when you work with clients or an audience. Claude consults these before writing content, emails, or offers on your behalf.
- **PARA structure** — Inbox, Projects, Areas, Resources, Daily Notes, Archive, Attachments.
- **Working rules baked in** — atomic notes, wikilinks, a strict two-place todo rule (detail page + linked daily note), session routines, and honest end-of-day feedback on request.
- **Skills** (`.claude/skills/`):
  - `brainstorming` — turns a rough idea into an approved plan before anything is written into the vault (adapted from [obra/superpowers](https://github.com/obra/superpowers))
  - `grill-me` — relentless one-question-at-a-time stress-testing of a plan or decision (adapted from [mattpocock/skills](https://github.com/mattpocock/skills))
  - `ingest` — drop in a PDF, e-book, screenshot, or article and it becomes a summarized source note plus atomic linked notes in your resources. Small files need zero extra tools; poppler/pandoc/tesseract unlock big books, EPUBs, and scans
  - `query` — answers questions from your own notes with wikilink citations, and files synthesized answers back into the vault so explorations compound
  - `research` — deep multi-note study written back as a structured, cited analysis note ("compare X and Y", "deep dive on Z")
  - `vault-lint` — health check: contradictions, broken wikilinks, orphan notes, inbox backlog, convention drift. Report first, fixes only on confirmation
  - `weekly-review` — closes the week: real progress vs. stuck items, honest feedback, a weekly note, and next week's focus

All skills work without extra tools and automatically use [qmd](https://github.com/tobi/qmd) for search when it's installed.

**Other agents (untested):** the vault ships an `AGENTS.md` pointing to the same instructions, so agents like Codex or Cursor *may* work too — they'd read the skills as written procedures instead of invoking them natively. This template is built and tested with Claude Code only; with other agents, your mileage may vary. Reports welcome.

## Requirements

- [Claude Code](https://claude.com/claude-code) — the agent this template is built and tested with (others may work via `AGENTS.md`, but are untested)
- [Obsidian](https://obsidian.md) (free)
- Optional: the [Iconize](https://github.com/FlorianWoelki/obsidian-icon-folder) community plugin — setup assigns folder icons if it's installed

## Getting started

```bash
git clone https://github.com/tograf/sidebrain MyVault
cd MyVault
claude
```

Say anything — the setup interview starts on first contact. Answer the questions; Claude builds the rest. When it finishes, the vault contains only your content: template files are removed and the git history is reset, so nothing of yours can accidentally end up here.

Afterwards, open the folder as a vault in Obsidian.

## Updating later

Your generated CLAUDE.md records this template's URL. Say **"update skills"** in your vault and Claude clones the latest template to a temp folder, shows you what changed in the skills (including anything you customized locally), and applies only what you approve — your notes and your personal CLAUDE.md are never touched. Requires this repo's URL to still be reachable.

## Optional: local search with qmd

For larger vaults, [qmd](https://github.com/tobi/qmd) adds fast local full-text and semantic search that the `query`, `research`, `ingest`, and `vault-lint` skills pick up automatically:

```bash
npm install -g @tobilu/qmd        # requires Node ≥22
qmd collection add . --name vault
qmd embed                          # downloads ~2GB of local models on first run
```

## References

Tools, methods, and sources this template builds on:

- [Obsidian](https://obsidian.md) — the Markdown vault this template is built for
- [Claude Code](https://claude.com/claude-code) — runs the setup interview and all vault sessions
- [PARA method](https://fortelabs.com/blog/para/) and the Second Brain concept by [Tiago Forte](https://www.buildingasecondbrain.com/) — the organizational structure and the name this template builds on
- [LLM Wiki pattern](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f) by Andrej Karpathy — the ingest/query/lint operations and the compounding-knowledge idea behind the skills
- [obra/superpowers](https://github.com/obra/superpowers) — origin of the `brainstorming` skill (adapted for knowledge work)
- [mattpocock/skills](https://github.com/mattpocock/skills) — origin of the `grill-me` skill
- [kepano/obsidian-skills](https://github.com/kepano/obsidian-skills) — additional Obsidian-specific skills worth installing
- [Iconize](https://github.com/FlorianWoelki/obsidian-icon-folder) (obsidian-icon-folder) — optional plugin for the folder icons
- [qmd](https://github.com/tobi/qmd) by Tobi Lütke — optional local full-text + semantic search

## License

[MIT](LICENSE)
