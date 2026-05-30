#!/usr/bin/env bash
# PreToolUse(Bash) guard: only the maintainer merges PRs (via the UI Merge when
# ready). Deny any gh pr merge invocation by the agent, including --auto.
set -uo pipefail

input="$(cat)"
cmd="$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null || echo "")"
[ -z "$cmd" ] && exit 0

if printf '%s' "$cmd" | grep -qiE 'gh pr merge([[:space:]]|$)'; then
  printf '%s\n' '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"Only the maintainer merges PRs (via Merge when ready). The agent must not run gh pr merge, including --auto."}}'
  exit 0
fi

exit 0
