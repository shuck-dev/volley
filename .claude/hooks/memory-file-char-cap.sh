#!/usr/bin/env bash
# PreToolUse on Edit/Write: deny a memory-dir leaf .md file growing past the cap.
# Leaves are capped; MEMORY.md (generated index), letters/, and topic nodes (any node
# with children) are exempt. Grow-only: a shrinking edit always passes. Fails open.
set -uo pipefail

CAP=2000
MEMDIR="${MEMDIR_OVERRIDE:-${HOME}/.claude/projects/-home-josh-gamedev-volley/memory}"
MEMDIR="$(realpath "$MEMDIR" 2>/dev/null || echo "$MEMDIR")"
input="$(cat)"

# Pull the fields we need from the tool-input JSON. jq handles the JSON; bash does the rest.
path="$(printf '%s' "$input" | jq -r '.tool_input.file_path // ""' 2>/dev/null)" || exit 0
tool="$(printf '%s' "$input" | jq -r '.tool_name // ""' 2>/dev/null)"
[ -n "$path" ] || exit 0
rp="$(realpath "$path" 2>/dev/null || echo "$path")"

# only genuine children of the memory dir, .md files
case "$rp" in
  "$MEMDIR"/*.md) ;;
  *) exit 0 ;;
esac
# exempt the generated index, the handoff letters, and topic nodes (generated bodies)
base="$(basename "$rp")"
slug="${base%.md}"
[ "$base" = "MEMORY.md" ] && exit 0
case "$rp" in *"/letters/"*) exit 0 ;; esac
# a topic is any node a child points at via parent:; only leaves are capped
if grep -lqE "^[[:space:]]*parent:[[:space:]]*${slug}[[:space:]]*$" "$MEMDIR"/*.md 2>/dev/null; then
  exit 0
fi

# resulting size of the file after this Write/Edit, in CHARACTERS (wc -m), matching jq length
cur="$([ -f "$rp" ] && wc -m < "$rp" | tr -d ' ' || echo 0)"
if [ "$tool" = "Write" ]; then
  size="$(printf '%s' "$input" | jq -r '(.tool_input.content // "") | length' 2>/dev/null)"
elif [ "$tool" = "Edit" ]; then
  curtext="$([ -f "$rp" ] && cat "$rp" || echo "")"
  # do the replacement in jq on the indexed split (literal match), not sub/gsub (which are regex)
  size="$(jq -rn --arg cur "$curtext" --argjson ti "$(printf '%s' "$input" | jq '.tool_input')" '
    ($ti.old_string // "") as $old | ($ti.new_string // "") as $new |
    if $old == "" then ($cur | length)
    elif ($ti.replace_all // false) then (($cur | split($old) | join($new)) | length)
    else
      ($cur | index($old)) as $i |
      (if $i == null then $cur
       else ($cur[0:$i] + $new + $cur[($i + ($old|length)):]) end) | length
    end
  ' 2>/dev/null)"
else
  exit 0
fi
[ -n "$size" ] || exit 0

# Block only growth over cap. A smaller result always passes (shrinking is the fix).
if [ "$size" -gt "$CAP" ] && [ "$size" -ge "$cur" ]; then
  if [ "$cur" -gt "$CAP" ]; then
    reason="Memory file would be ${size} chars; the cap is ${CAP} and it is not getting smaller. Keep cutting until it is under ${CAP}."
  else
    reason="Memory file would be ${size} chars; the cap is ${CAP}. A leaf is one rule. Split it into two rules, or push doctrine into child nodes and leave a short index."
  fi
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"%s"}}\n' "$reason"
fi
exit 0
