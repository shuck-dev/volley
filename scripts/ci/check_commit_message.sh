#!/usr/bin/env bash
# Validates commit messages match `[SH-<ticket> ]<type>: <subject>` where type is
# one of feat|fix|chore|docs|refactor|test|style|perf|ci|build|revert.
# Allows merge/squash commits and fixup/amend messages to pass untouched.

set -eu

COMMIT_MSG_FILE="$1"
FIRST_LINE=$(head -n 1 "$COMMIT_MSG_FILE")

case "$FIRST_LINE" in
	"Merge "* | "Revert "* | "fixup! "* | "squash! "* | "amend! "*)
		exit 0
		;;
esac

PATTERN='^(SH-[0-9]+ )?(feat|fix|chore|docs|refactor|test|style|perf|ci|build|revert): .+'
if ! printf '%s' "$FIRST_LINE" | grep -qE "$PATTERN"; then
	cat >&2 <<EOF
Commit message does not match the required format.
Expected: [SH-<ticket> ]<type>: <subject>
Types:    feat, fix, chore, docs, refactor, test, style, perf, ci, build, revert
Got:      $FIRST_LINE
EOF
	exit 1
fi
