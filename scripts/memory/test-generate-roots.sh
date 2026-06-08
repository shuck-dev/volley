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

make_trunk "$DIR1" "trunk-alpha" "alpha trunk gist"
make_trunk "$DIR1" "trunk-beta" "beta trunk gist"
make_node "$DIR1" "plain-root" "" "a plain parentless node"
make_node "$DIR1" "child-node" "trunk-alpha" "a typed child"

assert_output_contains "crown: trunk-alpha listed" "trunk-alpha" "$GEN" "$DIR1"
assert_output_contains "crown: trunk-beta listed" "trunk-beta" "$GEN" "$DIR1"
assert_output_not_contains "crown: plain parentless node excluded" "plain-root" "$GEN" "$DIR1"

# --- test 2: exactly five trunks produce exactly five trunk header lines ---

DIR2=$(mktemp -d)
trap 'rm -rf "$DIR1" "$DIR2"' EXIT

make_trunk "$DIR2" "trunk-one" "one"
make_trunk "$DIR2" "trunk-two" "two"
make_trunk "$DIR2" "trunk-three" "three"
make_trunk "$DIR2" "trunk-four" "four"
make_trunk "$DIR2" "trunk-five" "five"
make_node "$DIR2" "non-trunk-a" "" "not a trunk"
make_node "$DIR2" "non-trunk-b" "trunk-one" "typed child"

crown_count=$("$GEN" "$DIR2" 2>/dev/null | grep -c "^trunk-" || true)
if [[ "$crown_count" -eq 5 ]]; then
    echo "PASS: crown count: exactly 5 trunk headers"
    pass=$((pass + 1))
else
    echo "FAIL: crown count: expected 5 trunk headers, got $crown_count"
    fail=$((fail + 1))
fi

# --- test 3: typed child appears under its trunk ---

DIR3=$(mktemp -d)
trap 'rm -rf "$DIR1" "$DIR2" "$DIR3"' EXIT

make_trunk "$DIR3" "trunk-parent" "the parent trunk"
make_node "$DIR3" "child-of-trunk" "trunk-parent" "a direct trunk child"
make_node "$DIR3" "unrelated-root" "" "not a trunk"

output=$("$GEN" "$DIR3" 2>/dev/null)

if echo "$output" | grep -qF "child-of-trunk"; then
    echo "PASS: typed child: child-of-trunk appears"
    pass=$((pass + 1))
else
    echo "FAIL: typed child: child-of-trunk missing"
    echo "  output: $output"
    fail=$((fail + 1))
fi

trunk_line=$(echo "$output" | grep -n "trunk-parent" | head -1 | cut -d: -f1 || echo 0)
child_line=$(echo "$output" | grep -n "child-of-trunk" | head -1 | cut -d: -f1 || echo 0)
if [[ "$trunk_line" -gt 0 && "$child_line" -gt "$trunk_line" ]]; then
    echo "PASS: typed child: child positioned after its trunk"
    pass=$((pass + 1))
else
    echo "FAIL: typed child: child not after trunk (trunk=$trunk_line child=$child_line)"
    fail=$((fail + 1))
fi

# --- test 4: bridge node appears in trunk's provisional section ---

DIR4=$(mktemp -d)
trap 'rm -rf "$DIR1" "$DIR2" "$DIR3" "$DIR4"' EXIT

make_trunk "$DIR4" "trunk-x" "trunk x gist"
make_node "$DIR4" "bridge-node-a" "" "an untyped node"

BRIDGE4="$DIR4/bridge.md"
cat > "$BRIDGE4" <<'EOF'
## trunk-x (1)
- bridge-node-a
EOF

output=$("$GEN" "$DIR4" --bridge "$BRIDGE4" 2>/dev/null)

if echo "$output" | grep -qF "bridge-node-a"; then
    echo "PASS: bridge: bridge-node-a appears"
    pass=$((pass + 1))
else
    echo "FAIL: bridge: bridge-node-a missing"
    echo "  output: $output"
    fail=$((fail + 1))
fi

if echo "$output" | grep -qi "provisional"; then
    echo "PASS: bridge: provisional section label present"
    pass=$((pass + 1))
else
    echo "FAIL: bridge: no provisional section label"
    echo "  output: $output"
    fail=$((fail + 1))
fi

trunk_line=$(echo "$output" | grep -n "trunk-x" | head -1 | cut -d: -f1 || echo 0)
bridge_line=$(echo "$output" | grep -n "bridge-node-a" | head -1 | cut -d: -f1 || echo 0)
if [[ "$trunk_line" -gt 0 && "$bridge_line" -gt "$trunk_line" ]]; then
    echo "PASS: bridge: bridge node positioned after trunk"
    pass=$((pass + 1))
else
    echo "FAIL: bridge: bridge node not after trunk (trunk=$trunk_line bridge=$bridge_line)"
    fail=$((fail + 1))
fi

# --- test 5: cap guard fires, exits 2, emits truncation notice ---

DIR5=$(mktemp -d)
trap 'rm -rf "$DIR1" "$DIR2" "$DIR3" "$DIR4" "$DIR5"' EXIT

for i in $(seq 1 5); do
    make_trunk "$DIR5" "trunk-$(printf '%02d' "$i")" "gist number $i is here and takes space in the output buffer"
done

assert_exit "cap guard: exits 2 when budget exceeded" 2 "$GEN" "$DIR5" --budget 50

cap_output=$("$GEN" "$DIR5" --budget 50 2>&1 || true)
if echo "$cap_output" | grep -qF "truncated"; then
    echo "PASS: cap guard: truncation notice emitted"
    pass=$((pass + 1))
else
    echo "FAIL: cap guard: no truncation notice"
    echo "  output: $cap_output"
    fail=$((fail + 1))
fi

# --- test 6: gist from first prose line of trunk ---

DIR6=$(mktemp -d)
trap 'rm -rf "$DIR1" "$DIR2" "$DIR3" "$DIR4" "$DIR5" "$DIR6"' EXIT

cat > "$DIR6/trunk-prose.md" <<'EOF'
---
node_type: trunk
slug: trunk-prose
---
The prose gist for this trunk.
EOF

output=$("$GEN" "$DIR6" 2>/dev/null)
if echo "$output" | grep -qF "The prose gist for this trunk."; then
    echo "PASS: gist: first prose line used"
    pass=$((pass + 1))
else
    echo "FAIL: gist: first prose line not used"
    echo "  output: $output"
    fail=$((fail + 1))
fi

# --- test 7: exits 0 when all trunks fit in budget ---

DIR7=$(mktemp -d)
trap 'rm -rf "$DIR1" "$DIR2" "$DIR3" "$DIR4" "$DIR5" "$DIR6" "$DIR7"' EXIT

make_trunk "$DIR7" "trunk-aa" "short"
make_trunk "$DIR7" "trunk-bb" "short"

assert_exit "no truncation: exits 0 when under budget" 0 "$GEN" "$DIR7" --budget 10000

# --- summary ---

echo ""
echo "Results: $pass passed, $fail failed"
[[ "$fail" -eq 0 ]]
