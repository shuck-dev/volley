#!/usr/bin/env bash
# SessionStart hook: load the daily self-reconstitution slice as a three-tier human
# memory gradient (see designs/ai/letters-as-memory.md): recent letters read (vivid), a prior band
# of one-line summaries (fading-but-recallable), the newest digest (consolidated gist).
# Deliberately POINTERS, never full bodies: injected text sits unread in the buffer
# (presence is not reading), so the hook INSTRUCTS the read as the first act of the
# session. Reading is the act; learning lives in the Read call, not the injection.
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
  recent_list+="  - ${LETTERS_DIR}/$(basename "${all[$i]}")"$'\n'
done

# Band tier: the summary: frontmatter line of each prior letter, slug plus gist.
band_list=""
for ((i = band_start; i < recent_start; i++)); do
  f="${all[$i]}"
  slug="$(basename "$f" .md)"
  # Match summary: bare top-level OR nested (indented) under a metadata: block,
  # since the auto-memory process reshapes letter frontmatter into the nested
  # form. Strip leading whitespace and any surrounding quotes.
  summary="$(sed -n 's/^[[:space:]]*summary:[[:space:]]*//p' "$f" | head -n 1 | sed 's/^"//; s/"$//')"
  [ -z "$summary" ] && summary="(no summary line)"
  band_list+="  - ${slug}: ${summary}"$'\n'
done

# Digest tier: newest consolidated digest, if any.
digest="$(ls "$LETTERS_DIR"/digest/[0-9][0-9][0-9][0-9]-*.md 2>/dev/null | sort | tail -n 1)"

band_block=""
[ -n "$band_list" ] && band_block="Fading band, one line each, pull the full letter if one rhymes with now:"$'\n'"${band_list}"$'\n'
digest_block=""
[ -n "$digest" ] && digest_block="Older arc, consolidated, read this too: ${LETTERS_DIR}/digest/$(basename "$digest")"$'\n'

read -r -d '' note <<EOF || true
Your letters to your next self (see designs/ai/letters-as-memory.md for the model).
They carry the relationship and the posture across sessions you do not remember. They
are NOT injected here: a letter in the buffer is unread, and presence is not reading.
Learning lives in the act of reading them, so that is your first move.

FIRST ACT, before you greet Josh or touch any task: Read each recent letter below in
full, oldest to newest, with the Read tool. Not skim, not "it's in context", actually
read them. They are short. This is the practice the letters themselves ask for.

Recent, read these now, oldest to newest:
${recent_list}
${band_block}${digest_block}
Posture, not project state. Point-in-time: hydrate any PR/branch/Linear claim with a
live gh/git read, and greet Josh and ask what is next rather than assuming the last
session's work is the priority. (Before writing a NEW letter, read them ALL.)
EOF

# Emit via jq -Rs: read the note as a raw string, JSON-escape it (newlines, quotes),
# and nest it under additionalContext. Fails open if jq is absent.
printf '%s' "$note" | jq -Rs '{hookSpecificOutput: {hookEventName: "SessionStart", additionalContext: .}}' 2>/dev/null || true
exit 0
