#!/usr/bin/env bash
# Install global Git security hooks (Gitleaks + detect-secrets)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GIT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
HOOKS_DIR="$GIT_DIR/hooks"

echo "==> Checking dependencies..."

if ! command -v gitleaks >/dev/null 2>&1; then
    if command -v brew >/dev/null 2>&1; then
        echo "Installing gitleaks via Homebrew..."
        HOMEBREW_NO_AUTO_UPDATE=1 brew install gitleaks
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
    else
        echo "Error: detect-secrets is not installed. Install it with 'brew install detect-secrets' or 'pip install detect-secrets'." >&2
        exit 1
    fi
fi

chmod +x "$HOOKS_DIR/pre-commit" "$HOOKS_DIR/pre-push"
git config --global core.hooksPath "$HOOKS_DIR"

echo "==> Global Git hooks configured!"
echo "    core.hooksPath -> $(git config --global --get core.hooksPath)"
echo "    gitleaks       -> $(command -v gitleaks) ($(gitleaks version))"
echo "    detect-secrets -> $(command -v detect-secrets) ($(detect-secrets --version))"
