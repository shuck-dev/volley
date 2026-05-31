#!/usr/bin/env bash
# PreToolUse on Agent: deny a repo-file-EDITING agent dispatch that lacks isolation: "worktree".
# Rule: code-writing minions run in their own worktree (ai/skills/gru/dispatch.md), so they never
# share the main tree or its dirty state. Runtime/reviewer types are exempt (they need the main
# editor for godotiq, or are read-only).
# Fails open on parse error.
set -uo pipefail

input="$(cat)"

printf '%s' "$input" | python3 -c "
import json, sys
# Editing agent types that ship repo file changes and do not need the running godotiq editor.
EDITING = {'gdscript-implementer', 'test-author', 'integration-scenario-author', 'docs-tender'}
try:
    d = json.load(sys.stdin)
    ti = d.get('tool_input', {})
    st = ti.get('subagent_type', '')
    iso = ti.get('isolation', '')
except Exception:
    sys.exit(0)

if st in EDITING and iso != 'worktree':
    reason = (
        st + ' edits repo files and must dispatch with isolation: worktree so it does not share '
        'the main worktree or its uncommitted state (ai/skills/gru/dispatch.md). Re-issue with '
        'isolation set. If it genuinely needs the running godotiq editor, it is the wrong agent type.'
    )
    out = {'hookSpecificOutput': {'hookEventName': 'PreToolUse',
                                  'permissionDecision': 'deny',
                                  'permissionDecisionReason': reason}}
    print(json.dumps(out))
" 2>/dev/null || true
exit 0
