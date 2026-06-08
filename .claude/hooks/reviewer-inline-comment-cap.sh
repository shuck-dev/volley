#!/usr/bin/env bash
# PreToolUse on Bash, gated to a reviews/comments POST: deny when any inline finding
# body exceeds 300 chars. A review comment is a verdict-sized clause (the reviewers
# skill: 30 words, 2 lines); long inlines restate what the diff already shows.
# Only fires on `gh api ... pulls/.../reviews` or `.../comments` POSTs. Fails open.
set -uo pipefail

CAP=300
input="$(cat)"

result="$(printf '%s' "$input" | python3 -c "
import json, sys, re
CAP = $CAP
try:
    d = json.load(sys.stdin)
    cmd = d.get('tool_input', {}).get('command', '')
    # only reviewer-posting calls: a POST to pulls/.../reviews or .../comments
    if not re.search(r'pulls/[^ ]*/(reviews|comments)', cmd):
        print('PASS'); sys.exit()
    if 'POST' not in cmd and '-X POST' not in cmd:
        print('PASS'); sys.exit()
    # find every \"body\": \"...\" value in the command (the inline finding text)
    bodies = re.findall(r'\"body\"\s*:\s*\"((?:[^\"\\\\]|\\\\.)*)\"', cmd)
    worst = 0
    for b in bodies:
        # unescape \\n, \\\" etc to count visible chars
        try:
            v = json.loads('\"' + b + '\"')
        except Exception:
            v = b
        worst = max(worst, len(v))
    print('DENY %d' % worst if worst > CAP else 'PASS')
except Exception:
    print('PASS')  # fail open
" 2>/dev/null || echo PASS)"

if [ "${result%% *}" = "DENY" ]; then
  n="${result##* }"
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"An inline review comment is %s chars; the cap is %s. A finding is one clause: name the concern and the fix, anchored to the line. Push the reasoning into the dispatcher report, not the PR thread."}}\n' "$n" "$CAP"
fi
exit 0
