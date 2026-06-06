#!/usr/bin/env bash
# PreToolUse(Bash) gate for rm. This hook IS the gate (no bare permissions rule
# behind it), so it carries its own reasoning rather than narrating a rule:
#   - rm -rf (recursive force): denied.
#   - plain rm tacked on as a trailing cleanup after other commands: allowed, but
#     warned, that trailing-cleanup pattern is the one that drags an otherwise-fine
#     command onto a prompt and reads badly; split it into its own step.
#   - plain rm on its own: allowed silently.
set -euo pipefail

cmd="$(jq -r '.tool_input.command // ""')"
[ -z "$cmd" ] && exit 0

# rm with both recursive AND force, in any spelling, denied. Catches:
#   - short clusters: -rf, -fr, -rvf, -r -f, -f -r
#   - long flags: --recursive --force (either order, mixed with short)
#   - path-qualified / escaped / wrapped: /bin/rm, \rm, $(rm ...), `rm ...`, xargs rm
# rm is matched as a command token (start, whitespace, separator, slash, backslash,
# or subshell char before it), then recursive and force each appear somewhere after.
# Known limitation: the two flag checks are independent, so two SEPARATE rm calls on
# one line (rm -r a; rm -f b) trip the deny even though neither is rm -rf. This is a
# conservative false-deny, not a bypass; split the commands into separate calls. Not
# worth per-invocation parsing in a shell regex for a rare, recoverable case.
_rm_invoked='(^|[[:space:]&|;`($\\/])rm[[:space:]]'
_has_recursive='(-[a-zA-Z]*r|--recursive)'
_has_force='(-[a-zA-Z]*f|--force)'
if printf '%s' "$cmd" | grep -Eq "${_rm_invoked}" \
  && printf '%s' "$cmd" | grep -Eq "${_rm_invoked}.*${_has_recursive}" \
  && printf '%s' "$cmd" | grep -Eq "${_rm_invoked}.*${_has_force}"; then
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"Recursive force-delete (rm -rf) is not run unattended. Remove a directory'"'"'s contents in a reviewed step, or ask Josh."}}'
  exit 0
fi

# Plain rm that follows another command on the same line (&&, ||, ;, |, newline):
# the trailing-cleanup pattern. Allow, but warn.
if printf '%s' "$cmd" | grep -Eq '[^[:space:]].*([&|;]|`)[[:space:]]*rm([[:space:]]|$)'; then
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"allow","permissionDecisionReason":"Trailing rm cleanup: this rm runs after other commands on the same line. Allowed, but prefer leaving /tmp files or deleting them in a separate step, a trailing cleanup is what drags an otherwise-fine command onto a prompt."}}'
  exit 0
fi

# Any other rm (leading / sole command): allow silently by not emitting a decision.
