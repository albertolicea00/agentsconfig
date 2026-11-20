# Git Security Configuration (`git/`)

Global Git hooks and rules that protect every repository on the machine from accidentally committing secrets, credentials, connection URIs, or hardcoded server IPs.

100% local and offline — no telemetry, no cloud API calls.

## Hooks

| Hook | Triggers on | Scope | Typical duration | What it runs |
|---|---|---|---|---|
| [`hooks/pre-commit`](hooks/pre-commit) | Before a commit is created (`git commit`) | Staged changes & staged files only | ~0.3–1.5 s *(scales with staged files)* | 1. Blocks forbidden files (`.env`, `.DS_Store`, `Thumbs.db`, `desktop.ini`, private keys/certs), accidental nested Git repos (`160000` without `.gitmodules`), and files `> 5 MB`.<br>2. Runs **Gitleaks** (`--staged --redact`) with local `.gitleaks.toml` or global [`gitleaks.toml`](gitleaks.toml).<br>3. Runs **detect-secrets-hook** on staged files (excluding lockfiles; uses `.secrets.baseline` if present).<br>4. Chains repository-local `.git/hooks/pre-commit` if executable. |
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

## Bypassing & Allowlisting

### Inline Allowlisting (False Positives)

Ignore a single line without skipping the rest of the checks:

- **Gitleaks:** append `# gitleaks:allow` to the line.
- **detect-secrets:** append `# pragma: allowlist secret` to the line.
- **Both:** `# gitleaks:allow # pragma: allowlist secret`

### Skipping or Disabling Hooks

- **One-off bypass:** `git commit --no-verify` (or `git push --no-verify`).
- **Disable for a specific repository only** (e.g., a test repo):
  ```bash
  git config --local core.hooksPath .git/hooks
  ```
- **Disable globally:** `make uninstall-git`
