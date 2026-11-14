#!/usr/bin/env bash
# Pull tracked global agent configs and skill lockfiles from $HOME into repo
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AGENTS_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

AGENT_DIRS=(.claude .codex .codexbar .continue .copilot .gemini)

echo "==> Pulling tracked global agent configs from $HOME..."
PULLED=0
MISSING=0

for dir in "${AGENT_DIRS[@]}"; do
    REPO_DIR="$AGENTS_DIR/$dir"
    [ -d "$REPO_DIR" ] || continue

    while IFS= read -r -d '' repo_file; do
        rel_path="${repo_file#"$AGENTS_DIR"/}"
        home_file="$HOME/$rel_path"
        if [ -f "$home_file" ]; then
            cp "$home_file" "$repo_file"
            echo "    [pulled] ~/$rel_path -> agents/$rel_path"
            PULLED=$((PULLED + 1))
        else
            echo "    [missing] ~/$rel_path"
            MISSING=$((MISSING + 1))
        fi
    done < <(find "$REPO_DIR" -type f -not -name ".gitkeep" -not -name ".DS_Store" -print0 | sort -z)
done

if [ -f "$HOME/skills-lock.json" ]; then
    cp "$HOME/skills-lock.json" "$AGENTS_DIR/skills-lock.json"
    echo "    [pulled] ~/skills-lock.json -> agents/skills-lock.json"
    PULLED=$((PULLED + 1))
fi

if [ -f "$HOME/.agents/.skill-lock.json" ]; then
    mkdir -p "$AGENTS_DIR/.agents"
    cp "$HOME/.agents/.skill-lock.json" "$AGENTS_DIR/.agents/.skill-lock.json"
    echo "    [pulled] ~/.agents/.skill-lock.json -> agents/.agents/.skill-lock.json"
    PULLED=$((PULLED + 1))
fi

echo "==> Pulled $PULLED file(s) ($MISSING missing in \$HOME)."
