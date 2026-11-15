# Changelog (`agents/`)

## 2026-11-15
- Changed: `agents/.gemini/antigravity-cli/settings.json` — merged Windows Antigravity CLI permissions (50 commands/PowerShell cmdlets), updated `model` to `Gemini 4 Hydrogen (Medium)`, and removed duplicate `command(touch *)` entry

## 2026-11-14
- Added: `agents/.claude/CLAUDE.md`, `agents/.codex/AGENTS.md`, `agents/.gemini/GEMINI.md`, `agents/.gemini/antigravity-cli/settings.json` — tracked global agent instructions and Antigravity CLI settings
- Added: `agents/.codexbar/.gitkeep`, `agents/.continue/.gitkeep`, `agents/.copilot/.gitkeep` — placeholder directories for agent tool configs
- Added: `agents/skills-lock.json`, `agents/.agents/.skill-lock.json` — global skill lockfiles for `npx skills`
- Added: `agents/scripts/install.sh`, `agents/scripts/install-skills.sh`, `agents/scripts/pull.sh`, `agents/scripts/status.sh` — config sync and global skill installer scripts
- Added: `agents/Makefile`, `agents/README.md`, `agents/AGENTS.md` — area documentation and Make targets
