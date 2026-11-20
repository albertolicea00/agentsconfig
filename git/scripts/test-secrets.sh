#!/usr/bin/env bash
# Run self-tests in an isolated temporary repo to verify secret and IP detection
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GIT_CONFIG_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PRE_COMMIT_HOOK="$GIT_CONFIG_DIR/hooks/pre-commit"

TMP_REPO="$(mktemp -d "${TMPDIR:-/tmp}/agentsconfig-git-test.XXXXXX")"
trap 'rm -rf "$TMP_REPO"' EXIT

git -C "$TMP_REPO" init -q
git -C "$TMP_REPO" config user.name "Test User"
git -C "$TMP_REPO" config user.email "test@example.com"

# Build test tokens dynamically so this test script itself contains no literal secrets
PROTO="postgres"
DB_CRED="admin:Sup3rS3cr3tP4ssw0rd!99"
VPS_IP="198.51.100.42"
OPENAI_PREFIX="sk-proj-"
OPENAI_BODY="T9xKqLmN2pQrStUvWxYz1234567890AbCdEfGhIjKlMnOpQrSt" # pragma: allowlist secret
CAMOUFLAGED_PASS="MiClaveSuperSecretaDelVPS2026!"

cat << EOF > "$TMP_REPO/disguised_secrets.sh"
#!/usr/bin/env bash
# 1. Database URI with embedded credentials & public IP
DB_URI="${PROTO}://${DB_CRED}@${VPS_IP}:5432/prod_db"

# 2. Innocent variable name holding an OpenAI project key
DEFAULT_HEADER_VAL="${OPENAI_PREFIX}${OPENAI_BODY}"

# 3. Hardcoded VPS public IP and disguised high-entropy password
NODE_ENDPOINT="${VPS_IP}"
HANDSHAKE_SEED="${CAMOUFLAGED_PASS}"
EOF

git -C "$TMP_REPO" add disguised_secrets.sh

echo "==> Testing global pre-commit hook against disguised secrets in $TMP_REPO..."
echo ""

set +e
(cd "$TMP_REPO" && "$PRE_COMMIT_HOOK")
EXIT_CODE=$?
set -e

echo ""
if [ "$EXIT_CODE" -ne 0 ]; then
    echo "SUCCESS: Global pre-commit hook blocked the disguised secrets (exit code $EXIT_CODE)."
else
    echo "FAILURE: Global pre-commit hook did NOT block the disguised secrets!" >&2
    exit 1
fi

# Reset staging area and verify forbidden/large file guards
git -C "$TMP_REPO" reset -q

echo ""
echo "==> Testing forbidden files (.env, .DS_Store, Thumbs.db, .pem)..."
printf 'APP_MODE=development\n' > "$TMP_REPO/.env"
printf 'junk\n' > "$TMP_REPO/.DS_Store"
printf 'junk\n' > "$TMP_REPO/Thumbs.db"
printf 'placeholder\n' > "$TMP_REPO/cert.pem"
git -C "$TMP_REPO" add -f .env .DS_Store Thumbs.db cert.pem

set +e
(cd "$TMP_REPO" && "$PRE_COMMIT_HOOK")
FORBIDDEN_EXIT=$?
set -e

if [ "$FORBIDDEN_EXIT" -ne 0 ]; then
    echo "SUCCESS: Global pre-commit hook blocked forbidden files."
else
    echo "FAILURE: Global pre-commit hook did NOT block forbidden files!" >&2
    exit 1
fi

git -C "$TMP_REPO" reset -q

echo ""
echo "==> Testing allowed template file (.env.example)..."
printf 'APP_MODE=development\n' > "$TMP_REPO/.env.example"
git -C "$TMP_REPO" add .env.example

if (cd "$TMP_REPO" && "$PRE_COMMIT_HOOK"); then
    echo "SUCCESS: Global pre-commit hook allowed .env.example."
else
    echo "FAILURE: Global pre-commit hook blocked .env.example!" >&2
    exit 1
fi

git -C "$TMP_REPO" reset -q

echo ""
echo "==> Testing oversized staged file (> 5 MB)..."
dd if=/dev/zero of="$TMP_REPO/large.bin" bs=1048576 count=6 status=none
git -C "$TMP_REPO" add large.bin

set +e
(cd "$TMP_REPO" && "$PRE_COMMIT_HOOK")
LARGE_EXIT=$?
set -e

if [ "$LARGE_EXIT" -ne 0 ]; then
    echo "SUCCESS: Global pre-commit hook blocked oversized file (> 5 MB)."
else
    echo "FAILURE: Global pre-commit hook did NOT block oversized file!" >&2
    exit 1
fi

git -C "$TMP_REPO" reset -q

echo ""
echo "==> Testing accidental nested Git repository (unregistered gitlink)..."
mkdir -p "$TMP_REPO/nested-repo"
git -C "$TMP_REPO/nested-repo" init -q
git -C "$TMP_REPO/nested-repo" config user.name "Test User"
git -C "$TMP_REPO/nested-repo" config user.email "test@example.com"
printf 'hello\n' > "$TMP_REPO/nested-repo/README.md"
git -C "$TMP_REPO/nested-repo" add README.md
git -C "$TMP_REPO/nested-repo" commit --no-verify -q -m "init nested"
git -C "$TMP_REPO" add nested-repo

set +e
(cd "$TMP_REPO" && "$PRE_COMMIT_HOOK")
NESTED_EXIT=$?
set -e

if [ "$NESTED_EXIT" -ne 0 ]; then
    echo "SUCCESS: Global pre-commit hook blocked nested Git repository."
else
    echo "FAILURE: Global pre-commit hook did NOT block nested Git repository!" >&2
    exit 1
fi
