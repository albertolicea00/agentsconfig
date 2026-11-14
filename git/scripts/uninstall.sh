#!/usr/bin/env bash
# Uninstall global Git security hooks
set -euo pipefail

CURRENT_HOOKS="$(git config --global --get core.hooksPath || true)"
if [ -n "$CURRENT_HOOKS" ]; then
    git config --global --unset core.hooksPath
    echo "Removed global core.hooksPath (was: $CURRENT_HOOKS)"
else
    echo "No global core.hooksPath is currently configured."
fi
