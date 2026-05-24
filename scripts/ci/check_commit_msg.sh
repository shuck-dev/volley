#!/usr/bin/env bash
# Validate commit message against Volley's bare-conventional-commits rule.
# See ~/.claude/projects/-home-josh-gamedev-volley/memory/feedback_commit_message_format.md
#
# Rules enforced:
#   - Subject is `type: subject` where type is one of
#     {fix, feat, chore, docs, refactor, test, style, perf, build, ci},
#     optionally with `!` for breaking changes.
#   - No scope parens: `fix(ci):` is rejected.
#   - No `SH-N` prefix in subject.
#   - No `[Codename]` suffix or `[Codename]` anywhere in subject.
#   - Total message length (all lines combined) must be under 400 chars.
#
# Skips merge commits, revert commits, and fixup/squash commits.

set -euo pipefail

msg_file="${1:?usage: check_commit_msg.sh <commit-msg-file>}"
[[ -f "$msg_file" ]] || { echo "check_commit_msg: file not found: $msg_file" >&2; exit 1; }

# Strip comment lines (lines starting with #) before counting and parsing.
msg_body=$(grep -v '^#' "$msg_file" || true)
[[ -z "$msg_body" ]] && exit 0

subject=$(printf '%s\n' "$msg_body" | head -n 1)

# Skip merge / revert / fixup / squash.
case "$subject" in
  "Merge "*|"Revert "*|"fixup! "*|"squash! "*|"amend! "*)
    exit 0
    ;;
esac

errors=()

# Total char count (under 400).
total_chars=$(printf '%s' "$msg_body" | wc -c)
if (( total_chars >= 400 )); then
  errors+=("total message length is ${total_chars} chars; must be under 400 (move detail to the PR description)")
fi

# Subject must be `type: subject` or `type!: subject` with type in the closed set.
valid_re='^(fix|feat|chore|docs|refactor|test|style|perf|build|ci)!?: .+$'
scope_re='^[a-z]+\([^)]+\)!?: .+$'
ticket_re='^[A-Z]+-[0-9]+'
codename_re='^\[[^]]+\]'

if ! [[ "$subject" =~ $valid_re ]]; then
  # Detect common slip patterns to give a useful error.
  if [[ "$subject" =~ $scope_re ]]; then
    errors+=("subject uses conventional-commits scope parens; strip them ('fix(ci):' becomes 'fix:')")
  elif [[ "$subject" =~ $ticket_re ]]; then
    errors+=("subject starts with a ticket prefix (SH-N or similar); strip it, Linear syncs via branch/PR")
  elif [[ "$subject" =~ $codename_re ]]; then
    errors+=("subject starts with a [Codename] prefix; move it to an 'Agent-Role:' trailer")
  else
    first_word=$(printf '%s' "$subject" | sed -E 's/^([^: ]+).*/\1/')
    errors+=("subject type '${first_word}' is not one of {fix, feat, chore, docs, refactor, test, style, perf, build, ci}; topic words go in the subject after the colon, not before it")
  fi
fi

# Codename in brackets anywhere in subject.
codename_anywhere_re='\[[A-Z][a-zA-Z]+\]'
if [[ "$subject" =~ $codename_anywhere_re ]]; then
  errors+=("subject contains a [Codename] tag; move it to an 'Agent-Role:' trailer")
fi

if (( ${#errors[@]} > 0 )); then
  echo >&2
  echo "commit-msg: rejected by Volley commit-format rule" >&2
  echo "  subject: ${subject}" >&2
  for e in "${errors[@]}"; do
    echo "  - ${e}" >&2
  done
  echo >&2
  echo "See ~/.claude/projects/-home-josh-gamedev-volley/memory/feedback_commit_message_format.md" >&2
  exit 1
fi

exit 0
