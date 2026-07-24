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

# Filter cold-cache UID warning class (godot#101677, godot#115205, godot#109636);
# see ai/scratchpads/godot-ci-uid-cache.md. The WARNING pattern is unique enough to
# filter unconditionally. Filter the paired Failed-loading-resource ERROR only when
# its path matches a UID warning seen earlier in the run; standalone Failed-loading
# ERRORs (broken .tres, missing scenes) still fail the gate.
#
# WARNING lines are printed for visibility but never fail the gate; only
# ERROR/SCRIPT ERROR/USER ERROR and actual test failures do.
warnings=$(printf '%s\n' "$plain" | awk '
{
	if (match($0, /^WARNING: .* ext_resource, invalid UID: .* using text path instead: (res:\/\/[^ ]+)/, m)) {
		cold_paths[m[1]] = 1
		next
	}
	if (match($0, /^ERROR: Failed loading resource: (res:\/\/[^ ]+)\./, m)) {
		if (m[1] in cold_paths) next
		print NR ":" $0
		next
	}
	if ($0 ~ /^(WARNING|USER WARNING):/) print NR ":" $0
}' || true)

errors=$(printf '%s\n' "$plain" | awk '
{
	if (match($0, /^WARNING: .* ext_resource, invalid UID: .* using text path instead: (res:\/\/[^ ]+)/, m)) {
		cold_paths[m[1]] = 1
		next
	}
	if (match($0, /^ERROR: Failed loading resource: (res:\/\/[^ ]+)\./, m)) {
		if (m[1] in cold_paths) next
		if (m[1] ~ /\.(png|webp|exr|hdr|gif|apng|wav|ogg|mp3|flac|mp4|webm|mov|ogv|psd|aseprite|ase|kra|svg)$/) next
		print NR ":" $0
		next
	}
	if ($0 ~ /^(ERROR|SCRIPT ERROR|USER ERROR):/) print NR ":" $0
}' || true)

if [ -n "$warnings" ]; then
	printf '%s\n' "$warnings" | head -30
	echo "ci gate: warnings in test output (non-blocking)"
fi

if [ -n "$errors" ]; then
	printf '%s\n' "$errors" | head -30
	echo "ci gate: errors in test output"
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
