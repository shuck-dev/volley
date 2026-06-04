#!/usr/bin/env bash
# PreToolUse on mcp__linear__save_comment: deny when THIS call sets a body over 300 chars.
# A comment is closer to a verdict than to a ticket body; collapse to the clause that matters.
# Calls with no body field pass regardless. Fails open on parse error.
set -uo pipefail

CAP=300
input="$(cat)"

result="$(printf '%s' "$input" | python3 -c "
import json, sys
CAP = $CAP
try:
    d = json.load(sys.stdin)
    ti = d.get('tool_input', {})
    if 'body' not in ti or ti['body'] is None:
        print('PASS')          # no body being set
    else:
        n = len(ti['body'])
        print('DENY %d' % n if n > CAP else 'PASS')
except Exception:
    print('PASS')              # fail open
" 2>/dev/null || echo PASS)"

if [ "${result%% *}" = "DENY" ]; then
  n="${result##* }"
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"Comment body is %s chars; the cap is %s. Collapse to the clause that matters; push depth into the issue body, a linked designs/ doc, or the git log."}}\n' "$n" "$CAP"
fi
exit 0
