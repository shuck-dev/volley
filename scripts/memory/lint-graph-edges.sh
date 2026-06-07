#!/usr/bin/env bash
# Validates parent: frontmatter edges in the memory corpus, and optionally
# renders the forest as a tree.
#
# Every parent: value must resolve to an existing .md file whose basename
# matches the slug. Exits non-zero when any dangling parent is found.
#
# Usage:
#   lint-graph-edges.sh [MEMORY_DIR]            validate (default)
#   lint-graph-edges.sh --tree [MEMORY_DIR]     render the forest, then validate
#
# parent: may sit at the top level of the frontmatter or nested under
# metadata: (any indentation); both are read. MEMORY_DIR defaults to
# ~/.claude/projects/-home-josh-gamedev-volley/memory so the hook runs with
# no arguments.

set -euo pipefail

mode="lint"
if [[ "${1:-}" == "--tree" ]]; then
    mode="tree"
    shift
fi

MEMORY_DIR="${1:-$HOME/.claude/projects/-home-josh-gamedev-volley/memory}"

if [[ ! -d "$MEMORY_DIR" ]]; then
    echo "lint-graph-edges: memory dir not found: $MEMORY_DIR" >&2
    exit 1
fi

# Read a file's parent: slug from its frontmatter (top-level or nested under
# metadata:, at any indent). Prints the slug, or nothing for a root.
read_parent() {
    awk '
        /^---[[:space:]]*$/ { fence++; next }
        fence == 1 && /^[[:space:]]*parent:[[:space:]]*/ {
            sub(/^[[:space:]]*parent:[[:space:]]*/, ""); print; exit
        }
        fence >= 2 { exit }
    ' "$1"
}

dangling=0
orphans=0
# slug -> parent slug, for the tree render
declare -A PARENT_OF
declare -A IS_NODE

while IFS= read -r -d '' filepath; do
    filename="$(basename "$filepath" .md)"
    IS_NODE["$filename"]=1
    parent_value="$(read_parent "$filepath")"

    if [[ -z "$parent_value" ]]; then
        orphans=$((orphans + 1))
        PARENT_OF["$filename"]=""
        continue
    fi

    PARENT_OF["$filename"]="$parent_value"

    if [[ ! -f "$MEMORY_DIR/${parent_value}.md" ]]; then
        echo "dangling parent: $filename -> $parent_value (no file: ${parent_value}.md)"
        dangling=$((dangling + 1))
    fi
done < <(find "$MEMORY_DIR" -name "*.md" -print0 | sort -z)

if [[ "$mode" == "tree" ]]; then
    # Render each root and descend its children. A node whose parent is empty,
    # or whose parent does not resolve to a known node, is treated as a root.
    print_children() {
        local parent="$1" indent="$2" child
        for child in $(printf '%s\n' "${!PARENT_OF[@]}" | sort); do
            if [[ "${PARENT_OF[$child]}" == "$parent" ]]; then
                printf '%s- %s\n' "$indent" "$child"
                print_children "$child" "  $indent"
            fi
        done
    }
    typed_roots=0
    for node in $(printf '%s\n' "${!IS_NODE[@]}" | sort); do
        p="${PARENT_OF[$node]:-}"
        # A root with at least one child is a typed-tree top; show those.
        if [[ -z "$p" || -z "${IS_NODE[$p]:-}" ]]; then
            if printf '%s\n' "${PARENT_OF[@]}" | grep -qx "$node"; then
                printf '%s\n' "$node"
                print_children "$node" "  "
                typed_roots=$((typed_roots + 1))
            fi
        fi
    done
    echo "--- $typed_roots roots with children; flat roots omitted ---"
fi

echo "lint-graph-edges: $dangling dangling, $orphans root/untyped nodes"

if [[ "$dangling" -gt 0 ]]; then
    exit 1
fi
