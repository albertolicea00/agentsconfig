#!/usr/bin/env bash
# Check sync status between repo agent configs/skills and $HOME
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AGENTS_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

if ! command -v python3 >/dev/null 2>&1; then
    echo "Error: python3 is required to inspect skill lockfiles." >&2
    exit 1
fi

echo "==> Config files sync status (repo vs $HOME):"

IN_SYNC=0
DIFFERS=0
MISSING=0

while IFS= read -r -d '' repo_file; do
    rel_path="${repo_file#"$AGENTS_DIR"/}"
    home_file="$HOME/$rel_path"

    if [ ! -f "$home_file" ]; then
        printf "    %-10s %s\n" "MISSING" "~/$rel_path"
        MISSING=$((MISSING + 1))
    elif cmp -s "$repo_file" "$home_file"; then
        printf "    %-10s %s\n" "IN SYNC" "~/$rel_path"
        IN_SYNC=$((IN_SYNC + 1))
    else
        printf "    %-10s %s\n" "DIFFERS" "~/$rel_path"
        DIFFERS=$((DIFFERS + 1))
    fi
done < <(
    find "$AGENTS_DIR" \
        -path "$AGENTS_DIR/scripts" -prune -o \
        -type f \
        -not -path "$AGENTS_DIR/Makefile" \
        -not -path "$AGENTS_DIR/AGENTS.md" \
        -not -path "$AGENTS_DIR/README.md" \
        -not -path "$AGENTS_DIR/CHANGELOG.md" \
        -not -name ".gitkeep" \
        -not -name ".DS_Store" \
        -print0 | sort -z
)

echo "    Summary: $IN_SYNC in sync, $DIFFERS differ(s), $MISSING missing"
echo ""
echo "==> Global skills status (lockfiles vs ~/.agents/skills/):"

python3 - "$AGENTS_DIR/skills-lock.json" "$AGENTS_DIR/.agents/.skill-lock.json" "$HOME/.agents/skills" <<'PY'
import json
import os
import sys

lock_paths = sys.argv[1:3]
skills_dir = sys.argv[3]

unique_skills = {}
for path in lock_paths:
    if not os.path.isfile(path):
        continue
    with open(path, "r", encoding="utf-8") as f:
        data = json.load(f)
    for name, meta in data.get("skills", {}).items():
        unique_skills.setdefault(name, meta.get("source") or meta.get("sourceUrl") or "unknown")

installed = 0
missing = []
for name in sorted(unique_skills):
    skill_md = os.path.join(skills_dir, name, "SKILL.md")
    if os.path.isfile(skill_md):
        installed += 1
    else:
        missing.append((name, unique_skills[name]))

print(f"    Lockfiles define {len(unique_skills)} unique skill(s); {installed} installed in ~/.agents/skills/")
if missing:
    print("    Missing skills:")
    for name, source in missing:
        print(f"      - {name} ({source})")
PY
