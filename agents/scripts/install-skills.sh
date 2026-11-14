#!/usr/bin/env bash
# Install global agent skills from skills-lock.json files via npx skills
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AGENTS_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

FORCE=false
for arg in "$@"; do
    case "$arg" in
        --force)
            FORCE=true
            ;;
        *)
            echo "Unknown option: $arg" >&2
            echo "Usage: $(basename "$0") [--force]" >&2
            exit 1
            ;;
    esac
done

if ! command -v npx >/dev/null 2>&1; then
    echo "Error: npx is required to install skills. Install Node.js / npm first." >&2
    exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
    echo "Error: python3 is required to parse skills lockfiles." >&2
    exit 1
fi

echo "==> Reading skill lockfiles..."

SKILLS_LIST=()
while IFS= read -r line; do
    [ -n "$line" ] && SKILLS_LIST+=("$line")
done < <(
    python3 - "$AGENTS_DIR/skills-lock.json" "$AGENTS_DIR/.agents/.skill-lock.json" <<'PY'
import json
import os
import sys

seen = set()
for lock_path in sys.argv[1:]:
    if not os.path.isfile(lock_path):
        continue
    with open(lock_path, "r", encoding="utf-8") as f:
        data = json.load(f)
    skills = data.get("skills", {})
    for skill_name, meta in skills.items():
        source = meta.get("source") or meta.get("sourceUrl")
        if not source:
            continue
        key = (source, skill_name)
        if key in seen:
            continue
        seen.add(key)
        print(f"{source}|{skill_name}")
PY
)

if [ "${#SKILLS_LIST[@]}" -eq 0 ]; then
    echo "No skills found in lockfiles."
    exit 0
fi

INSTALLED=0
SKIPPED=0

for entry in "${SKILLS_LIST[@]}"; do
    source="${entry%%|*}"
    skill_name="${entry#*|}"
    skill_md="$HOME/.agents/skills/$skill_name/SKILL.md"

    if [ "$FORCE" = false ] && [ -f "$skill_md" ]; then
        echo "    [skip] $skill_name (already installed from $source)"
        SKIPPED=$((SKIPPED + 1))
        continue
    fi

    echo "    [install] $skill_name ($source)..."
    npx --yes skills add "$source" --skill "$skill_name" -g -y
    INSTALLED=$((INSTALLED + 1))
done

echo "==> Done: $INSTALLED installed, $SKIPPED skipped."
