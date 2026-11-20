# Global Git Hooks & Guardrails (`git/`)

Machine-wide Git hooks that protect every repository on macOS, Linux, and Windows — blocking secret leaks, forbidden/oversized files, accidental nested repos, and unsafe rebases, while adding lightweight workflow helpers (`TODO`/`FIXME` summaries, `.env.example` drift alerts, and cache cleanup).

100% local and offline — no telemetry, no cloud API calls.

## Hooks

| Hook | Triggers on | Scope | Typical duration | What it runs |
|---|---|---|---|---|
| [`hooks/pre-commit`](hooks/pre-commit) | Before a commit is created (`git commit`) | Staged changes & staged files only | ~0.3–1.5 s *(scales with staged files)* | 1. Blocks forbidden files (`.env`, `.DS_Store`, `Thumbs.db`, `desktop.ini`, private keys/certs), accidental nested Git repos (`160000` without `.gitmodules`), and files `> 5 MB`.<br>2. Runs **Gitleaks** (`--staged --redact`) with local `.gitleaks.toml` or global [`gitleaks.toml`](gitleaks.toml).<br>3. Runs **detect-secrets-hook** on staged files (excluding lockfiles; uses `.secrets.baseline` if present).<br>4. Chains repository-local `.git/hooks/pre-commit` if executable. |
| [`hooks/prepare-commit-msg`](hooks/prepare-commit-msg) | Before the commit message editor opens (`git commit`) | Current branch name & commit message file | < 15 ms | 1. On protected branches (`main`, `master`, `pro`, `prod`, `production`), inserts a `# ⚠️ WARNING: You are committing directly to protected branch '<branch>'!` banner at the top of the editor (or warns on `stderr` for `git commit -m`).<br>2. Chains repository-local `.git/hooks/prepare-commit-msg` if executable. |
| [`hooks/commit-msg`](hooks/commit-msg) | After commit message is written, before commit is finalized (`git commit`) | Commit message file only | < 20 ms | 1. Checks for `Co-authored-by:` trailers according to `hooks.coAuthorPolicy` (`warn` by default, `block`, or `allow`).<br>2. Chains repository-local `.git/hooks/commit-msg` if executable. |
| [`hooks/post-commit`](hooks/post-commit) | Immediately after a commit is created (`git commit`) | Newly created `HEAD` commit & upstream counter | < 30 ms | 1. Reminds if the commit introduced new `TODO`/`FIXME` lines.<br>2. Shows how many unpushed commits the branch is ahead of its upstream.<br>3. Chains repository-local `.git/hooks/post-commit` if executable. |
| [`hooks/post-checkout`](hooks/post-checkout) | After switching branches (`git checkout` / `git switch`, `$3 = 1`) | Git-tracked files only (untracked files are ignored) | ~20–150 ms | 1. Lists pending items in tracked `TODO.md` / `TODO.txt` (top 5 + count).<br>2. Summarizes tracked `TODO`/`FIXME` code markers via `git grep` (top 5 + total).<br>3. Chains repository-local `.git/hooks/post-checkout` if executable. |
| [`hooks/post-merge`](hooks/post-merge) | After a merge completes (`git merge` / `git pull`) | Files changed between `ORIG_HEAD` and `HEAD` | ~20–100 ms | 1. Compares updated `.env.example` against local `.env` and warns about missing keys.<br>2. Cleans obsolete local caches (`.pytest_cache`, `.mypy_cache`, `.ruff_cache`, `__pycache__`, `.vite`, `.turbo`, `.parcel-cache`, `.next/cache`) when critical config files change.<br>3. Chains repository-local `.git/hooks/post-merge` if executable. |
| [`hooks/pre-rebase`](hooks/pre-rebase) | Before a rebase starts (`git rebase` / `git rebase -i`) | Target branch & commit range being rewritten | < 30 ms | 1. Blocks rebasing protected/shared branches (`main`, `master`, `dev`, `develop`, `development`, `staging`, `pro`, `prod`, `production`).<br>2. Blocks rebasing commits that already have Git tags.<br>3. Automatically creates a backup branch (`backup/<branch>-<timestamp>`) before rewriting history.<br>4. Chains repository-local `.git/hooks/pre-rebase` if executable. |
| [`hooks/pre-push`](hooks/pre-push) | Before refs are pushed to a remote (`git push`) | Unpushed commits (`remote..local`, or full reachable history on a new branch) | ~0.1–1 s *(longer on brand-new branches with large history)* | 1. Runs **Gitleaks** (`--redact`) across the commit range being pushed.<br>2. Chains repository-local `.git/hooks/pre-push` if executable. |

## Stack

1. **Forbidden, Nested Repo & Oversized File Guard** (in `pre-commit`)
   - Blocks staging sensitive or unwanted files: `.env` / `.env.*` (allows `.env.example`, `.env.sample`, `.env.template`, `.env.dist`, `.env.schema`), OS metadata (`.DS_Store`, `Thumbs.db`, `desktop.ini`), and private key/certificate files (`*.pem`, `*.key`, `*.p12`, `*.pfx`, `id_rsa`, `id_ed25519`, `id_ecdsa`, `id_dsa`).
   - Blocks accidental nested Git repositories (staged mode `160000` gitlinks not registered in `.gitmodules`).
   - Blocks staged files larger than **5 MB** by default (configurable per repo via `git config --local hooks.maxFileSizeMB <MB>`, or `0` to disable).
   - Cross-platform: works on macOS, Linux, and Windows (Git for Windows / Git Bash, with LF line endings enforced via `git/.gitattributes` and Windows shim `PATH` + `cygpath` support).
2. **[Gitleaks](https://github.com/gitleaks/gitleaks)** + custom [`gitleaks.toml`](gitleaks.toml)
   - Inherits all default Gitleaks rules (`[extend] useDefault = true`).
   - Adds custom detection for:
     - **Connection URIs with credentials:** `postgres://<user>:<pass>@<host>`, `mysql://`, `mongodb+srv://`, `redis://`, `amqp://`, `sftp://`, `http://<user>:<pass>@<host>`.
     - **OpenAI keys under any variable name:** `sk-proj-...`, `sk-svcacct-...`.
     - **Hardcoded public IPv4 addresses:** catches VPS/server IP leaks while ignoring loopback (`127.x`), RFC1918 private subnets (`10.x`, `192.168.x`, `172.16-31.x`), and public DNS (`1.1.1.1`, `8.8.8.8`).
     - **Disguised high-entropy assignments:** catches complex passwords/tokens even when stored in variables with innocent names (`HANDSHAKE_SEED="..."`).
     - **Inline CLI passwords:** `sshpass -p`, `--password=...`.
3. **[detect-secrets](https://github.com/Yelp/detect-secrets)** (`detect-secrets-hook`)
   - Yelp's entropy and pattern analyzer (`Base64HighEntropyString`, `HexHighEntropyString`, `BasicAuthDetector`, `PrivateKeyDetector`, etc.) scanning all staged files.
4. **Local Hook Chaining**
   - Automatically chains `.git/hooks/pre-commit` and `.git/hooks/pre-push` if a repository defines its own local hooks (e.g., Husky or pre-commit framework).

## Usage

From the root of `agentsconfig`:

```bash
make install-git     # Install gitleaks + detect-secrets and configure global core.hooksPath
make status-git      # Check active hooksPath and installed versions
make test-git        # Test against disguised secrets, DB URIs, and public IPs
make scan-git DIR=.  # Audit an entire directory or repository
make uninstall-git   # Unset global core.hooksPath
```

### Running Hooks Manually (Without Committing or Pushing)

Run either hook from inside any Git repository without creating a commit or pushing to the remote:

- **Run `pre-commit` on currently staged files:**
  ```bash
  "$(git config --get core.hooksPath)/pre-commit"
  ```
- **Run `pre-push` without updating the remote:**
  ```bash
  git push --dry-run
  ```

## Bypassing & Allowlisting

### Inline Allowlisting (False Positives)

Ignore a single line without skipping the rest of the checks:

- **Gitleaks:** append `# gitleaks:allow` to the line.
- **detect-secrets:** append `# pragma: allowlist secret` to the line.
- **Both:** `# gitleaks:allow # pragma: allowlist secret`

### Per-Repository Configuration

Every hook and every individual validation can be toggled on or off (`true` / `false`) per repository with `git config --local` (or globally with `--global`). All switches default to `true`.

| Hook | Master switch | Individual validation switches | Extra options |
|---|---|---|---|
| `pre-commit` | `hooks.pre-commit.enabled` | `hooks.pre-commit.forbiddenFiles`<br>`hooks.pre-commit.nestedRepos`<br>`hooks.pre-commit.largeFiles`<br>`hooks.pre-commit.gitleaks`<br>`hooks.pre-commit.detectSecrets` | `hooks.maxFileSizeMB` (default `5`, `0` disables) |
| `prepare-commit-msg` | `hooks.prepare-commit-msg.enabled` | `hooks.prepare-commit-msg.protectedBranch` | `hooks.protectedBranches` (default `main master pro prod production`) |
| `commit-msg` | `hooks.commit-msg.enabled` | `hooks.commit-msg.coAuthor` | `hooks.coAuthorPolicy` (`warn` \| `block` \| `allow`) |
| `post-commit` | `hooks.post-commit.enabled` | `hooks.post-commit.todoReminder`<br>`hooks.post-commit.unpushedCount` | — |
| `post-checkout` | `hooks.post-checkout.enabled` | `hooks.post-checkout.todoFiles`<br>`hooks.post-checkout.todoMarkers` | — |
| `post-merge` | `hooks.post-merge.enabled` | `hooks.post-merge.envDiff`<br>`hooks.post-merge.cleanCache` | — |
| `pre-rebase` | `hooks.pre-rebase.enabled` | `hooks.pre-rebase.protectedBranch`<br>`hooks.pre-rebase.taggedCommits`<br>`hooks.pre-rebase.backup` | `hooks.protectedRebaseBranches` (default `main master dev develop development staging pro prod production`) |
| `pre-push` | `hooks.pre-push.enabled` | `hooks.pre-push.gitleaks` | — |

Examples:

```bash
git config --local hooks.commit-msg.coAuthor false              # disable Co-authored-by check in this repo
git config --local hooks.coAuthorPolicy block                   # warn (default) | block | allow
git config --local hooks.pre-commit.largeFiles false            # disable 5 MB limit in this repo
git config --local hooks.post-checkout.todoMarkers false        # keep TODO.md summary, skip code grep
git config --local hooks.pre-rebase.backup false                # skip auto backup/* branch on rebase
git config --local hooks.post-commit.enabled false              # disable the entire post-commit hook
```

### Skipping or Disabling Hooks

- **One-off bypass:** `git commit --no-verify` (or `git push --no-verify`).
- **Disable for a specific repository only** (e.g., a test repo):
  ```bash
  git config --local core.hooksPath .git/hooks
  ```
- **Disable globally:** `make uninstall-git`
