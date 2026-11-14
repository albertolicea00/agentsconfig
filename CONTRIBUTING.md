# Contributing

> **Note:** This is not an open-contribution project. This guide exists as a personal reference so I (and my AI agents) know how to keep things organized.

If you want the configs — fork it. [Unlicense](UNLICENSE). Take everything.

## Adding a Config Area

1. Place under `<area>/` with its own `README.md`, `Makefile`, `AGENTS.md`, and `CHANGELOG.md`
2. Forward top-level targets from the root `Makefile`
3. Update `.workspace/CHANGELOG.md` and the area's `CHANGELOG.md`

## Adding or Modifying Git Rules (`git/`)

1. Edit `git/gitleaks.toml` or `git/hooks/`
2. Run `make test-git` to verify disguised secrets, URIs, and IPs are still blocked
3. Verify no false positives against tracked files (`./git/hooks/pre-commit`)
4. Update `git/CHANGELOG.md`

## Conventions

- All scanners and hooks must run **100% offline** (no cloud verification or telemetry)
- No hardcoded credentials, personal IPs, or machine-specific secrets
- `set -euo pipefail` on every shell script
- Deps checked at top with clear error messages

## Checklist

- [ ] Correct folder and filename
- [ ] Description comment on line 2 of every shell script
- [ ] No hardcoded secrets or false-positive test literals
- [ ] README updated
- [ ] Area `CHANGELOG.md` (or `.workspace/CHANGELOG.md`) updated
- [ ] Tested with `make test-git`
