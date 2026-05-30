#!/usr/bin/env bash
# Warn on creation of new Linear issues that may belong on an active PR.
# Rule: ~/.claude/projects/-home-josh-gamedev-volley/memory/feedback_continuous_refactoring.md
set -e

INPUT=$(cat)

# Only act when no `id` is present (creation, not update).
HAS_ID=$(printf '%s' "$INPUT" | jq -r '.tool_input.id // empty' 2>/dev/null)
if [ -n "$HAS_ID" ]; then
  exit 0
fi

# If we're on a feature branch (not main), filing a new issue is the danger zone:
# the work may be a follow-up that folds into the active PR per feedback_continuous_refactoring.
BRANCH=$(git -C /home/josh/gamedev/volley branch --show-current 2>/dev/null || echo "")
case "$BRANCH" in
  ""|main|master)
    exit 0
    ;;
esac

jq -n --arg branch "$BRANCH" '{
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    permissionDecision: "ask",
    permissionDecisionReason: ("Creating a new Linear issue while on feature branch " + $branch + ". If this work could fold into the active PR, retire it as in-flight cleanup per feedback_continuous_refactoring instead. Approve to proceed if genuinely standalone.")
  }
}'
exit 0
