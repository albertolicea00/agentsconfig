#!/usr/bin/env bash
# Install global agent configs to $HOME and install global skills
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AGENTS_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

CONFIGS_ONLY=false
SKILLS_ARGS=()

for arg in "$@"; do
    case "$arg" in
        --configs-only)
            CONFIGS_ONLY=true
            ;;
        --force)
            SKILLS_ARGS+=("--force")
            ;;
        *)
            echo "Unknown option: $arg" >&2
            echo "Usage: $(basename "$0") [--configs-only] [--force]" >&2
            exit 1
            ;;
    esac
done

AGENT_DIRS=(.claude .codex .codexbar .continue .copilot .gemini .agents)

echo "==> Installing global agent configs to $HOME..."
COPIED=0

for dir in "${AGENT_DIRS[@]}"; do
    SRC_DIR="$AGENTS_DIR/$dir"
    [ -d "$SRC_DIR" ] || continue

    while IFS= read -r -d '' src_file; do
        rel_path="${src_file#"$AGENTS_DIR"/}"
        dst_file="$HOME/$rel_path"
        mkdir -p "$(dirname "$dst_file")"
        cp "$src_file" "$dst_file"
        echo "    [ok] ~/$rel_path"
        COPIED=$((COPIED + 1))
    done < <(find "$SRC_DIR" -type f -not -name ".gitkeep" -not -name ".DS_Store" -print0 | sort -z)
done

if [ -f "$AGENTS_DIR/skills-lock.json" ]; then
    cp "$AGENTS_DIR/skills-lock.json" "$HOME/skills-lock.json"
    echo "    [ok] ~/skills-lock.json"
    COPIED=$((COPIED + 1))
fi

echo "==> Copied $COPIED config file(s) to $HOME."

if [ "$CONFIGS_ONLY" = false ]; then
    echo ""
    bash "$SCRIPT_DIR/install-skills.sh" "${SKILLS_ARGS[@]+"${SKILLS_ARGS[@]}"}"
fi
