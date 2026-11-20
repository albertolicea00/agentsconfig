# Changelog (`git/`)

## 2026-11-20
- Changed: `git/README.md` — documented inline allowlisting for false positives and per-repository hook opt-out (`git config --local core.hooksPath .git/hooks`)

## 2026-11-14
- Changed: `git/hooks/pre-commit`, `git/gitleaks.toml` — exclude `skills-lock.json`, `.skill-lock.json`, and package lockfiles from `detect-secrets-hook` and Gitleaks to avoid SHA integrity hash false positives
- Added: `git/hooks/pre-commit` — global pre-commit hook running Gitleaks + `detect-secrets-hook` + local hook chaining
- Added: `git/hooks/pre-push` — global pre-push hook scanning unpushed commits with Gitleaks
- Added: `git/gitleaks.toml` — extended Gitleaks configuration for connection URIs, disguised high-entropy assignments, inline CLI passwords, and hardcoded public IPv4 addresses
- Added: `git/scripts/install.sh`, `git/scripts/uninstall.sh`, `git/scripts/test-secrets.sh` — installer, uninstaller, and automated disguised-secret self-test
- Added: `git/Makefile`, `git/README.md`, `git/AGENTS.md` — area documentation and Make targets
