#!/usr/bin/env bash
# Given ONE topic node slug, emits its index body: a description line then each
# direct child with a one-line gist, derived from the parent: edges that name it.
#
# A topic is any node that has at least one child (another node whose parent:
# frontmatter names this slug). Leaves have no children and are not touched.
#
# Output (written to stdout):
#   <description of the topic node>
#
#   Children:
#   - <child-slug>: <gist>
#   ...
#
# Usage:
#   generate-index.sh <slug> [MEMORY_DIR]
#
# MEMORY_DIR defaults to ~/.claude/projects/-home-josh-gamedev-volley/memory

set -euo pipefail

MEMORY_DIR=""
SLUG=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        -*)
            echo "generate-index: unknown flag: $1" >&2
            exit 1
            ;;
        *)
            if [[ -z "$SLUG" ]]; then
                SLUG="$1"
            elif [[ -z "$MEMORY_DIR" ]]; then
                MEMORY_DIR="$1"
            fi
            shift
            ;;
    esac
done

if [[ -z "$SLUG" ]]; then
    echo "generate-index: usage: generate-index.sh <slug> [MEMORY_DIR]" >&2
    exit 1
fi

MEMORY_DIR="${MEMORY_DIR:-$HOME/.claude/projects/-home-josh-gamedev-volley/memory}"

if [[ ! -d "$MEMORY_DIR" ]]; then
    echo "generate-index: memory dir not found: $MEMORY_DIR" >&2
    exit 1
fi

TOPIC_FILE="$MEMORY_DIR/${SLUG}.md"
if [[ ! -f "$TOPIC_FILE" ]]; then
    echo "generate-index: node not found: $TOPIC_FILE" >&2
    exit 1
fi

read_field() {
    local filepath="$1"
    local field="$2"
    awk -v field="$field" '
        /^---[[:space:]]*$/ { fence++; next }
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

read_prose_gist() {
    # the first prose line, with markdown stripped so the gist reads clean
    awk '
        /^---[[:space:]]*$/ { fence++; next }
        fence < 2 { next }
        /^[[:space:]]*$/ { next }
        /^#/ { next }
        {
            gsub(/\*\*/, "")       # bold markers
            gsub(/`/, "")          # inline code
            sub(/^[[:space:]]*([-*>]|[0-9]+\.)[[:space:]]+/, "")  # list/quote marker
            print; exit
        }
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

read_parent() {
    awk '
        /^---[[:space:]]*$/ { fence++; next }
        fence == 1 && /^[[:space:]]*parent:[[:space:]]*/ {
            sub(/^[[:space:]]*parent:[[:space:]]*/, ""); print; exit
        }
        fence >= 2 { exit }
    ' "$1"
}

# Collect direct children: files whose parent: field equals SLUG.
declare -a CHILDREN=()
while IFS= read -r -d '' filepath; do
    child_slug="$(basename "$filepath" .md)"
    [[ "$child_slug" == "$SLUG" ]] && continue
    parent_val="$(read_parent "$filepath")"
    if [[ "$parent_val" == "$SLUG" ]]; then
        CHILDREN+=("$child_slug")
    fi
done < <(find "$MEMORY_DIR" -name "*.md" -print0 | sort -z)

child_count="${#CHILDREN[@]}"

if [[ "$child_count" -eq 0 ]]; then
    echo "generate-index: $SLUG is a leaf (no children); skipping" >&2
    exit 0
fi

topic_gist="$(derive_gist "$TOPIC_FILE")"
printf '%s\n' "$topic_gist"
printf '\n'
printf 'Children:\n'

for child_slug in "${CHILDREN[@]}"; do
    child_file="$MEMORY_DIR/${child_slug}.md"
    child_gist=""
    if [[ -f "$child_file" ]]; then
        child_gist="$(derive_gist "$child_file")"
    fi
    printf -- '- %s: %s\n' "$child_slug" "$child_gist"
done

echo "generate-index: $child_count children listed for $SLUG" >&2
