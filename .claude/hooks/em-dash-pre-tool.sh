#!/usr/bin/env bash
# Block tool calls whose input contains U+2014 (em dash).
# Rule: ~/.claude/projects/-home-josh-gamedev-volley/memory/feedback_no_em_dashes.md
set -e

INPUT=$(cat)
TEXT=$(printf '%s' "$INPUT" | jq -r '.tool_input | tostring' 2>/dev/null || printf '%s' "$INPUT")

if printf '%s' "$TEXT" | grep -q $'\xe2\x80\x94'; then
  jq -n '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: "U+2014 (em dash) detected in tool input. The em dash is banned on every surface per feedback_no_em_dashes.md. Replace with a comma, semicolon, period, or parentheses, then retry."
    }
  }'
fi
exit 0
