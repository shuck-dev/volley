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

if printf '%s\n' "$plain" | grep -qE '^(WARNING|ERROR|SCRIPT ERROR|USER WARNING|USER ERROR):'; then
	printf '%s\n' "$plain" | grep -nE '^(WARNING|ERROR|SCRIPT ERROR|USER WARNING|USER ERROR):' | head -30
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
