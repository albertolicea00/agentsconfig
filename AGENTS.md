# Agent Guidelines

Instructions for AI agents working in this repository.

## Language

- Write all new or modified repository content in English, including code identifiers, comments, documentation, scripts, user-facing messages, changelog entries, and commit messages.
- Preserve external names, URLs, and user-provided data as needed. Conversations with the user may use their preferred language.

## Repository Purpose

`agentsconfig` holds machine-wide developer and AI-agent configurations:
- **`git/`** — Global Git security hooks (`pre-commit`, `pre-push`) powered by Gitleaks + `detect-secrets`
- **`agents/`** — Global AI agent configurations, instructions, and skill lockfiles synced with `$HOME`
- **`<area>/`** — Additional global tool configurations, each with its own `README.md`, `Makefile`, `AGENTS.md`, and `CHANGELOG.md`

## Structure

```
agentsconfig/
├── agents/                   # Global AI agent configs & skill lockfiles (see agents/README.md)
├── git/                      # Global Git security hooks & rules (see git/README.md)
├── AGENTS.md                 # This file
├── .workspace/CHANGELOG.md   # Repo-level changelog (not area internals)
├── TODO.md
└── Makefile                  # Delegates to area Makefiles
```

Each subfolder has its own `AGENTS.md`, `README.md`, `CHANGELOG.md`, and `Makefile` scoped to that area.

## Script Conventions

- Shebang: `#!/usr/bin/env bash`
- Second line: `# <short description>` — appears in `make help`
- `set -euo pipefail` on the third line
- No hardcoded secrets or machine-specific credentials
- Deps checked at top with clear error messages

## ⚠ CHANGELOG — UPDATE BEFORE EVERY COMMIT

Each changelog tracks only its own area:

| File | Tracks |
|---|---|
| `agents/CHANGELOG.md` | Every agent config, skill lockfile, or sync script added, changed, or fixed under `agents/` |
| `git/CHANGELOG.md` | Every hook, rule, or script added, changed, or fixed under `git/` |
| `.workspace/CHANGELOG.md` | Repo-level changes only (structure, root Makefile, root docs, AGENTS) |

Format:

```
## YYYY-MM-DD
- Added: `<path>` — short description
- Changed: `<path>` — what changed and why
- Fixed: `<path>` — what was broken
- Removed: `<path>` — why removed
```

**No changelog entry = do not commit.**

## Commit attribution

Every AI-assisted commit must include a `Co-authored-by` trailer identifying the actual AI assistant that contributed.

The trailer is mandatory; a single assistant identity is not mandatory for all agents. Each agent must attribute its own work to itself. Identity examples and assistant-specific rules apply only to that named assistant, never to other agents.

- Codex must use exactly: `Co-authored-by: Codex <noreply@openai.com>` (verified in the installed OpenAI Codex CLI).
- Other assistants must use their own verified attribution identity. Never copy another assistant's identity: Codex must not attribute its work to Gemini, Claude, or another product.
- **NEVER** use `<antigravity@gmail.com>`, `<antigravity@google.com>`, or invented, ambiguous, or unverified co-author identities or emails: GitHub may associate them with unrelated users.
- Never guess an email from an agent or product name. Verify the identity from the assistant's official tooling or documentation.
- Never omit the required co-author trailer from AI-assisted commits.

## TODO.md

Informal backlog. No structure required. Drop ideas, clean up when done.
