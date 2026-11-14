# Global Agent Configs & Skills (`agents/`)

Machine-wide configurations, instruction files, and global skill lockfiles for AI coding agents — portable across machines with a single `make` command.

## Tracked Contents

| Path | Maps to in `$HOME` | Purpose |
| --- | --- | --- |
| `.claude/` | `~/.claude/` | Claude Code global instructions (`CLAUDE.md`) |
| `.codex/` | `~/.codex/` | OpenAI Codex global instructions (`AGENTS.md`) |
| `.codexbar/` | `~/.codexbar/` | CodexBar placeholder directory |
| `.continue/` | `~/.continue/` | Continue placeholder directory |
| `.copilot/` | `~/.copilot/` | GitHub Copilot CLI placeholder directory |
| `.gemini/` | `~/.gemini/` | Gemini / Antigravity CLI instructions (`GEMINI.md`) and settings (`antigravity-cli/settings.json`) |
| `.agents/.skill-lock.json` | `~/.agents/.skill-lock.json` | Global `npx skills` lockfile (installed skills & sources) |
| `skills-lock.json` | `~/skills-lock.json` | Root skills lockfile (Caveman skill suite) |

## Usage

From the root of `agentsconfig`:

```bash
make install-agents    # Copy global agent configs to $HOME + install all skills
make push-agents       # Copy global agent configs to $HOME only (skip skills)
make pull-agents       # Pull updated configs & skill lockfiles from $HOME into repo
make install-skills    # Install missing global skills from lockfiles via npx skills
make status-agents     # Show diff/sync status between repo and $HOME
```

To force reinstalling all global skills even if already present:

```bash
make -C agents install-skills ARGS="--force"
```
