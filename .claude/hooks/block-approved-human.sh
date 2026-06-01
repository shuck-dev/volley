#!/usr/bin/env bash
# PreToolUse(Bash) guard: deny any attempt to apply (or remove) the
# approved-human label. That label is Josh's human sign-off gate; the agent
# must never touch it. Reads pass (a gh pr view that merely mentions the label
# in a jq filter is fine); only label-mutating commands are denied.
set -uo pipefail

input="$(cat)"
cmd="$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null || echo "")"
[ -z "$cmd" ] && exit 0

deny=0
# gh flag form: --add-label / --remove-label followed (optionally quoted) by
# the label name. Matches the actual mutation, not a prose mention.
if printf '%s' "$cmd" | grep -qiE -- '--(add|remove)-label[=[:space:]]+.{0,1}approved-human'; then
  deny=1
fi
# REST/GraphQL form: a write to a labels endpoint carrying the label name.
if printf '%s' "$cmd" | grep -qiE 'approved-human' \
   && printf '%s' "$cmd" | grep -qiE '(issues|pulls)/[^[:space:]]*/labels|addLabels|removeLabels' \
   && printf '%s' "$cmd" | grep -qiE -- '-X[[:space:]]+(POST|PUT|DELETE)|--method[[:space:]]+(POST|PUT|DELETE)'; then
  deny=1
fi

if [ "$deny" = "1" ]; then
  printf '%s\n' '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"Refusing to mutate the approved-human label. That is the human sign-off gate and is Josh'"'"'s alone; the agent must never apply or remove it. Ask Josh to approve."}}'
  exit 0
fi

exit 0
