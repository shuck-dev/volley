#!/usr/bin/env bash
# PreToolUse on Edit/Write: deny a memory-dir leaf .md file growing past the cap.
# Leaves are capped; MEMORY.md (generated index) and letters/ (handoff letters) are exempt.
# Grow-only: a shrinking edit on an already-oversized file always passes. Fails open.
set -uo pipefail

CAP=2000
MEMDIR="${HOME}/.claude/projects/-home-josh-gamedev-volley/memory"
input="$(cat)"

result="$(printf '%s' "$input" | python3 -c "
import json, sys, os
CAP = $CAP
MEMDIR = os.path.realpath('$MEMDIR')
try:
    d = json.load(sys.stdin)
    tool = d.get('tool_name', '')
    ti = d.get('tool_input', {})
    path = ti.get('file_path', '')
    rp = os.path.realpath(path) if path else ''
    # only genuine children of the memory dir, .md files
    if not rp.startswith(MEMDIR + os.sep) or not rp.endswith('.md'):
        print('PASS'); sys.exit()
    # exempt the generated index and the handoff letters (both legitimately large)
    if os.path.basename(rp) == 'MEMORY.md' or (os.sep + 'letters' + os.sep) in rp:
        print('PASS'); sys.exit()
    try:
        cur = open(rp, encoding='utf-8').read()
    except FileNotFoundError:
        cur = ''
    if tool == 'Write':
        size = len(ti.get('content', ''))
    elif tool == 'Edit':
        old = ti.get('old_string', '')
        new = ti.get('new_string', '')
        size = len(cur.replace(old, new)) if ti.get('replace_all') else len(cur.replace(old, new, 1))
    else:
        print('PASS'); sys.exit()
    # Block only growth over cap. A smaller result always passes (shrinking is the fix).
    if size > CAP and size >= len(cur):
        print('DENY %d %d' % (size, len(cur)))
    else:
        print('PASS')
except Exception:
    print('PASS')  # fail open
" 2>/dev/null || echo PASS)"

if [ "${result%% *}" = "DENY" ]; then
  read -r _ n cur <<< "$result"
  if [ "$cur" -gt "$CAP" ]; then
    # already oversized: the right move is to keep shrinking, not split
    reason="Memory file would be ${n} chars; the cap is ${CAP} and it is not getting smaller. Keep cutting until it is under ${CAP}."
  else
    reason="Memory file would be ${n} chars; the cap is ${CAP}. A leaf is one rule. Split it into two rules, or push doctrine into child nodes and leave a short index."
  fi
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"%s"}}\n' "$reason"
fi
exit 0
