#!/usr/bin/env bash
# Tests for generate-index.sh and the topic-exempt path in memory-file-char-cap.sh.
# Creates temporary fixture directories and asserts exit codes + output.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GEN="$SCRIPT_DIR/generate-index.sh"
HOOK="$(dirname "$SCRIPT_DIR")/../.claude/hooks/memory-file-char-cap.sh"
HOOK="$(cd "$(dirname "$SCRIPT_DIR")" && cd .. && pwd)/.claude/hooks/memory-file-char-cap.sh"

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
        echo "FAIL: $description (expected '$expected_substring' not found)"
        echo "  actual output: $output"
        fail=$((fail + 1))
    fi
}

assert_output_not_contains() {
    local description="$1"
    local absent_substring="$2"
    shift 2
    local output
    output=$("$@" 2>&1 || true)
    if echo "$output" | grep -qF "$absent_substring"; then
        echo "FAIL: $description (unexpected '$absent_substring' found)"
        echo "  actual output: $output"
        fail=$((fail + 1))
    else
        echo "PASS: $description"
        pass=$((pass + 1))
    fi
}

assert_stdout_contains() {
    local description="$1"
    local expected_substring="$2"
    shift 2
    local output
    output=$("$@" 2>/dev/null || true)
    if echo "$output" | grep -qF "$expected_substring"; then
        echo "PASS: $description"
        pass=$((pass + 1))
    else
        echo "FAIL: $description (expected '$expected_substring' not found in stdout)"
        echo "  actual stdout: $output"
        fail=$((fail + 1))
    fi
}

assert_stdout_not_contains() {
    local description="$1"
    local absent_substring="$2"
    shift 2
    local output
    output=$("$@" 2>/dev/null || true)
    if echo "$output" | grep -qF "$absent_substring"; then
        echo "FAIL: $description (unexpected '$absent_substring' found in stdout)"
        echo "  actual stdout: $output"
        fail=$((fail + 1))
    else
        echo "PASS: $description"
        pass=$((pass + 1))
    fi
}

make_node() {
    local dir="$1"
    local slug="$2"
    local parent="${3:-}"
    local description="${4:-}"
    local file="$dir/${slug}.md"
    mkdir -p "$(dirname "$file")"

    {
        printf -- '---\n'
        [[ -n "$parent" ]] && printf 'parent: %s\n' "$parent"
        [[ -n "$description" ]] && printf 'description: %s\n' "$description"
        printf -- '---\n'
        printf 'Body text for %s.\n' "$slug"
    } > "$file"
}

# --- test 1: topic with children emits description and child list ---

DIR1=$(mktemp -d)
trap 'rm -rf "$DIR1"' EXIT

make_node "$DIR1" "my-topic" "" "The topic description."
make_node "$DIR1" "child-alpha" "my-topic" "Alpha child gist."
make_node "$DIR1" "child-beta" "my-topic" "Beta child gist."

assert_stdout_contains "topic: description in output" "The topic description." "$GEN" "my-topic" "$DIR1"
assert_stdout_contains "topic: child-alpha listed" "child-alpha" "$GEN" "my-topic" "$DIR1"
assert_stdout_contains "topic: child-beta listed" "child-beta" "$GEN" "my-topic" "$DIR1"
assert_stdout_contains "topic: child-alpha gist" "Alpha child gist." "$GEN" "my-topic" "$DIR1"
assert_stdout_contains "topic: child-beta gist" "Beta child gist." "$GEN" "my-topic" "$DIR1"
assert_stdout_contains "topic: children header present" "Children:" "$GEN" "my-topic" "$DIR1"

# --- test 2: leaf node exits 0 and produces no stdout ---

DIR2=$(mktemp -d)
trap 'rm -rf "$DIR1" "$DIR2"' EXIT

make_node "$DIR2" "leaf-node" "" "A standalone leaf."

assert_exit "leaf: exits 0 (skip, not error)" 0 "$GEN" "leaf-node" "$DIR2"

leaf_stdout=$("$GEN" "leaf-node" "$DIR2" 2>/dev/null || true)
if [[ -z "$leaf_stdout" ]]; then
    echo "PASS: leaf: no stdout emitted"
    pass=$((pass + 1))
else
    echo "FAIL: leaf: unexpected stdout: $leaf_stdout"
    fail=$((fail + 1))
fi

# --- test 3: missing slug exits non-zero ---

DIR3=$(mktemp -d)
trap 'rm -rf "$DIR1" "$DIR2" "$DIR3"' EXIT

make_node "$DIR3" "exists" "" ""

assert_exit "missing-slug: non-zero exit" 1 "$GEN" "no-such-slug" "$DIR3"

# --- test 4: no arguments exits 1 with usage message ---

DIR4=$(mktemp -d)
trap 'rm -rf "$DIR1" "$DIR2" "$DIR3" "$DIR4"' EXIT

assert_exit "no-args: exits 1" 1 "$GEN"
assert_output_contains "no-args: usage in stderr" "usage" "$GEN"

# --- test 5: only direct children listed, not grandchildren ---

DIR5=$(mktemp -d)
trap 'rm -rf "$DIR1" "$DIR2" "$DIR3" "$DIR4" "$DIR5"' EXIT

make_node "$DIR5" "root-topic" "" "Root topic."
make_node "$DIR5" "mid-child" "root-topic" "Mid-level child."
make_node "$DIR5" "grandchild" "mid-child" "Grandchild gist."

assert_stdout_contains "depth: direct child listed" "mid-child" "$GEN" "root-topic" "$DIR5"
assert_stdout_not_contains "depth: grandchild not listed" "grandchild" "$GEN" "root-topic" "$DIR5"

# --- test 6: child gist falls back to first prose line when no description: ---

DIR6=$(mktemp -d)
trap 'rm -rf "$DIR1" "$DIR2" "$DIR3" "$DIR4" "$DIR5" "$DIR6"' EXIT

cat > "$DIR6/prose-parent.md" <<'EOF'
---
description: The parent.
---
Parent body.
EOF

cat > "$DIR6/prose-child.md" <<'EOF'
---
parent: prose-parent
---
First prose line of child.
EOF

assert_stdout_contains "prose-gist: first prose line used" "First prose line of child." "$GEN" "prose-parent" "$DIR6"

# --- test 7: char-cap hook exempts topic nodes ---
# Requires the hook to support MEMDIR_OVERRIDE (the topic-exempt update).
# Skips when the hook is not present or not yet updated.

hook_has_override=0
if [[ -f "$HOOK" ]] && grep -qF "MEMDIR_OVERRIDE" "$HOOK" 2>/dev/null; then
    hook_has_override=1
fi

if [[ "$hook_has_override" -eq 0 ]]; then
    echo "SKIP: char-cap topic-exempt tests require hook update (MEMDIR_OVERRIDE not present)"
else
    DIR7=$(mktemp -d)
    trap 'rm -rf "$DIR1" "$DIR2" "$DIR3" "$DIR4" "$DIR5" "$DIR6" "$DIR7"' EXIT

    make_node "$DIR7" "big-topic" "" "A topic with many children."
    make_node "$DIR7" "child-one" "big-topic" "Child one."
    make_node "$DIR7" "child-two" "big-topic" "Child two."

    long_content=""
    for i in $(seq 1 50); do
        long_content+="This is a line of content to push past 2000 chars. Line $i of the content.\n"
    done
    BIG_CONTENT=$(printf '%b' "$long_content")

    payload_topic=$(python3 -c "
import json, sys
path = '${DIR7}/big-topic.md'
content = sys.stdin.read()
print(json.dumps({'tool_name': 'Write', 'tool_input': {'file_path': path, 'content': content}}))
" <<< "$BIG_CONTENT")

    hook_result_topic=$(printf '%s' "$payload_topic" | MEMDIR_OVERRIDE="$DIR7" bash "$HOOK" 2>/dev/null || true)

    if echo "$hook_result_topic" | grep -qF "deny"; then
        echo "FAIL: char-cap: topic node was denied (should be exempt)"
        fail=$((fail + 1))
    else
        echo "PASS: char-cap: topic node is exempt from cap"
        pass=$((pass + 1))
    fi

    payload_leaf=$(python3 -c "
import json, sys
path = '${DIR7}/child-one.md'
content = sys.stdin.read()
print(json.dumps({'tool_name': 'Write', 'tool_input': {'file_path': path, 'content': content}}))
" <<< "$BIG_CONTENT")

    hook_result_leaf=$(printf '%s' "$payload_leaf" | MEMDIR_OVERRIDE="$DIR7" bash "$HOOK" 2>/dev/null || true)

    if echo "$hook_result_leaf" | grep -qF "deny"; then
        echo "PASS: char-cap: leaf node is capped"
        pass=$((pass + 1))
    else
        echo "FAIL: char-cap: leaf node was not denied when over cap"
        fail=$((fail + 1))
    fi
fi

# --- summary ---

echo ""
echo "Results: $pass passed, $fail failed"
[[ "$fail" -eq 0 ]]
