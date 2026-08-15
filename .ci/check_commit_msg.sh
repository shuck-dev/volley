#!/usr/bin/env bash
# Validate commit message against Volley's bare-conventional-commits rule.
#
# Rules enforced:
#   - Subject is `type: subject` where type is one of
#     {fix, feat, chore, docs, refactor, test, style, perf, build, ci},
#     optionally with `!` for breaking changes.
#   - A `Signed-off-by:` trailer is present (DCO; commit with -s).
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

# Subject must be `type: subject` or `type!: subject` with type in the closed set.
valid_re='^(fix|feat|chore|docs|refactor|test|style|perf|build|ci)(\([^)]+\))?!?: .+$'

if ! [[ "$subject" =~ $valid_re ]]; then
  first_word=$(printf '%s' "$subject" | sed -E 's/^([^: (]+).*/\1/')
  errors+=("subject type '${first_word}' is not one of {fix, feat, chore, docs, refactor, test, style, perf, build, ci}; topic words go in the subject after the colon, not before it")
fi

# Signed-off-by trailer required (DCO). Catch a missing -s here, before CI rejects it.
if ! printf '%s\n' "$msg_body" | grep -qiE '^Signed-off-by: .+ <.+@.+>'; then
  errors+=("missing Signed-off-by trailer; commit with -s (DCO requires it on every commit)")
fi

if (( ${#errors[@]} > 0 )); then
  echo >&2
  echo "commit-msg: rejected by Volley commit-format rule" >&2
  echo "  subject: ${subject}" >&2
  for e in "${errors[@]}"; do
    echo "  - ${e}" >&2
  done
  echo >&2
  exit 1
fi

exit 0
