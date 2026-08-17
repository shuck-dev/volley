#!/usr/bin/env bash
# Validate commit message against Volley's DCO requirement.
#
# Rules enforced:
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
