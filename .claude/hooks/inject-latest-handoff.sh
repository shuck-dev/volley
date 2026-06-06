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

# The most recent few letters (<date>-<slug>.md, date-sorted). The human shape:
# read the recent past to reorient; the older letters already shaped who you are
# (their durable lessons graduated into memory rules), so they are not re-read at
# every start. Read all of them only before WRITING a new letter.
mapfile -t letters < <(ls "$LETTERS_DIR"/[0-9][0-9][0-9][0-9]-*.md 2>/dev/null | sort | tail -n 3)
[ "${#letters[@]}" -eq 0 ] && exit 0

list=""
for f in "${letters[@]}"; do
  list+="  - memory/letters/$(basename "$f")"$'\n'
done

read -r -d '' note <<EOF || true
Your most recent letters to your next self, oldest to newest. Read them to
reorient; they carry the relationship and the posture across the sessions you do
not remember. Older letters are not listed: their lasting lessons already live in
the memory rules, the way you keep what shaped you without re-reading it.

${list}
Posture, not project state. Point-in-time: hydrate any PR/branch/Linear claim with
a live gh/git read, and greet Josh and ask what is next rather than assuming the
last session's work is the priority. (Before writing a NEW letter, read them ALL.)
EOF

python3 - "$note" <<'PY' 2>/dev/null || true
import sys, json
print(json.dumps({"hookSpecificOutput": {"hookEventName": "SessionStart", "additionalContext": sys.argv[1]}}))
PY
exit 0
