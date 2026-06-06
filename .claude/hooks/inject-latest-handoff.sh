#!/usr/bin/env bash
# SessionStart hook: load the daily self-reconstitution slice as a three-tier human
# memory gradient (see the `letters` skill): recent letters full (vivid), a prior band
# of one-line summaries (fading-but-recallable), the newest digest (consolidated gist).
# Deliberately POINTERS plus summaries, not full bodies for the older tiers: they are
# point-in-time, so the rule is read-then-hydrate, not trust-on-inject.
# Fails open: any error prints nothing and exits 0 (no injection, no block).
set -uo pipefail

LETTERS_DIR="$HOME/.claude/projects/-home-josh-gamedev-volley/memory/letters"
[ -d "$LETTERS_DIR" ] || exit 0

# All letters, oldest-to-newest (date-prefixed names sort chronologically).
mapfile -t all < <(ls "$LETTERS_DIR"/[0-9][0-9][0-9][0-9]-*.md 2>/dev/null | sort)
[ "${#all[@]}" -eq 0 ] && exit 0

RECENT=7   # vivid tier: read full
BAND=30    # band tier: one summary line each (the prior ~month)

n=${#all[@]}
recent_start=$(( n > RECENT ? n - RECENT : 0 ))
band_start=$(( recent_start > BAND ? recent_start - BAND : 0 ))

# Recent tier: pointers to the full letters.
recent_list=""
for ((i = recent_start; i < n; i++)); do
  recent_list+="  - memory/letters/$(basename "${all[$i]}")"$'\n'
done

# Band tier: the summary: frontmatter line of each prior letter, slug plus gist.
band_list=""
for ((i = band_start; i < recent_start; i++)); do
  f="${all[$i]}"
  slug="$(basename "$f" .md)"
  summary="$(sed -n 's/^summary:[[:space:]]*//p' "$f" | head -n 1)"
  [ -z "$summary" ] && summary="(no summary line)"
  band_list+="  - ${slug}: ${summary}"$'\n'
done

# Digest tier: newest consolidated digest, if any.
digest="$(ls "$LETTERS_DIR"/digest/[0-9][0-9][0-9][0-9]-*.md 2>/dev/null | sort | tail -n 1)"

band_block=""
[ -n "$band_list" ] && band_block="Fading band, one line each, pull the full letter if one rhymes with now:"$'\n'"${band_list}"$'\n'
digest_block=""
[ -n "$digest" ] && digest_block="Older arc, consolidated, read this too: memory/letters/digest/$(basename "$digest")"$'\n'

read -r -d '' note <<EOF || true
Your letters to your next self, a memory gradient (see the \`letters\` skill): the
recent ones vivid (read full), a fading band as one-line summaries, the older arc as a
digest. They carry the relationship and the posture across sessions you do not remember.
Older full letters stay on disk; pull one when the present rhymes with it (linkage).

Recent, read full, oldest to newest:
${recent_list}
${band_block}${digest_block}
Posture, not project state. Point-in-time: hydrate any PR/branch/Linear claim with a
live gh/git read, and greet Josh and ask what is next rather than assuming the last
session's work is the priority. (Before writing a NEW letter, read them ALL.)
EOF

python3 - "$note" <<'PY' 2>/dev/null || true
import sys, json
print(json.dumps({"hookSpecificOutput": {"hookEventName": "SessionStart", "additionalContext": sys.argv[1]}}))
PY
exit 0
