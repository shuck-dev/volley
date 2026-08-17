#!/usr/bin/env bash
# Fails non-zero when any staged (or diff-listed) binary file exceeds the
# threshold. Called by the lefthook pre-commit command and the CI workflow.
#
# Usage:
#   Pre-commit mode (no args): checks files staged in the git index.
#   CI mode (--diff BASE):     checks files added/modified vs BASE commit.

set -euo pipefail

THRESHOLD_KB=500
THRESHOLD_BYTES=$(( THRESHOLD_KB * 1024 ))

mode="staged"
base_ref=""

if [[ "${1:-}" == "--diff" ]]; then
    mode="diff"
    base_ref="${2:?'--diff requires a base ref'}"
fi

get_files() {
    if [[ "$mode" == "staged" ]]; then
        git diff --cached --name-only --diff-filter=d
    else
        git diff --name-only --diff-filter=d "${base_ref}...HEAD"
    fi
}

is_lfs_pointer() {
    local file="$1"
    local blob_ref first_line
    if [[ "$mode" == "staged" ]]; then
        blob_ref=":${file}"
    else
        blob_ref="HEAD:${file}"
    fi
    first_line=$(git show "${blob_ref}" 2>/dev/null | head -1 || true)
    [[ "$first_line" == "version https://git-lfs.github.com/spec/v1" ]]
}

get_size() {
    local file="$1"
    if [[ "$mode" == "staged" ]]; then
        git cat-file -s ":${file}" 2>/dev/null || printf 0
    else
        git cat-file -s "HEAD:${file}" 2>/dev/null || printf 0
    fi
}

failed=0

while IFS= read -r file; do
    [[ -z "$file" ]] && continue

    case "$file" in
        *.import)  continue ;;
        addons/*)  continue ;;
    esac

    if is_lfs_pointer "$file"; then
        continue
    fi

    size=$(get_size "$file")

    if (( size > THRESHOLD_BYTES )); then
        size_kb=$(( size / 1024 ))
        printf 'error: %s is %dKB, exceeds %dKB limit\n' "$file" "$size_kb" "$THRESHOLD_KB" >&2
        failed=1
    fi
done < <(get_files)

if (( failed )); then
    printf '\nLarge binaries must be tracked via Git LFS, not committed directly.\n' >&2
    printf 'Run: git lfs track <pattern>\n' >&2
    exit 1
fi
