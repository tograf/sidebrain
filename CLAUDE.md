# Second Brain — Fresh Vault

This is an uninitialized second-brain template. The personalized vault doesn't exist yet.

**On the user's first message — whatever it is — run the `setup` skill** (`.claude/skills/setup/`).
It interviews the user and builds their personalized folder structure, context files, and a
tailored CLAUDE.md that replaces this stub.

Until setup has run, don't create folders or notes on your own — the setup skill owns that.

After setup, this file is gone and the generated CLAUDE.md is the vault's context. If the user
ever wants to start over, the setup skill handles re-runs too ("run setup again").
