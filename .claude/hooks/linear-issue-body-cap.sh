#!/usr/bin/env bash
# PreToolUse on mcp__linear__save_issue: deny when THIS call sets a description over 600 chars.
# Overflow belongs in a linked design doc, not the issue body.
# State-only saves (no description field in the call) pass regardless of the stored body length.
# Fails open on parse error.
set -uo pipefail

CAP=600
input="$(cat)"

result="$(printf '%s' "$input" | python3 -c "
import json, sys
CAP = $CAP
try:
    d = json.load(sys.stdin)
    ti = d.get('tool_input', {})
    if 'description' not in ti or ti['description'] is None:
        print('PASS')          # state-only save, body not being set
    else:
        n = len(ti['description'])
        print('DENY %d' % n if n > CAP else 'PASS')
except Exception:
    print('PASS')              # fail open
" 2>/dev/null || echo PASS)"

if [ "${result%% *}" = "DENY" ]; then
  n="${result##* }"
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"Issue body is %s chars; the cap is %s. Trim the body to the ask + AC and move the depth (options, rationale, design detail) into a designs/ doc linked via the issue links field."}}\n' "$n" "$CAP"
fi
exit 0
