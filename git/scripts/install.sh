#!/usr/bin/env bash
# Install global Git security hooks (Gitleaks + detect-secrets)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
GIT_DIR="$(cd "$SCRIPT_DIR/.." && pwd -P)"
HOOKS_DIR="$GIT_DIR/hooks"

if command -v cygpath >/dev/null 2>&1; then
    HOOKS_PATH_CONFIG="$(cygpath -m "$HOOKS_DIR")"
else
    HOOKS_PATH_CONFIG="$HOOKS_DIR"
fi

echo "==> Checking dependencies..."

if ! command -v gitleaks >/dev/null 2>&1; then
    if command -v brew >/dev/null 2>&1; then
        echo "Installing gitleaks via Homebrew..."
        HOMEBREW_NO_AUTO_UPDATE=1 brew install gitleaks
    elif command -v winget >/dev/null 2>&1; then
        echo "Installing gitleaks via winget..."
        winget install --id Gitleaks.Gitleaks -e --accept-source-agreements --accept-package-agreements
    elif command -v scoop >/dev/null 2>&1; then
        echo "Installing gitleaks via Scoop..."
        scoop install gitleaks
    elif command -v choco >/dev/null 2>&1; then
        echo "Installing gitleaks via Chocolatey..."
        choco install gitleaks -y
    else
        echo "Error: gitleaks is not installed. Install it from https://github.com/gitleaks/gitleaks" >&2
        exit 1
    fi
fi

if ! command -v detect-secrets-hook >/dev/null 2>&1; then
    if command -v brew >/dev/null 2>&1; then
        echo "Installing detect-secrets via Homebrew..."
        HOMEBREW_NO_AUTO_UPDATE=1 brew install detect-secrets
    elif command -v uv >/dev/null 2>&1; then
        echo "Installing detect-secrets via uv..."
        uv tool install detect-secrets
    elif command -v pip3 >/dev/null 2>&1; then
        echo "Installing detect-secrets via pip3..."
        pip3 install --user detect-secrets
    elif command -v pip >/dev/null 2>&1; then
        echo "Installing detect-secrets via pip..."
        pip install --user detect-secrets
    elif command -v py >/dev/null 2>&1; then
        echo "Installing detect-secrets via py -m pip..."
        py -m pip install --user detect-secrets
    else
        echo "Error: detect-secrets is not installed. Install it with 'brew install detect-secrets', 'uv tool install detect-secrets', or 'pip install detect-secrets'." >&2
        exit 1
    fi
fi

chmod +x "$HOOKS_DIR/pre-commit" "$HOOKS_DIR/prepare-commit-msg" "$HOOKS_DIR/commit-msg" "$HOOKS_DIR/post-commit" "$HOOKS_DIR/post-checkout" "$HOOKS_DIR/post-merge" "$HOOKS_DIR/pre-rebase" "$HOOKS_DIR/pre-push"
git config --global core.hooksPath "$HOOKS_PATH_CONFIG"

echo "==> Global Git hooks configured!"
echo "    core.hooksPath -> $(git config --global --get core.hooksPath)"
echo "    gitleaks       -> $(command -v gitleaks) ($(gitleaks version))"
echo "    detect-secrets -> $(command -v detect-secrets) ($(detect-secrets --version))"
