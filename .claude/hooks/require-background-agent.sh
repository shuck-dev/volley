#!/usr/bin/env bash
# PreToolUse hook on Agent: deny any dispatch missing run_in_background: true.
# Rule feedback_agents_default_background: always background, no exceptions.
# Fails open on parse error (no false block), denies only on a clear missing/false flag.
set -uo pipefail

input="$(cat)"

bg="$(printf '%s' "$input" | python3 -c "
import json, sys
try:
    d = json.load(sys.stdin)
    print(str(d.get('tool_input', {}).get('run_in_background')).lower())
except Exception:
    print('parse_error')
" 2>/dev/null || echo parse_error)"

# Only act when we positively read a non-true flag. Anything ambiguous passes.
if [ "$bg" = "true" ] || [ "$bg" = "parse_error" ]; then
  exit 0
fi

printf '%s\n' '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"Agent dispatch must set run_in_background: true (feedback_agents_default_background, always background, no exceptions). Re-issue the call with the flag."}}'
exit 0
