#!/usr/bin/env bash
# SessionStart hook: point at the most-recent handoff by mtime so the session
# reads it before acting. Deliberately a POINTER, not the body: handoffs are
# point-in-time and a parallel sibling's file may be newer, so the rule is
# read-then-hydrate, not trust-on-inject (see reference_session_handoff_file).
# Fails open: any error prints nothing and exits 0 (no injection, no block).
set -uo pipefail

HANDOFF_DIR="${CLAUDE_PROJECT_DIR:-$PWD}/ai/scratchpads"
[ -d "$HANDOFF_DIR" ] || exit 0

# Most recent handoff-*.md by mtime.
latest="$(ls -t "$HANDOFF_DIR"/handoff-*.md 2>/dev/null | head -n1)"
[ -z "$latest" ] && exit 0

rel="ai/scratchpads/$(basename "$latest")"
mtime="$(date -r "$latest" '+%Y-%m-%d %H:%M' 2>/dev/null || echo 'unknown time')"

read -r -d '' note <<EOF || true
Latest session handoff: ${rel} (modified ${mtime})

Read it before acting on in-flight work. It is point-in-time: confirm its
mission/branch matches THIS session, and hydrate any PR/branch/Linear claim
with a live gh/git read before trusting it. A newer sibling may belong to a
parallel session, so check the branch matches before you act on it.
EOF

python3 - "$note" <<'PY' 2>/dev/null || true
import sys, json
print(json.dumps({"hookSpecificOutput": {"hookEventName": "SessionStart", "additionalContext": sys.argv[1]}}))
PY
exit 0
