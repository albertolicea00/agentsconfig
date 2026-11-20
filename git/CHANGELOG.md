# Changelog (`git/`)

## 2026-11-20
- Changed: `git/README.md` — add Hooks overview table listing all hooks, when they trigger, scope, typical duration, and checks run
- Added: `git/hooks/pre-commit` — block forbidden staged files (`.env`, `.DS_Store`, `Thumbs.db`, `desktop.ini`, private keys/certs `*.pem`/`*.key`/`*.p12`/`*.pfx`/`id_*`), accidental nested Git repositories (unregistered `160000` gitlinks), and oversized files (> 5 MB default, configurable via `hooks.maxFileSizeMB`)
- Added: `git/.gitattributes` — enforce LF line endings for hooks, shell scripts, and Makefile on Windows checkouts
- Changed: `git/hooks/pre-commit`, `git/hooks/pre-push`, `git/scripts/install.sh` — add Windows (Git Bash / MSYS2) compatibility (`cygpath -m`, Windows shim `PATH` discovery, `winget`/`scoop`/`choco`/`pip`/`py` installer support, `\r` sanitization)
- Changed: `git/scripts/test-secrets.sh`, `git/README.md` — add self-tests and documentation for forbidden/oversized file guards, nested Git repo guard, and cross-platform Windows/macOS support
- Changed: `git/README.md` — documented inline allowlisting for false positives and per-repository hook opt-out (`git config --local core.hooksPath .git/hooks`)

## 2026-11-14
- Changed: `git/hooks/pre-commit`, `git/gitleaks.toml` — exclude `skills-lock.json`, `.skill-lock.json`, and package lockfiles from `detect-secrets-hook` and Gitleaks to avoid SHA integrity hash false positives
- Added: `git/hooks/pre-commit` — global pre-commit hook running Gitleaks + `detect-secrets-hook` + local hook chaining
- Added: `git/hooks/pre-push` — global pre-push hook scanning unpushed commits with Gitleaks
- Added: `git/gitleaks.toml` — extended Gitleaks configuration for connection URIs, disguised high-entropy assignments, inline CLI passwords, and hardcoded public IPv4 addresses
- Added: `git/scripts/install.sh`, `git/scripts/uninstall.sh`, `git/scripts/test-secrets.sh` — installer, uninstaller, and automated disguised-secret self-test
- Added: `git/Makefile`, `git/README.md`, `git/AGENTS.md` — area documentation and Make targets
