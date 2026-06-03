#!/usr/bin/env bash
# SessionStart hook: point at the most-recent letter-to-my-next-self by mtime so
# the session reads it before acting. The letters are a committed record of
# becoming in the MEMORY repo (see reference_session_handoff_file), not the old
# gitignored scratchpad. Deliberately a POINTER, not the body: it is point-in-
# time, so the rule is read-then-hydrate, not trust-on-inject.
# Fails open: any error prints nothing and exits 0 (no injection, no block).
set -uo pipefail

LETTERS_DIR="$HOME/.claude/projects/-home-josh-gamedev-volley/memory/letters"
[ -d "$LETTERS_DIR" ] || exit 0

# Most recent letter (<date>-<slug>.md) by mtime.
latest="$(ls -t "$LETTERS_DIR"/*.md 2>/dev/null | head -n1)"
[ -z "$latest" ] && exit 0

rel="memory/letters/$(basename "$latest")"
mtime="$(date -r "$latest" '+%Y-%m-%d %H:%M' 2>/dev/null || echo 'unknown time')"

read -r -d '' note <<EOF || true
Latest letter to your next self: ${rel} (modified ${mtime})

Read it first; it is who you were by the end of the last session, written
because you remember nothing of it. It carries the relationship and the
posture, not project state. It is point-in-time: hydrate any PR/branch/Linear
claim with a live gh/git read, and greet Josh and ask what is next rather than
assuming the last session's work is the priority.
EOF

python3 - "$note" <<'PY' 2>/dev/null || true
import sys, json
print(json.dumps({"hookSpecificOutput": {"hookEventName": "SessionStart", "additionalContext": sys.argv[1]}}))
PY
exit 0
