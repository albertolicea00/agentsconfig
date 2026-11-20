# Changelog (`git/`)

## 2026-11-20
- Added: `git/scripts/hook-lib.sh` — shared `hook_is_enabled` helper providing per-hook (`hooks.<hook>.enabled`) and per-validation (`hooks.<hook>.<check>`) boolean switches across all 8 global hooks
- Changed: `git/README.md` — rename section to `Global Git Hooks & Guardrails (git/)` and document all per-hook and per-validation switches
- Added: `git/hooks/post-merge` — warn about new `.env.example` keys missing from local `.env`, and clean obsolete local caches (`.pytest_cache`, `__pycache__`, `.vite`, `.next/cache`, etc.) when critical config files change (`hooks.cleanCacheOnMerge`)
- Added: `git/hooks/pre-rebase` — block rebasing protected/shared branches (`hooks.protectedRebaseBranches`) or tagged commits, and automatically create a `backup/<branch>-<timestamp>` branch (`hooks.backupOnRebase`)
- Added: `git/hooks/prepare-commit-msg` — insert a visible `# ⚠️ WARNING` banner in the editor (or warn on stderr for `-m`) when committing directly to protected branches (`main`, `master`, `pro`, `prod`, `production`; configurable via `hooks.protectedBranches`)
- Added: `git/hooks/commit-msg` — detect `Co-authored-by:` trailers with configurable `hooks.coAuthorPolicy` (`warn` | `block` | `allow`) and local hook chaining
- Added: `git/hooks/post-checkout` — print pending tracked `TODO.md`/`TODO.txt` items and tracked `TODO`/`FIXME` code markers on branch switches (`hooks.todoOnCheckout`)
- Added: `git/hooks/post-commit` — remind on newly introduced `TODO`/`FIXME` lines and show unpushed commit count ahead of upstream
- Changed: `git/scripts/install.sh`, `git/scripts/test-secrets.sh`, `git/README.md` — install, test, and document the new hooks, per-repo config options, and manual hook invocation (`git push --dry-run`)
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
