#!/usr/bin/env bash
# Tests for lint-graph-edges.sh.
# Creates temporary fixture directories and asserts exit codes + output.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LINT="$SCRIPT_DIR/lint-graph-edges.sh"

pass=0
fail=0

assert_exit() {
    local description="$1"
    local expected_exit="$2"
    shift 2
    local actual_exit=0
    "$@" >/dev/null 2>&1 || actual_exit=$?
    if [[ "$actual_exit" -eq "$expected_exit" ]]; then
        echo "PASS: $description"
        pass=$((pass + 1))
    else
        echo "FAIL: $description (expected exit $expected_exit, got $actual_exit)"
        fail=$((fail + 1))
    fi
}

assert_output_contains() {
    local description="$1"
    local expected_substring="$2"
    shift 2
    local output
    output=$("$@" 2>&1 || true)
    if echo "$output" | grep -qF "$expected_substring"; then
        echo "PASS: $description"
        pass=$((pass + 1))
    else
        echo "FAIL: $description (expected substring '$expected_substring' not found in output)"
        echo "  actual output: $output"
        fail=$((fail + 1))
    fi
}

# --- fixture helpers ---

make_node() {
    local dir="$1"
    local slug="$2"
    local parent="${3:-}"
    local file="$dir/${slug}.md"
    mkdir -p "$(dirname "$file")"

    if [[ -n "$parent" ]]; then
        printf -- '---\nparent: %s\n---\nBody.\n' "$parent" > "$file"
    else
        printf -- '---\n---\nBody.\n' > "$file"
    fi
}

# --- test 1: all parents resolve ---

DIR1=$(mktemp -d)
trap 'rm -rf "$DIR1"' EXIT

make_node "$DIR1" "root-principle"
make_node "$DIR1" "child-rule" "root-principle"
make_node "$DIR1" "another-root"

assert_exit "all parents resolve: exits 0" 0 "$LINT" "$DIR1"
assert_output_contains "all parents resolve: reports 1 dangling=0" "0 dangling" "$LINT" "$DIR1"

# --- test 2: dangling parent exits non-zero ---

DIR2=$(mktemp -d)
trap 'rm -rf "$DIR1" "$DIR2"' EXIT

make_node "$DIR2" "orphaned-child" "nonexistent-parent"

assert_exit "dangling parent: exits non-zero" 1 "$LINT" "$DIR2"
assert_output_contains "dangling parent: reports the slug" "nonexistent-parent" "$LINT" "$DIR2"

# --- test 3: no parent is valid (root node) ---

DIR3=$(mktemp -d)
trap 'rm -rf "$DIR1" "$DIR2" "$DIR3"' EXIT

make_node "$DIR3" "standalone-root"
make_node "$DIR3" "another-standalone"

assert_exit "no parent is root: exits 0" 0 "$LINT" "$DIR3"

# --- test 4: dangling parent in a subdir exits non-zero ---

DIR4=$(mktemp -d)
trap 'rm -rf "$DIR1" "$DIR2" "$DIR3" "$DIR4"' EXIT

make_node "$DIR4" "letters/2026-06-07-slug" "nonexistent-root"

assert_exit "subdir dangling parent: exits non-zero" 1 "$LINT" "$DIR4"
assert_output_contains "subdir dangling parent: reports the slug" "nonexistent-root" "$LINT" "$DIR4"

# --- summary ---

echo ""
echo "Results: $pass passed, $fail failed"
[[ "$fail" -eq 0 ]]
