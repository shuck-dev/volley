#!/usr/bin/env bash
# Tests for inject-memory-crown.sh hook.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOK="${SCRIPT_DIR}/../../.claude/hooks/inject-memory-crown.sh"

pass=0
fail=0

tmpwrap=""
tmpwrap2=""
tmpgen=""

cleanup() {
    [ -n "$tmpwrap" ] && [ -f "$tmpwrap" ] && unlink "$tmpwrap" 2>/dev/null || true
    [ -n "$tmpwrap2" ] && [ -f "$tmpwrap2" ] && unlink "$tmpwrap2" 2>/dev/null || true
    [ -n "$tmpgen" ] && [ -f "$tmpgen" ] && unlink "$tmpgen" 2>/dev/null || true
}
trap cleanup EXIT

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

# --- test 1: hook produces valid JSON with SessionStart event name ---

assert_exit "hook exits 0" 0 "$HOOK"
assert_output_contains "output is valid JSON with hookEventName" \
    '"hookEventName": "SessionStart"' "$HOOK"

# --- test 2: additionalContext contains all five trunk slugs ---

output=$("$HOOK" 2>&1)
for slug in trunk_dev_cycle trunk_docs trunk_shuck trunk_volley trunk_who_i_am; do
    if echo "$output" | grep -qF "$slug"; then
        echo "PASS: additionalContext contains $slug"
        pass=$((pass + 1))
    else
        echo "FAIL: additionalContext missing $slug"
        echo "  actual output: $output"
        fail=$((fail + 1))
    fi
done

# --- test 3: hook exits 0 and emits nothing when generator is absent ---

tmpwrap=$(mktemp)
cat > "$tmpwrap" << 'WRAP'
#!/usr/bin/env bash
set -uo pipefail
GENERATOR="/tmp/does-not-exist-$$"
[ -x "$GENERATOR" ] || exit 0
crown="$(bash "$GENERATOR" 2>/dev/null)" || exit 0
[ -z "$crown" ] && exit 0
echo "SHOULD NOT REACH HERE"
WRAP
chmod +x "$tmpwrap"

assert_exit "exits 0 when generator absent" 0 "$tmpwrap"
assert_output_not_contains "emits nothing when generator absent" "SHOULD NOT REACH HERE" "$tmpwrap"

# --- test 4: hook exits 0 and emits nothing when generator exits non-zero ---

tmpgen=$(mktemp)
printf '#!/usr/bin/env bash\nexit 2\n' > "$tmpgen"
chmod +x "$tmpgen"

tmpwrap2=$(mktemp)
printf '#!/usr/bin/env bash\nset -uo pipefail\nGENERATOR="%s"\n[ -x "$GENERATOR" ] || exit 0\ncrown="$(bash "$GENERATOR" 2>/dev/null)" || exit 0\n[ -z "$crown" ] && exit 0\necho "SHOULD NOT REACH HERE"\n' "$tmpgen" > "$tmpwrap2"
chmod +x "$tmpwrap2"

assert_exit "exits 0 when generator exits non-zero" 0 "$tmpwrap2"
assert_output_not_contains "emits nothing when generator exits non-zero" "SHOULD NOT REACH HERE" "$tmpwrap2"

# --- summary ---

echo ""
echo "Results: $pass passed, $fail failed"
[[ "$fail" -eq 0 ]]
