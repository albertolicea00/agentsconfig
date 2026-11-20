#!/usr/bin/env bash
# Run self-tests in an isolated temporary repo to verify secret and IP detection
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GIT_CONFIG_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PRE_COMMIT_HOOK="$GIT_CONFIG_DIR/hooks/pre-commit"
PREPARE_COMMIT_MSG_HOOK="$GIT_CONFIG_DIR/hooks/prepare-commit-msg"
COMMIT_MSG_HOOK="$GIT_CONFIG_DIR/hooks/commit-msg"
POST_CHECKOUT_HOOK="$GIT_CONFIG_DIR/hooks/post-checkout"
POST_COMMIT_HOOK="$GIT_CONFIG_DIR/hooks/post-commit"
POST_MERGE_HOOK="$GIT_CONFIG_DIR/hooks/post-merge"
PRE_REBASE_HOOK="$GIT_CONFIG_DIR/hooks/pre-rebase"

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

git -C "$TMP_REPO" reset -q
rm -rf "$TMP_REPO/nested-repo"

echo ""
echo "==> Testing commit-msg Co-authored-by policy (warn / block / allow)..."
MSG_FILE="$TMP_REPO/COMMIT_EDITMSG"
printf 'feat: test commit\n\nCo-authored-by: Test Bot <bot@example.com>\n' > "$MSG_FILE"

# Default policy (warn): exits 0 with warning
if (cd "$TMP_REPO" && "$COMMIT_MSG_HOOK" "$MSG_FILE"); then
    echo "SUCCESS: commit-msg warned and allowed under default policy (warn)."
else
    echo "FAILURE: commit-msg blocked under default warn policy!" >&2
    exit 1
fi

# Block policy: exits non-zero
git -C "$TMP_REPO" config --local hooks.coAuthorPolicy block
set +e
(cd "$TMP_REPO" && "$COMMIT_MSG_HOOK" "$MSG_FILE")
BLOCK_EXIT=$?
set -e
if [ "$BLOCK_EXIT" -ne 0 ]; then
    echo "SUCCESS: commit-msg blocked Co-authored-by under block policy."
else
    echo "FAILURE: commit-msg did NOT block Co-authored-by under block policy!" >&2
    exit 1
fi

# Allow policy: exits 0 silently
git -C "$TMP_REPO" config --local hooks.coAuthorPolicy allow
if (cd "$TMP_REPO" && "$COMMIT_MSG_HOOK" "$MSG_FILE"); then
    echo "SUCCESS: commit-msg allowed Co-authored-by under allow policy."
else
    echo "FAILURE: commit-msg failed under allow policy!" >&2
    exit 1
fi

echo ""
echo "==> Testing post-checkout tracked TODO/FIXME summary (ignoring untracked files)..."
printf '# TODO\n\n- [ ] Ship v1\n- [x] Done item\n' > "$TMP_REPO/TODO.md"
printf '// TODO: refactor helper\n' > "$TMP_REPO/app.js"
printf '// TODO: should be ignored because untracked\n' > "$TMP_REPO/untracked.js"
git -C "$TMP_REPO" add TODO.md app.js
git -C "$TMP_REPO" commit --no-verify -q -m "add tracked todo fixtures"

POST_CHECKOUT_OUT="$(cd "$TMP_REPO" && "$POST_CHECKOUT_HOOK" HEAD HEAD 1)"
printf '%s\n' "$POST_CHECKOUT_OUT"
if printf '%s' "$POST_CHECKOUT_OUT" | grep -q 'Ship v1' \
    && printf '%s' "$POST_CHECKOUT_OUT" | grep -q 'app.js' \
    && ! printf '%s' "$POST_CHECKOUT_OUT" | grep -q 'untracked.js'; then
    echo "SUCCESS: post-checkout reported tracked TODO.md and app.js while ignoring untracked.js."
else
    echo "FAILURE: post-checkout output did not match expectations!" >&2
    exit 1
fi

echo ""
echo "==> Testing post-commit new TODO/FIXME reminder..."
POST_COMMIT_OUT="$(cd "$TMP_REPO" && "$POST_COMMIT_HOOK")"
printf '%s\n' "$POST_COMMIT_OUT"
if printf '%s' "$POST_COMMIT_OUT" | grep -q 'introduced 1 new TODO/FIXME'; then
    echo "SUCCESS: post-commit reported newly introduced TODO/FIXME."
else
    echo "FAILURE: post-commit did not report newly introduced TODO/FIXME!" >&2
    exit 1
fi

echo ""
echo "==> Testing prepare-commit-msg protected branch warning..."
git -C "$TMP_REPO" checkout -q -B prod
EDIT_MSG_FILE="$TMP_REPO/PREPARE_MSG"
printf '\n# Please enter the commit message\n' > "$EDIT_MSG_FILE"
(cd "$TMP_REPO" && "$PREPARE_COMMIT_MSG_HOOK" "$EDIT_MSG_FILE" "")
if head -n 1 "$EDIT_MSG_FILE" | grep -q "WARNING: You are committing directly to protected branch 'prod'!"; then
    echo "SUCCESS: prepare-commit-msg inserted protected branch warning banner on 'prod'."
else
    echo "FAILURE: prepare-commit-msg did NOT insert protected branch warning banner!" >&2
    cat "$EDIT_MSG_FILE" >&2
    exit 1
fi

echo ""
echo "==> Testing post-merge (.env.example diff & cache cleanup)..."
git -C "$TMP_REPO" checkout -q -B feature/merge-test
printf 'EXISTING_KEY=1\n' > "$TMP_REPO/.env"
printf 'EXISTING_KEY=1\nNEW_REQUIRED_KEY=\n' > "$TMP_REPO/.env.example"
printf '[tool.pytest.ini_options]\n' > "$TMP_REPO/pyproject.toml"
mkdir -p "$TMP_REPO/.pytest_cache" "$TMP_REPO/pkg/__pycache__"
git -C "$TMP_REPO" add .env.example pyproject.toml
git -C "$TMP_REPO" commit --no-verify -q -m "update env example and pyproject"
git -C "$TMP_REPO" update-ref ORIG_HEAD HEAD~1

POST_MERGE_OUT="$(cd "$TMP_REPO" && "$POST_MERGE_HOOK" 2>&1)"
printf '%s\n' "$POST_MERGE_OUT"
if printf '%s' "$POST_MERGE_OUT" | grep -q 'NEW_REQUIRED_KEY' \
    && [ ! -d "$TMP_REPO/.pytest_cache" ] \
    && [ ! -d "$TMP_REPO/pkg/__pycache__" ]; then
    echo "SUCCESS: post-merge flagged missing .env key and cleaned obsolete caches."
else
    echo "FAILURE: post-merge did not detect missing key or clean caches!" >&2
    exit 1
fi

echo ""
echo "==> Testing pre-rebase (protected branch, tagged commit, and auto-backup)..."
# 1. Protected branch ('develop') should be blocked
git -C "$TMP_REPO" checkout -q -B develop
set +e
(cd "$TMP_REPO" && "$PRE_REBASE_HOOK" HEAD~1)
PROTECTED_REBASE_EXIT=$?
set -e
if [ "$PROTECTED_REBASE_EXIT" -ne 0 ]; then
    echo "SUCCESS: pre-rebase blocked rebasing protected branch 'develop'."
else
    echo "FAILURE: pre-rebase did NOT block rebasing 'develop'!" >&2
    exit 1
fi

# 2. Tagged commit on a feature branch should be blocked
git -C "$TMP_REPO" checkout -q -B feature/tagged
printf 'release\n' > "$TMP_REPO/release.txt"
git -C "$TMP_REPO" add release.txt
git -C "$TMP_REPO" commit --no-verify -q -m "release v1.0.0"
git -C "$TMP_REPO" tag v1.0.0
set +e
(cd "$TMP_REPO" && "$PRE_REBASE_HOOK" HEAD~1)
TAGGED_REBASE_EXIT=$?
set -e
if [ "$TAGGED_REBASE_EXIT" -ne 0 ]; then
    echo "SUCCESS: pre-rebase blocked rebasing tagged commit (v1.0.0)."
else
    echo "FAILURE: pre-rebase did NOT block rebasing tagged commit!" >&2
    exit 1
fi

# 3. Clean untagged feature branch should succeed and create backup/* branch
git -C "$TMP_REPO" checkout -q -B feature/clean HEAD~1
printf 'wip\n' > "$TMP_REPO/wip.txt"
git -C "$TMP_REPO" add wip.txt
git -C "$TMP_REPO" commit --no-verify -q -m "wip commit"
if (cd "$TMP_REPO" && "$PRE_REBASE_HOOK" HEAD~1) \
    && git -C "$TMP_REPO" branch --list 'backup/feature-clean-*' | grep -q 'backup/feature-clean-'; then
    echo "SUCCESS: pre-rebase allowed feature branch and created backup branch."
else
    echo "FAILURE: pre-rebase failed or did not create backup branch!" >&2
    exit 1
fi

echo ""
echo "==> Testing per-validation individual toggle switches..."
git -C "$TMP_REPO" config --local hooks.pre-commit.largeFiles false
git -C "$TMP_REPO" add large.bin
if (cd "$TMP_REPO" && "$PRE_COMMIT_HOOK"); then
    echo "SUCCESS: hooks.pre-commit.largeFiles=false bypassed the 5 MB file size check."
else
    echo "FAILURE: hooks.pre-commit.largeFiles=false did NOT bypass the size check!" >&2
    exit 1
fi
git -C "$TMP_REPO" reset -q
git -C "$TMP_REPO" config --local --unset hooks.pre-commit.largeFiles
