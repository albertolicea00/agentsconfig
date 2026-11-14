# Git Area Guidelines (`git/`)

Instructions for AI agents working under `git/`.

## Scope

- `hooks/` — Global Git hooks (`pre-commit`, `pre-push`) referenced by `git config --global core.hooksPath`.
- `gitleaks.toml` — Extended Gitleaks ruleset (`[extend] useDefault = true` + custom rules for URIs, public IPs, and disguised secrets).
- `scripts/` — Setup, teardown, and self-test scripts (`#!/usr/bin/env bash`, `# description`, `set -euo pipefail`).

## Conventions

- All scanners must run **100% offline** (never enable online token verification that phones home or sends secrets over the network).
- Always preserve `--redact` on Gitleaks invocations so secret values are never printed in plain text to logs.
- Always chain repository-local hooks (`$GIT_DIR/hooks/pre-commit` and `pre-push`) while guarding against infinite recursion when `core.hooksPath` points to `git/hooks`.
- Never place literal test secrets inside tracked scripts; construct test fixtures dynamically in `scripts/test-secrets.sh`.
- Update `git/CHANGELOG.md` before staging any change under `git/`.
