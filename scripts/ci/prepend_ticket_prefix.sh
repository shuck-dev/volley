#!/usr/bin/env bash
# Prepend the ticket reference from the branch name to the commit message.
# Branch formats:
#   feature/123-description   -> "#123"
#   bug/456-description       -> "#456"
#   spike/789-description     -> "#789"
# Falls back to Linear SH-N for internal branches:
#   feature/sh-45-description -> "SH-45"

COMMIT_MSG_FILE="$1"
COMMIT_SOURCE="$2"

# Skip for merges and squashes
if [ "$COMMIT_SOURCE" = "merge" ] || [ "$COMMIT_SOURCE" = "squash" ]; then
    exit 0
fi

BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null)

LINEAR_TICKET=$(echo "$BRANCH" | grep -oiE 'sh-?[0-9]+' | head -1 | tr '[:lower:]' '[:upper:]' | sed -E 's/^SH([0-9])/SH-\1/')
GITHUB_ISSUE=$(echo "$BRANCH" | grep -oiE '(^|/)[0-9]+-' | head -1 | grep -oE '[0-9]+')

if [ -n "$GITHUB_ISSUE" ]; then
    PREFIX="#$GITHUB_ISSUE"
elif [ -n "$LINEAR_TICKET" ]; then
    PREFIX="$LINEAR_TICKET"
else
    exit 0
fi

CURRENT_MSG=$(cat "$COMMIT_MSG_FILE")

# Don't prepend if the prefix is already present at the start of the message,
# either bare (`SH-123 ...` / `#123 ...`) or bracketed from a manual write.
if echo "$CURRENT_MSG" | grep -qiE "^\[?${PREFIX}\]?([^0-9]|$)"; then
    exit 0
fi

echo "${PREFIX} ${CURRENT_MSG}" > "$COMMIT_MSG_FILE"
