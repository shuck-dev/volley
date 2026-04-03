#!/usr/bin/env bash
# Prepend the Linear ticket number from the branch name to the commit message.
# Branch format: feature/sh-45-description or sh-45-description

COMMIT_MSG_FILE="$1"
COMMIT_SOURCE="$2"

# Skip for merges and squashes
if [ "$COMMIT_SOURCE" = "merge" ] || [ "$COMMIT_SOURCE" = "squash" ]; then
    exit 0
fi

BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null)
TICKET=$(echo "$BRANCH" | grep -oiE '(sh-[0-9]+)' | head -1 | tr '[:lower:]' '[:upper:]')

if [ -z "$TICKET" ]; then
    exit 0
fi

CURRENT_MSG=$(cat "$COMMIT_MSG_FILE")

# Don't prepend if the ticket is already present
if echo "$CURRENT_MSG" | grep -qiE "^${TICKET}"; then
    exit 0
fi

echo "${TICKET} ${CURRENT_MSG}" > "$COMMIT_MSG_FILE"
