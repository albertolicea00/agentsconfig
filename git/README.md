# Git Security Configuration (`git/`)

Global Git hooks and rules that protect every repository on the machine from accidentally committing secrets, credentials, connection URIs, or hardcoded server IPs.

100% local and offline — no telemetry, no cloud API calls.

## Stack

1. **[Gitleaks](https://github.com/gitleaks/gitleaks)** + custom [`gitleaks.toml`](gitleaks.toml)
   - Inherits all default Gitleaks rules (`[extend] useDefault = true`).
   - Adds custom detection for:
     - **Connection URIs with credentials:** `postgres://<user>:<pass>@<host>`, `mysql://`, `mongodb+srv://`, `redis://`, `amqp://`, `sftp://`, `http://<user>:<pass>@<host>`.
     - **OpenAI keys under any variable name:** `sk-proj-...`, `sk-svcacct-...`.
     - **Hardcoded public IPv4 addresses:** catches VPS/server IP leaks while ignoring loopback (`127.x`), RFC1918 private subnets (`10.x`, `192.168.x`, `172.16-31.x`), and public DNS (`1.1.1.1`, `8.8.8.8`).
     - **Disguised high-entropy assignments:** catches complex passwords/tokens even when stored in variables with innocent names (`HANDSHAKE_SEED="..."`).
     - **Inline CLI passwords:** `sshpass -p`, `--password=...`.
2. **[detect-secrets](https://github.com/Yelp/detect-secrets)** (`detect-secrets-hook`)
   - Yelp's entropy and pattern analyzer (`Base64HighEntropyString`, `HexHighEntropyString`, `BasicAuthDetector`, `PrivateKeyDetector`, etc.) scanning all staged files.
3. **Local Hook Chaining**
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

## Inline Allowlisting (False Positives)

- **Gitleaks:** append `# gitleaks:allow` to the line.
- **detect-secrets:** append `# pragma: allowlist secret` to the line.
- **Both:** `# gitleaks:allow # pragma: allowlist secret`
- **One-off commit bypass:** `git commit --no-verify`
