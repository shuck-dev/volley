#!/usr/bin/env bash
# PreToolUse on Bash, gated to bot-review.yml: deny when the synthesis verdict -f body exceeds 300 chars.
# A clean re-verdict roll-call restates what the inline threads carry; the body is the verdict, not a report.
# Non-bot-review commands and parse errors pass.
set -uo pipefail

CAP=300
input="$(cat)"

result="$(printf '%s' "$input" | python3 -c "
import json, sys, re
CAP = $CAP
try:
    d = json.load(sys.stdin)
    cmd = d.get('tool_input', {}).get('command', '')
    if 'bot-review.yml' not in cmd:
        print('PASS')
    else:
        m = re.search(r'-f body=([\x27\"])(.*?)\1', cmd, re.S)
        if not m:
            print('PASS')
        else:
            n = len(m.group(2))
            print('DENY %d' % n if n > CAP else 'PASS')
except Exception:
    print('PASS')
" 2>/dev/null || echo PASS)"

if [ "${result%% *}" = "DENY" ]; then
  n="${result##* }"
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"Synthesis verdict body is %s chars; the cap is %s. Collapse to the resolved-findings clause and the verdict; the inline threads carry the detail."}}\n' "$n" "$CAP"
fi
exit 0
