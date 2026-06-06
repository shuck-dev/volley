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

# rm with both recursive and force flags (-rf / -fr / -r -f / -f -r): deny.
if printf '%s' "$cmd" | grep -Eq '(^|[[:space:]&|;`(])rm[[:space:]]+(-[a-zA-Z]*r[a-zA-Z]*f|-[a-zA-Z]*f[a-zA-Z]*r|-r[[:space:]]+-f|-f[[:space:]]+-r)'; then
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
