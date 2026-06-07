#!/usr/bin/env bash
# Validates parent: frontmatter edges in the memory corpus.
# Every parent: value must resolve to an existing .md file whose basename
# matches the slug. Exits non-zero when any dangling parent is found.
#
# Usage:
#   lint-graph-edges.sh [MEMORY_DIR]
#
# MEMORY_DIR defaults to ~/.claude/projects/-home-josh-gamedev-volley/memory
# when not supplied, so the hook can run with no arguments.

set -euo pipefail

MEMORY_DIR="${1:-$HOME/.claude/projects/-home-josh-gamedev-volley/memory}"

if [[ ! -d "$MEMORY_DIR" ]]; then
    echo "lint-graph-edges: memory dir not found: $MEMORY_DIR" >&2
    exit 1
fi

dangling=0
orphans=0

while IFS= read -r -d '' filepath; do
    filename="$(basename "$filepath" .md)"

    # Extract parent: value from YAML frontmatter (between the first --- pair).
    parent_value=$(awk '
        /^---$/ { fence++; next }
        fence == 1 && /^parent:/ { sub(/^parent:[[:space:]]*/, ""); print; exit }
        fence >= 2 { exit }
    ' "$filepath")

    if [[ -z "$parent_value" ]]; then
        orphans=$((orphans + 1))
        continue
    fi

    # Resolve: a slug matches if <slug>.md exists anywhere under MEMORY_DIR.
    target="$MEMORY_DIR/${parent_value}.md"

    if [[ ! -f "$target" ]]; then
        echo "dangling parent: $filename -> $parent_value (no file: ${parent_value}.md)"
        dangling=$((dangling + 1))
    fi
done < <(find "$MEMORY_DIR" -name "*.md" -print0 | sort -z)

echo "lint-graph-edges: $dangling dangling, $orphans root/untyped nodes"

if [[ "$dangling" -gt 0 ]]; then
    exit 1
fi
