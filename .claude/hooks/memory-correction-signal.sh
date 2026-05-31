#!/usr/bin/env bash
# UserPromptSubmit hook: scans the user's prompt for correction-phrase
# heuristics and injects a system reminder when one matches, prompting
# Claude to consider whether this turn introduces or sharpens a memory rule.
set -euo pipefail

prompt="$(jq -r '.prompt // empty')"
[[ -z "$prompt" ]] && exit 0

if printf '%s' "$prompt" | grep -qiE "(\\bdon't\\b|\\bstop\\b|\\balways\\b|\\bnever\\b|\\bactually\\b|\\bremember\\b|you didn't|you should|no don't|wrong way|isn't right|is not right|you forgot|\\bmissed\\b)"; then
  jq -n '{
    hookSpecificOutput: {
      hookEventName: "UserPromptSubmit",
      additionalContext: "Possible correction signal in user message — apply feedback_corrections_always_update_memory and feedback_continuous_rule_refinement: consider whether this turn introduces or sharpens a memory rule, and if so update memory + commit before turn ends."
    }
  }'
fi
exit 0
