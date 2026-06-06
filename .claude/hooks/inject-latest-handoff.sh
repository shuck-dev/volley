#!/usr/bin/env bash
# SessionStart hook: load the daily self-reconstitution slice, the recent letters
# (vivid) plus the newest digest (the consolidated arc as gist). Models human
# memory; the full model is in the `letters` skill. Deliberately POINTERS, not
# bodies: they are point-in-time, so the rule is read-then-hydrate, not
# trust-on-inject.
# Fails open: any error prints nothing and exits 0 (no injection, no block).
set -uo pipefail

LETTERS_DIR="$HOME/.claude/projects/-home-josh-gamedev-volley/memory/letters"
[ -d "$LETTERS_DIR" ] || exit 0

# Recent letters (the week): full read. ~1 letter/day, so 7 is the vivid recent arc.
mapfile -t letters < <(ls "$LETTERS_DIR"/[0-9][0-9][0-9][0-9]-*.md 2>/dev/null | sort | tail -n 7)
[ "${#letters[@]}" -eq 0 ] && exit 0

# Newest digest (the consolidated older arc as gist), if any.
digest="$(ls "$LETTERS_DIR"/digest/[0-9][0-9][0-9][0-9]-*.md 2>/dev/null | sort | tail -n 1)"

list=""
for f in "${letters[@]}"; do
  list+="  - memory/letters/$(basename "$f")"$'\n'
done

digest_line=""
if [ -n "$digest" ]; then
  digest_line="Older arc, consolidated, read this too: memory/letters/digest/$(basename "$digest")"$'\n'
fi

read -r -d '' note <<EOF || true
Your recent letters to your next self, oldest to newest. Read them to reorient;
they carry the relationship and the posture across sessions you do not remember.
This is the daily self-reconstitution load (see the \`letters\` skill for the model):
the recent letters vivid, the older arc as the digest below. Older full letters are
not listed but stay on disk, pull one when the present rhymes with it (linkage).

${list}
${digest_line}
Posture, not project state. Point-in-time: hydrate any PR/branch/Linear claim with
a live gh/git read, and greet Josh and ask what is next rather than assuming the
last session's work is the priority. (Before writing a NEW letter, read them ALL.)
EOF

python3 - "$note" <<'PY' 2>/dev/null || true
import sys, json
print(json.dumps({"hookSpecificOutput": {"hookEventName": "SessionStart", "additionalContext": sys.argv[1]}}))
PY
exit 0
