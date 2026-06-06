#!/usr/bin/env bash
# PreToolUse(Bash) guard for rm. The bare permissions rules (Bash(rm:*) on ask,
# Bash(rm -rf:*) on deny) fire silently, so a denial reaches the agent as a bare
# "denied" with no cause, and the agent guesses why. This hook emits the SAME
# decisions WITH a permissionDecisionReason the agent can read, so the gate
# explains itself instead of being reverse-engineered.
set -euo pipefail

cmd="$(jq -r '.tool_input.command // ""')"
[ -z "$cmd" ] && exit 0

# rm -rf (and -fr / -r -f variants): deny outright. Matches an rm invocation
# carrying both recursive and force flags.
if printf '%s' "$cmd" | grep -Eq '(^|[[:space:]&|;`(])rm[[:space:]]+(-[a-zA-Z]*r[a-zA-Z]*f|-[a-zA-Z]*f[a-zA-Z]*r|-r[[:space:]]+-f|-f[[:space:]]+-r)'; then
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"rm -rf is on the deny list: recursive force-delete is never run unattended. If a directory must go, remove its contents in a reviewed step or ask Josh."}}'
  exit 0
fi

# Any other rm: ask, with the reason so a denial is legible (this is what bit a
# trailing `rm -rf \"$TMP\"` cleanup tacked onto an otherwise-fine command).
if printf '%s' "$cmd" | grep -Eq '(^|[[:space:]&|;`(])rm([[:space:]]|$)'; then
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"rm is on the ask list; confirm the path is intended. Note: a trailing rm cleanup drags an otherwise-fine command onto this path, prefer leaving /tmp files or deleting them in a separate step."}}'
  exit 0
fi
