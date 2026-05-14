#!/usr/bin/env bash
# Runs the gut test suite and prints only the summary highlights on success.
# On failure, prints full output so the breaking test is visible.

set -eu

output=$(godot --headless -s addons/gut/gut_cmdln.gd 2>&1) && status=0 || status=$?

if [ $status -ne 0 ]; then
	printf '%s\n' "$output"
	exit $status
fi

plain=$(printf '%s\n' "$output" | sed -E 's/\x1b\[[0-9;]*m//g')

fail=0

# Filter out the cold-cache UID warning + paired Failed-loading-resource ERROR
# (godot#101677, godot#115205, godot#109636); see ai/scratchpads/godot-ci-uid-cache.md.
# Pair-match: drop the ERROR only when its path matches the immediately preceding
# UID-warning's text-path target; standalone Failed-loading-resource ERRORs still fail the gate.
warnings=$(printf '%s\n' "$plain" | awk '
function warn_path(line,   m) {
	if (match(line, /using text path instead: (res:\/\/[^ ]+)/, m)) return m[1]
	return ""
}
function err_path(line,   m) {
	if (match(line, /Failed loading resource: (res:\/\/[^ ]+)\./, m)) return m[1]
	return ""
}
{
	if (pending != "") {
		if (err_path($0) == pending_path) {
			pending = ""; pending_path = ""; next
		}
		print pending_lineno ":" pending
		pending = ""; pending_path = ""
	}
	if ($0 ~ /^WARNING: .* ext_resource, invalid UID: .* using text path instead: res:\/\//) {
		pending = $0; pending_lineno = NR; pending_path = warn_path($0); next
	}
	if ($0 ~ /^(WARNING|ERROR|SCRIPT ERROR|USER WARNING|USER ERROR):/) print NR ":" $0
}
END { if (pending != "") print pending_lineno ":" pending }
' || true)

if [ -n "$warnings" ]; then
	printf '%s\n' "$warnings" | head -30
	echo "ci gate: warnings or errors in test output"
	fail=1
fi

if printf '%s\n' "$plain" | grep -qE '^[[:space:]]+[1-9][0-9]* Orphans'; then
	printf '%s\n' "$plain" | grep -nE '^[[:space:]]+[1-9][0-9]* Orphans' | head -30
	echo "ci gate: per-test orphans detected (nodes left in tree); see ai/scratchpads/gut-orphans-research.md"
	fail=1
fi

if [ "$fail" -ne 0 ]; then
	exit 1
fi

printf '%s\n' "$output" | grep -E \
	'Total Coverage|Run Summary|^Scripts|^Tests|Passing Tests|Failing Tests|^Asserts|^Time|All tests passed|failing tests' \
	|| true
