#!/usr/bin/env bash
# Shared helper functions for global Git hooks
set -euo pipefail

# Return 0 (true) unless the git config key (or optional legacy fallback key) is false/0/no/off
hook_is_enabled() {
    local val
    val="$(git config --get "$1" 2>/dev/null | tr -d '\r' | tr '[:upper:]' '[:lower:]' || true)"
    if [ -z "$val" ] && [ -n "${2:-}" ]; then
        val="$(git config --get "$2" 2>/dev/null | tr -d '\r' | tr '[:upper:]' '[:lower:]' || true)"
    fi
    case "$val" in
        false|0|no|off) return 1 ;;
        *) return 0 ;;
    esac
}
