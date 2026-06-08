#!/usr/bin/env bash
# Tests for generate-roots.sh.
# Creates temporary fixture directories and asserts exit codes + output.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GEN="$SCRIPT_DIR/generate-roots.sh"

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

# --- fixture helpers ---

make_trunk() {
    local dir="$1"
    local slug="$2"
    local gist="${3:-gist for $slug}"
    cat > "$dir/${slug}.md" <<EOF
---
node_type: trunk
slug: $slug
---
$gist
EOF
}

make_trunk_with_node_type() {
    local dir="$1"
    local slug="$2"
    local node_type="$3"
    local gist="${4:-gist for $slug}"
    cat > "$dir/${slug}.md" <<EOF
---
node_type: $node_type
slug: $slug
---
$gist
EOF
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

# --- test 1: crown lists only trunks, not plain parentless nodes ---

DIR1=$(mktemp -d)
trap 'rm -rf "$DIR1"' EXIT

make_trunk "$DIR1" "trunk_alpha" "alpha trunk gist"
make_trunk "$DIR1" "trunk_beta" "beta trunk gist"
make_node "$DIR1" "plain-root" "" "a plain parentless node"
make_node "$DIR1" "child-node" "trunk_alpha" "a typed child"

assert_output_contains "crown: trunk_alpha listed" "trunk_alpha" "$GEN" "$DIR1"
assert_output_contains "crown: trunk_beta listed" "trunk_beta" "$GEN" "$DIR1"
assert_output_not_contains "crown: plain parentless node excluded" "plain-root" "$GEN" "$DIR1"

# --- test 2: exactly five trunks produce exactly five trunk header lines ---

DIR2=$(mktemp -d)
trap 'rm -rf "$DIR1" "$DIR2"' EXIT

make_trunk "$DIR2" "trunk_one" "one"
make_trunk "$DIR2" "trunk_two" "two"
make_trunk "$DIR2" "trunk_three" "three"
make_trunk "$DIR2" "trunk_four" "four"
make_trunk "$DIR2" "trunk_five" "five"
make_node "$DIR2" "non-trunk-a" "" "not a trunk"
make_node "$DIR2" "non-trunk-b" "trunk_one" "typed child"

crown_count=$("$GEN" "$DIR2" 2>/dev/null | grep -c "^trunk_" || true)
if [[ "$crown_count" -eq 5 ]]; then
    echo "PASS: crown count: exactly 5 trunk headers"
    pass=$((pass + 1))
else
    echo "FAIL: crown count: expected 5 trunk headers, got $crown_count"
    fail=$((fail + 1))
fi

# --- test 3: cap guard fires, exits 2, emits truncation notice ---

DIR3=$(mktemp -d)
trap 'rm -rf "$DIR1" "$DIR2" "$DIR3"' EXIT

for i in $(seq 1 5); do
    make_trunk "$DIR3" "trunk_$(printf '%02d' "$i")" "gist number $i is here and takes space in the output buffer"
done

assert_exit "cap guard: exits 2 when budget exceeded" 2 "$GEN" "$DIR3" --budget 50

cap_output=$("$GEN" "$DIR3" --budget 50 2>&1 || true)
if echo "$cap_output" | grep -qF "truncated"; then
    echo "PASS: cap guard: truncation notice emitted"
    pass=$((pass + 1))
else
    echo "FAIL: cap guard: no truncation notice"
    echo "  output: $cap_output"
    fail=$((fail + 1))
fi

# --- test 4: gist from first prose line of trunk ---

DIR4=$(mktemp -d)
trap 'rm -rf "$DIR1" "$DIR2" "$DIR3" "$DIR4"' EXIT

cat > "$DIR4/trunk_prose.md" <<'EOF'
---
node_type: trunk
slug: trunk_prose
---
The prose gist for this trunk.
EOF

output=$("$GEN" "$DIR4" 2>/dev/null)
if echo "$output" | grep -qF "The prose gist for this trunk."; then
    echo "PASS: gist: first prose line used"
    pass=$((pass + 1))
else
    echo "FAIL: gist: first prose line not used"
    echo "  output: $output"
    fail=$((fail + 1))
fi

# --- test 4b: gist from description: frontmatter field, ignoring prose ---

DIR4B=$(mktemp -d)
trap 'rm -rf "$DIR1" "$DIR2" "$DIR3" "$DIR4" "$DIR4B"' EXIT

cat > "$DIR4B/trunk_desc.md" <<'EOF'
---
node_type: trunk
slug: trunk_desc
description: Description field gist.
---
Prose that must not appear in the crown.
EOF

output=$("$GEN" "$DIR4B" 2>/dev/null)
if echo "$output" | grep -qF "Description field gist."; then
    echo "PASS: gist: description: field used when present"
    pass=$((pass + 1))
else
    echo "FAIL: gist: description: field not used"
    echo "  output: $output"
    fail=$((fail + 1))
fi

if echo "$output" | grep -qF "Prose that must not appear in the crown."; then
    echo "FAIL: gist: prose leaked into crown despite description: field"
    echo "  output: $output"
    fail=$((fail + 1))
else
    echo "PASS: gist: prose suppressed when description: field present"
    pass=$((pass + 1))
fi

# --- test 4c: gist from summary: frontmatter field when no description: ---

DIR4C=$(mktemp -d)
trap 'rm -rf "$DIR1" "$DIR2" "$DIR3" "$DIR4" "$DIR4B" "$DIR4C"' EXIT

cat > "$DIR4C/trunk_summ.md" <<'EOF'
---
node_type: trunk
slug: trunk_summ
summary: Summary field gist.
---
EOF

output=$("$GEN" "$DIR4C" 2>/dev/null)
if echo "$output" | grep -qF "Summary field gist."; then
    echo "PASS: gist: summary: field used when no description:"
    pass=$((pass + 1))
else
    echo "FAIL: gist: summary: field not used"
    echo "  output: $output"
    fail=$((fail + 1))
fi

# --- test 4d: subdirectory trunk_ files are NOT crowned (maxdepth 1) ---

DIR4D=$(mktemp -d)
trap 'rm -rf "$DIR1" "$DIR2" "$DIR3" "$DIR4" "$DIR4B" "$DIR4C" "$DIR4D"' EXIT

make_trunk "$DIR4D" "trunk_top" "top-level trunk gist"
mkdir -p "$DIR4D/letters"
cat > "$DIR4D/letters/trunk_nested.md" <<'EOF'
---
node_type: trunk
slug: trunk_nested
---
This trunk is nested and must not appear in the crown.
EOF

assert_output_contains "maxdepth: top-level trunk is crowned" "trunk_top" "$GEN" "$DIR4D"
assert_output_not_contains "maxdepth: nested trunk_ excluded" "trunk_nested" "$GEN" "$DIR4D"

# --- test 4e: non-integer --budget exits 1 with a clear message ---

DIR4E=$(mktemp -d)
trap 'rm -rf "$DIR1" "$DIR2" "$DIR3" "$DIR4" "$DIR4B" "$DIR4C" "$DIR4D" "$DIR4E"' EXIT

make_trunk "$DIR4E" "trunk_aa" "short"

assert_exit "budget-validate: non-integer --budget exits 1" 1 "$GEN" "$DIR4E" --budget abc

budget_err=$("$GEN" "$DIR4E" --budget xyz 2>&1 || true)
if echo "$budget_err" | grep -qF "must be a positive integer"; then
    echo "PASS: budget-validate: clear error message on non-integer --budget"
    pass=$((pass + 1))
else
    echo "FAIL: budget-validate: expected clear error message, got: $budget_err"
    fail=$((fail + 1))
fi

# --- test 5: exits 0 when all trunks fit in budget ---

DIR5=$(mktemp -d)
trap 'rm -rf "$DIR1" "$DIR2" "$DIR3" "$DIR4" "$DIR4B" "$DIR4C" "$DIR4D" "$DIR4E" "$DIR5"' EXIT

make_trunk "$DIR5" "trunk_aa" "short"
make_trunk "$DIR5" "trunk_bb" "short"

assert_exit "no truncation: exits 0 when under budget" 0 "$GEN" "$DIR5" --budget 10000

# --- test 6: trunk_ filename with node_type: memory is still treated as a trunk ---
# Normalizer-survival: the harness rewrites node_type to "memory" on any edit,
# so detection must not rely on frontmatter node_type.

DIR6=$(mktemp -d)
trap 'rm -rf "$DIR1" "$DIR2" "$DIR3" "$DIR4" "$DIR4B" "$DIR4C" "$DIR4D" "$DIR4E" "$DIR5" "$DIR6"' EXIT

make_trunk_with_node_type "$DIR6" "trunk_normalizer" "memory" "normalizer-safe trunk gist"
make_node "$DIR6" "plain-node" "" "should not appear"

assert_output_contains "normalizer-survival: trunk_ with node_type:memory is in crown" "trunk_normalizer" "$GEN" "$DIR6"
assert_output_not_contains "normalizer-survival: plain node excluded" "plain-node" "$GEN" "$DIR6"

# --- summary ---

echo ""
echo "Results: $pass passed, $fail failed"
[[ "$fail" -eq 0 ]]
