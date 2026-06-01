#!/usr/bin/env bash
# PreToolUse on Agent: warn when the dispatch prompt names a branch that differs from the
# main tree's current branch. Catches dispatching an agent to diagnose/edit branch X while
# the tree is on branch Y (a dispatched agent reads the tree's current branch).
# Warns only when the prompt explicitly names a branch and it mismatches; silent otherwise.
# Fails open on any parse/git error.
set -uo pipefail

input="$(cat)"

printf '%s' "$input" | CUR_BRANCH="$(git -C "${CLAUDE_PROJECT_DIR:-.}" branch --show-current 2>/dev/null || echo '')" python3 -c "
import json, os, re, sys

cur = os.environ.get('CUR_BRANCH', '').strip()
if not cur:
    sys.exit(0)

try:
    d = json.load(sys.stdin)
    prompt = d.get('tool_input', {}).get('prompt', '')
except Exception:
    sys.exit(0)

# A branch the brief names to work on: the project's branch-name shapes.
named = re.findall(r'\b(?:feature|chore|fix|docs|refactor|test|ci|perf)/[a-z0-9][a-z0-9._/-]*', prompt)
# Drop trivial trailing punctuation a sentence might attach.
named = [b.rstrip('.,);/\`\"') for b in named]
# Drop file paths: a docs/ or ci/ prefix also names a referenced file, whose last segment carries an extension.
named = [b for b in named if '.' not in b.rsplit('/', 1)[-1]]
# Unique, preserve order.
seen = []
for b in named:
    if b not in seen:
        seen.append(b)

if seen and cur not in seen:
    reason = (
        'Branch mismatch: the main tree is on \'' + cur + '\' but the dispatch names '
        + ', '.join(\"'\" + b + \"'\" for b in seen) + '. A dispatched agent reads the tree\\'s '
        'current branch, so it would work against \'' + cur + '\', not the named branch. '
        'Switch the main tree to the intended branch (or use isolation), then re-dispatch.'
    )
    out = {'hookSpecificOutput': {'hookEventName': 'PreToolUse',
                                  'permissionDecision': 'ask',
                                  'permissionDecisionReason': reason}}
    print(json.dumps(out))
" 2>/dev/null || true
exit 0
