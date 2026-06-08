#!/usr/bin/env bash
# Emits MEMORY.md's CROWN: the five trunk roots plus their ordered children
# and provisional bridge nodes.
#
# A trunk is any .md file whose frontmatter contains node_type: trunk.
# Plain parentless nodes are NOT trunks and do NOT appear in the crown.
#
# Output structure for each trunk:
#   <slug>  <gist>
#     ordered children (nodes whose parent: == trunk slug):
#       - <child-slug>  <child-gist>
#     provisional (bridge nodes bucketed to this trunk but not yet typed):
#       provisional:
#       - <bridge-slug>
#
# Cap: total output must stay under --budget chars (default 10000).
# Exits 2 with a truncation notice on stderr when the cap would be exceeded.
#
# Usage:
#   generate-roots.sh [MEMORY_DIR] [--budget N] [--bridge PATH]
#
# MEMORY_DIR defaults to ~/.claude/projects/-home-josh-gamedev-volley/memory
# --bridge defaults to /home/josh/gamedev/volley/ai/scratchpads/memory-bucketing-proposed.md
# parent: may sit at the top level of frontmatter or nested (any indent); both are read.

set -euo pipefail

MEMORY_DIR=""
BUDGET=10000
BRIDGE_MAP=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --budget)
            BUDGET="$2"
            shift 2
            ;;
        --bridge)
            BRIDGE_MAP="$2"
            shift 2
            ;;
        *)
            if [[ -z "$MEMORY_DIR" ]]; then
                MEMORY_DIR="$1"
            fi
            shift
            ;;
    esac
done

MEMORY_DIR="${MEMORY_DIR:-$HOME/.claude/projects/-home-josh-gamedev-volley/memory}"
BRIDGE_MAP="${BRIDGE_MAP:-/home/josh/gamedev/volley/ai/scratchpads/memory-bucketing-proposed.md}"

if [[ ! -d "$MEMORY_DIR" ]]; then
    echo "generate-roots: memory dir not found: $MEMORY_DIR" >&2
    exit 1
fi

# Read a frontmatter field (top-level or indented under metadata:).
read_field() {
    local filepath="$1"
    local field="$2"
    awk -v field="$field" '
        /^---[[:space:]]*$/ { fence++; next }
        fence == 1 && /^[[:space:]]*node_type:[[:space:]]*/ && field == "node_type" {
            sub(/^[[:space:]]*node_type:[[:space:]]*/, "")
            gsub(/^"/, ""); gsub(/"$/, "")
            print; exit
        }
        fence == 1 && /^[[:space:]]*parent:[[:space:]]*/ && field == "parent" {
            sub(/^[[:space:]]*parent:[[:space:]]*/, "")
            gsub(/^"/, ""); gsub(/"$/, "")
            print; exit
        }
        fence == 1 && /^[[:space:]]*slug:[[:space:]]*/ && field == "slug" {
            sub(/^[[:space:]]*slug:[[:space:]]*/, "")
            gsub(/^"/, ""); gsub(/"$/, "")
            print; exit
        }
        fence == 1 && /^[[:space:]]*description:[[:space:]]*/ && field == "description" {
            sub(/^[[:space:]]*description:[[:space:]]*/, "")
            gsub(/^"/, ""); gsub(/"$/, "")
            print; exit
        }
        fence == 1 && /^[[:space:]]*summary:[[:space:]]*/ && field == "summary" {
            sub(/^[[:space:]]*summary:[[:space:]]*/, "")
            gsub(/^"/, ""); gsub(/"$/, "")
            print; exit
        }
        fence >= 2 { exit }
    ' "$filepath"
}

# First prose line after the frontmatter: not blank, not a heading.
read_prose_gist() {
    awk '
        /^---[[:space:]]*$/ { fence++; next }
        fence < 2 { next }
        /^[[:space:]]*$/ { next }
        /^#/ { next }
        { print; exit }
    ' "$1"
}

derive_gist() {
    local filepath="$1"
    local gist

    gist="$(read_field "$filepath" "description")"

    if [[ -z "$gist" ]]; then
        gist="$(read_field "$filepath" "summary")"
    fi

    if [[ -z "$gist" ]]; then
        gist="$(read_prose_gist "$filepath")"
    fi

    gist="${gist:0:120}"
    gist="${gist%"${gist##*[! ]}"}"
    printf '%s' "$gist"
}

# Walk the corpus once: collect trunks, parent edges, and all known slugs.
declare -A NODE_FILE
declare -A PARENT_OF
declare -A IS_TRUNK
# trunk_filename_slug -> bridge_slug (from slug: frontmatter field)
declare -A TRUNK_BRIDGE_SLUG

while IFS= read -r -d '' filepath; do
    slug="$(basename "$filepath" .md)"
    NODE_FILE["$slug"]="$filepath"

    node_type="$(read_field "$filepath" "node_type")"
    if [[ "$node_type" == "trunk" ]]; then
        IS_TRUNK["$slug"]=1
        bridge_slug="$(read_field "$filepath" "slug")"
        if [[ -n "$bridge_slug" ]]; then
            TRUNK_BRIDGE_SLUG["$slug"]="$bridge_slug"
        fi
    fi

    parent="$(read_field "$filepath" "parent")"
    if [[ -n "$parent" ]]; then
        PARENT_OF["$slug"]="$parent"
    fi
done < <(find "$MEMORY_DIR" -name "*.md" -print0 | sort -z)

# Build the trunk list sorted by filename slug.
trunks=()
for slug in $(printf '%s\n' "${!IS_TRUNK[@]}" | sort); do
    trunks+=("$slug")
done

# Load the bridge map: trunk slug -> list of node slugs.
declare -A BRIDGE_NODES
if [[ -f "$BRIDGE_MAP" ]]; then
    cur_trunk=""
    while IFS= read -r line; do
        if [[ "$line" =~ ^##[[:space:]]+([a-zA-Z0-9_-]+) ]]; then
            cur_trunk="${BASH_REMATCH[1]}"
        elif [[ "$line" =~ ^-[[:space:]]+([A-Za-z0-9_/-]+) && -n "$cur_trunk" ]]; then
            node="${BASH_REMATCH[1]}"
            BRIDGE_NODES["${cur_trunk}:${node}"]="$node"
        fi
    done < "$BRIDGE_MAP"
fi

# Assemble output in a buffer, enforcing the char budget.
output_buf=""
truncated=0

append_line() {
    local line="$1"
    local len=$(( ${#line} + 1 ))
    if (( ${#output_buf} + len > BUDGET )); then
        truncated=1
        return 1
    fi
    output_buf+="${line}"$'\n'
}

for trunk_slug in "${trunks[@]}"; do
    trunk_file="${NODE_FILE[$trunk_slug]:-}"
    if [[ -z "$trunk_file" ]]; then
        continue
    fi

    trunk_gist="$(derive_gist "$trunk_file")"
    if ! append_line "${trunk_slug}  ${trunk_gist}"; then
        break
    fi

    # Ordered children: nodes whose parent is this trunk slug.
    for child_slug in $(printf '%s\n' "${!PARENT_OF[@]}" | sort); do
        if [[ "${PARENT_OF[$child_slug]}" == "$trunk_slug" ]]; then
            child_file="${NODE_FILE[$child_slug]:-}"
            child_gist=""
            if [[ -n "$child_file" ]]; then
                child_gist="$(derive_gist "$child_file")"
            fi
            if ! append_line "  - ${child_slug}  ${child_gist}"; then
                truncated=1
                break
            fi
        fi
    done

    [[ "$truncated" -eq 1 ]] && break

    # Provisional bridge nodes bucketed to this trunk but not yet typed.
    # Bridge map uses the trunk's slug: field, not its filename slug.
    bridge_key="${TRUNK_BRIDGE_SLUG[$trunk_slug]:-$trunk_slug}"
    provisional_lines=()
    for key in $(printf '%s\n' "${!BRIDGE_NODES[@]}" | grep "^${bridge_key}:" | sort); do
        node="${BRIDGE_NODES[$key]}"
        # Skip if already a typed child of this trunk.
        [[ "${PARENT_OF[$node]:-}" == "$trunk_slug" ]] && continue
        provisional_lines+=("  - ${node}")
    done

    if [[ "${#provisional_lines[@]}" -gt 0 ]]; then
        if ! append_line "  provisional:"; then
            truncated=1
            break
        fi
        for pline in "${provisional_lines[@]}"; do
            if ! append_line "$pline"; then
                truncated=1
                break
            fi
        done
        [[ "$truncated" -eq 1 ]] && break
    fi
done

printf '%s' "$output_buf"

if [[ "$truncated" -eq 1 ]]; then
    echo "generate-roots: crown truncated; output exceeded $BUDGET chars" >&2
    echo "[truncated: crown exceeded budget of $BUDGET chars]" >&2
    exit 2
fi

echo "generate-roots: ${#trunks[@]} trunks emitted" >&2
