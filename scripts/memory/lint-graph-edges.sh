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
done < <(find "$MEMORY_DIR" -name "*.md" -print0 | sort -z)

# Resolve parents against the set of known nodes (any subdir), not a fixed path,
# so a parent file in letters/ or any subdir resolves. Done as a second pass so
# a parent seen later in the walk still counts.
for child in "${!PARENT_OF[@]}"; do
    p="${PARENT_OF[$child]}"
    [[ -z "$p" ]] && continue
    if [[ -z "${IS_NODE[$p]:-}" ]]; then
        echo "dangling parent: $child -> $p (no node: $p)"
        dangling=$((dangling + 1))
    fi
done

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
    # Show the WHOLE navigable surface: ordered trees first (roots with
    # children), then every unordered node (a root with no children, not yet
    # placed). A fresh instance must be able to reach all of them, so render all.
    has_children() { printf '%s\n' "${PARENT_OF[@]}" | grep -qx "$1"; }
    is_root() { local p="${PARENT_OF[$1]:-}"; [[ -z "$p" || -z "${IS_NODE[$p]:-}" ]]; }
    typed_roots=0
    unordered=0
    for node in $(printf '%s\n' "${!IS_NODE[@]}" | sort); do
        if is_root "$node" && has_children "$node"; then
            printf '%s\n' "$node"
            print_children "$node" "  "
            typed_roots=$((typed_roots + 1))
        fi
    done
    # Bridge: group the unordered nodes under their proposed trunk, so the render
    # shows a navigable forest (trunks), not a flat dump. The bucketing map is a
    # markdown file with "## <trunk> (N)" headers and "- <node>" lines.
    BRIDGE="${BRIDGE_MAP:-/home/josh/gamedev/volley/ai/scratchpads/memory-bucketing-proposed.md}"
    declare -A TRUNK_OF
    if [[ -f "$BRIDGE" ]]; then
        cur=""
        while IFS= read -r line; do
            if [[ "$line" =~ ^##\ ([a-z-]+) ]]; then cur="${BASH_REMATCH[1]}"
            elif [[ "$line" =~ ^-\ ([A-Za-z0-9_]+) ]]; then TRUNK_OF["${BASH_REMATCH[1]}"]="$cur"; fi
        done < "$BRIDGE"
    fi
    echo
    echo "# bridge: unordered nodes grouped under their proposed trunk"
    for trunk in dev-cycle who-i-am docs volley shuck UNBUCKETED; do
        first=1
        for node in $(printf '%s\n' "${!IS_NODE[@]}" | sort); do
            is_root "$node" && ! has_children "$node" || continue
            t="${TRUNK_OF[$node]:-UNBUCKETED}"
            [[ "$t" == "$trunk" ]] || continue
            if [[ $first == 1 ]]; then echo; echo "## $trunk"; first=0; fi
            printf -- '- %s\n' "$node"
            unordered=$((unordered + 1))
        done
    done
    echo "--- $typed_roots ordered trees, $unordered unordered nodes across the trunks ---"
fi

echo "lint-graph-edges: $dangling dangling, $orphans root/untyped nodes"

if [[ "$dangling" -gt 0 ]]; then
    exit 1
fi
