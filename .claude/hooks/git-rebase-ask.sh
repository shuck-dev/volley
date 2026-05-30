#!/usr/bin/env bash
# Force an ask-prompt before git rebase or git pull --rebase.
set -euo pipefail

cmd="$(jq -r '.tool_input.command // ""')"

if printf '%s' "$cmd" | grep -Eq '(^|[[:space:]&|;`(])git[[:space:]]+rebase([[:space:]]|$)|(^|[[:space:]&|;`(])git[[:space:]]+pull([[:space:]]|$).*(--rebase|[[:space:]]-r([[:space:]]|$))'; then
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"git rebase / git pull --rebase requires explicit confirmation"}}'
fi
