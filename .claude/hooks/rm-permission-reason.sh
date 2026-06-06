#!/usr/bin/env bash
# PreToolUse(Bash) gate for rm. This hook IS the gate (no bare permissions rule
# behind it):
#   - rm chained/piped with other commands (&&, ||, ;, |, newline, or wrapped in
#     a subshell): denied. A chained rm hides damage in a line that's hard to
#     eyeball; run it on its own.
#   - standalone rm -rf (recursive force): denied. Reviewed deletes only.
#   - standalone plain rm: allowed.
# rm is matched as a command token (start, whitespace, separator, slash, backslash,
# or subshell char before it), so /bin/rm, \rm, $(rm ...), `rm ...`, xargs rm count.
set -euo pipefail

cmd="$(jq -r '.tool_input.command // ""')"
[ -z "$cmd" ] && exit 0

_rm_invoked='(^|[[:space:]&|;`($\\/])rm[[:space:]]'

# Is there an rm invocation at all?
printf '%s' "$cmd" | grep -Eq "${_rm_invoked}" || exit 0

# Chained/piped: a command separator (&& || ; |), a subshell wrapper, or a newline
# (multi-line command) appears anywhere alongside the rm. Deny the whole line.
# The newline is checked directly because grep -E newline handling is unreliable.
# Known false-deny: a separator char inside a quoted rm argument (rm "a;b") trips
# this; such filenames must be deleted in a command with no other separators.
if [ "$cmd" != "${cmd%$'\n'*}" ] || printf '%s' "$cmd" | grep -Eq '(&&|\|\||;|\||`|\$\()'; then
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"rm is chained with other commands (a separator, subshell, or newline is present). A chained rm hides what it deletes in a line that is hard to review. Run the rm on its own, in a separate step."}}'
  exit 0
fi

# Standalone rm -rf: recursive force in any spelling (-R is a synonym for -r).
if printf '%s' "$cmd" | grep -Eq '(-[a-zA-Z]*[rR]|--recursive)' \
  && printf '%s' "$cmd" | grep -Eq '(-[a-zA-Z]*f|--force)'; then
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"Recursive force-delete (rm -rf) is not run unattended. Remove a directory'"'"'s contents in a reviewed step, or ask Josh."}}'
  exit 0
fi

# Standalone plain rm: allowed silently.
