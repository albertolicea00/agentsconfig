# Agents Area Guidelines (`agents/`)

Instructions for AI agents working under `agents/`.

## Scope

- `.claude/`, `.codex/`, `.codexbar/`, `.continue/`, `.copilot/`, `.gemini/`, `.agents/` — Tracked global configuration and instruction files mirrored to `$HOME`.
- `skills-lock.json` & `.agents/.skill-lock.json` — Declarative lockfiles for global skills installed via `npx skills`.
- `scripts/` — Sync, installation, and status scripts (`#!/usr/bin/env bash`, `# description`, `set -euo pipefail`).

## Security & Privacy Rules

- **NEVER** track authentication tokens, session files, SQLite history databases, or OAuth caches from `~/.claude`, `~/.codex`, `~/.copilot`, `~/.continue`, `~/.codexbar`, or `~/.gemini` (e.g., `auth.json`, `history.jsonl`, `*.sqlite*`, `*.db*`, `logs/`, `sessions/`).
- Only commit explicit configuration, settings, instruction files (`CLAUDE.md`, `AGENTS.md`, `GEMINI.md`, `settings.json`), and skill lockfiles.
- Update `agents/CHANGELOG.md` before staging any change under `agents/`.
