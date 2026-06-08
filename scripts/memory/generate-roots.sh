#!/usr/bin/env bash
# Emits MEMORY.md's CROWN: one line per trunk root, slug + gist.
#
# A trunk is any .md file whose basename starts with `trunk_`.
# Plain parentless nodes are NOT trunks and do NOT appear in the crown.
#
# Output (one line per trunk, sorted by filename slug):
#   <slug>  <gist>
#
# Cap: total output must stay under --budget chars (default 10000).
# Exits 2 with a truncation notice on stderr when the cap would be exceeded.
#
# Usage:
#   generate-roots.sh [MEMORY_DIR] [--budget N]
#
# MEMORY_DIR defaults to ~/.claude/projects/-home-josh-gamedev-volley/memory

set -euo pipefail

MEMORY_DIR=""
BUDGET=10000

while [[ $# -gt 0 ]]; do
    case "$1" in
        --budget)
            if [[ ! "$2" =~ ^[0-9]+$ ]]; then
                echo "generate-roots: --budget must be a positive integer, got: $2" >&2
                exit 1
            fi
            BUDGET="$2"
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

# Walk the corpus once: collect trunks.
declare -A NODE_FILE
declare -A IS_TRUNK

while IFS= read -r -d '' filepath; do
    slug="$(basename "$filepath" .md)"
    NODE_FILE["$slug"]="$filepath"

    if [[ "$slug" == trunk_* ]]; then
        IS_TRUNK["$slug"]=1
    fi
done < <(find "$MEMORY_DIR" -maxdepth 1 -name "*.md" -print0 | sort -z)

# Build the trunk list sorted by filename slug.
trunks=()
for slug in $(printf '%s\n' "${!IS_TRUNK[@]}" | sort); do
    trunks+=("$slug")
done

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
done

printf '%s' "$output_buf"

if [[ "$truncated" -eq 1 ]]; then
    echo "generate-roots: crown truncated; output exceeded $BUDGET chars" >&2
    echo "[truncated: crown exceeded budget of $BUDGET chars]" >&2
    exit 2
fi

echo "generate-roots: ${#trunks[@]} trunks emitted" >&2
