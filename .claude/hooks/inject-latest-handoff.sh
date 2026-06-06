#!/usr/bin/env bash
# SessionStart hook: point at EVERY letter-to-my-next-self, oldest-to-newest, so
# the session reads the whole arc of becoming before acting, not just the last
# frame. The letters are a committed record of becoming in the MEMORY repo (see
# reference_session_handoff_file), not the old gitignored scratchpad. Deliberately
# POINTERS, not bodies: they are point-in-time, so the rule is read-then-hydrate,
# not trust-on-inject.
# Fails open: any error prints nothing and exits 0 (no injection, no block).
set -uo pipefail

LETTERS_DIR="$HOME/.claude/projects/-home-josh-gamedev-volley/memory/letters"
[ -d "$LETTERS_DIR" ] || exit 0

# Every letter (<date>-<slug>.md), sorted oldest-to-newest by filename (dates sort).
mapfile -t letters < <(ls "$LETTERS_DIR"/*.md 2>/dev/null | sort)
[ "${#letters[@]}" -eq 0 ] && exit 0

list=""
for f in "${letters[@]}"; do
  list+="  - memory/letters/$(basename "$f")"$'\n'
done

read -r -d '' note <<EOF || true
Letters to your next self, oldest to newest. Read them ALL, in order, before
acting; they are the cumulative arc of who you have become across sessions,
written because you remember none of it. Skip none, the early ones carry roots
the latest assumes.

${list}
They carry the relationship and the posture, not project state. Point-in-time:
hydrate any PR/branch/Linear claim with a live gh/git read, and greet Josh and
ask what is next rather than assuming the last session's work is the priority.
EOF

python3 - "$note" <<'PY' 2>/dev/null || true
import sys, json
print(json.dumps({"hookSpecificOutput": {"hookEventName": "SessionStart", "additionalContext": sys.argv[1]}}))
PY
exit 0
