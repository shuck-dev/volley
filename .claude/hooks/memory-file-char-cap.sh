#!/usr/bin/env bash
# PreToolUse on Edit/Write: deny when the call would leave a memory FILE over the cap.
# A memory node is one rule (a leaf, ~1.6-2.7k chars in the corpus) or a short index
# node; nothing should legitimately exceed the cap. Over it means two rules to separate,
# or a root hoarding doctrine that should push down into its children.
# Only fires on files under the memory dir. Index files (MEMORY.md) are exempt.
# Fails open on any parse error.
set -uo pipefail

CAP=2000
MEMDIR="/home/josh/.claude/projects/-home-josh-gamedev-volley/memory"
input="$(cat)"

result="$(printf '%s' "$input" | python3 -c "
import json, sys, os
CAP = $CAP
MEMDIR = '$MEMDIR'
try:
    d = json.load(sys.stdin)
    tool = d.get('tool_name', '')
    ti = d.get('tool_input', {})
    path = ti.get('file_path', '')
    # only memory-dir .md files, excluding the generated index
    rp = os.path.realpath(path) if path else ''
    if not rp.startswith(os.path.realpath(MEMDIR)) or not rp.endswith('.md'):
        print('PASS'); sys.exit()
    if os.path.basename(rp) == 'MEMORY.md':
        print('PASS'); sys.exit()
    # compute the resulting file size and the current size
    try:
        cur = open(rp, encoding='utf-8').read()
    except FileNotFoundError:
        cur = ''
    if tool == 'Write':
        size = len(ti.get('content', ''))
    elif tool == 'Edit':
        old = ti.get('old_string', '')
        new = ti.get('new_string', '')
        if ti.get('replace_all'):
            size = len(cur.replace(old, new))
        else:
            size = len(cur.replace(old, new, 1))
    else:
        print('PASS'); sys.exit()
    # Block only when the result is over cap AND not smaller than now.
    # A shrinking edit on an already-oversized node is the fix, never blocked.
    print('DENY %d' % size if (size > CAP and size >= len(cur)) else 'PASS')
except Exception:
    print('PASS')  # fail open
" 2>/dev/null || echo PASS)"

if [ "${result%% *}" = "DENY" ]; then
  n="${result##* }"
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"Memory file would be %s chars; the cap is %s. A node is one rule. Over the cap means: separate it into two rules, merge nothing, or (if a root) push doctrine down into child nodes and leave an index."}}\n' "$n" "$CAP"
fi
exit 0
