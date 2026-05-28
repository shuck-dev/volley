#!/usr/bin/env bash
# Reject branch names that carry a Linear-style ID instead of the GitHub issue
# number. The repo convention is feature/<gh-number>-<slug>; Linear's
# gitBranchName field emits feature/sh-N-..., which must be overridden. A bare
# gh- prefix is also wrong (the number alone, no prefix).
#
# Reads the branch from $1 if given, otherwise the current HEAD. Used as a
# lefthook pre-push command.
set -euo pipefail

branch="${1:-$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")}"
[ -z "$branch" ] && exit 0
[ "$branch" = "HEAD" ] && exit 0

case "$branch" in
  feature/[Ss][Hh]-[0-9]*|feature/[Gg][Hh]-[0-9]*)
    echo >&2
    echo "branch-name: rejected '$branch'" >&2
    echo "  Use the GitHub issue number, not the Linear ID and not a gh- prefix:" >&2
    echo "    feature/<gh-number>-<slug>   e.g. feature/371-bot-synthesis-review" >&2
    echo "  Linear's gitBranchName emits feature/sh-N-...; override it." >&2
    echo >&2
    exit 1
    ;;
esac

exit 0
