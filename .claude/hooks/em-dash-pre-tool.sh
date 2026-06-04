#!/usr/bin/env bash
# Block tool calls whose input contains U+2014 (em dash).
# Rule: ~/.claude/projects/-home-josh-gamedev-volley/memory/feedback_no_em_dashes.md
#
# Bash is special: a command can legitimately CONTAIN an em dash as a search
# pattern (grep/sed/rg matching for it) without writing one anywhere. So for
# Bash, only scan commands that write prose to a permanent surface: a commit
# message, a PR body/title, or a redirect/heredoc into a text file. Every
# other tool (Edit, Write, the Linear and PR text tools) is scanned in full.
set -e

INPUT=$(cat)
EM=$'\xe2\x80\x94'

TOOL=$(printf '%s' "$INPUT" | jq -r '.tool_name // ""' 2>/dev/null || printf '')

if [ "$TOOL" = "Bash" ]; then
  CMD=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // ""' 2>/dev/null || printf '')
  # Prose-writing surfaces: commit messages (literal git, the gcmsg alias, and
  # the gc* conventional-commit function family in ~/.zshrc, each with a `!`
  # variant), PR create/edit, redirects or heredocs into a text file. Anything
  # else (grep/sed patterns, plain commands) is exempt even with an em dash.
  if printf '%s' "$CMD" | grep -qE '(^|[;&|[:space:]])(git commit|gcmsg|gc(f|x|d|h|r|t|i|st|pf|bd|v)!?)([[:space:]]|$)|gh pr (create|edit)|>>?[[:space:]]*[^[:space:]]*\.(md|txt|gd|tres|tscn|cfg|json|yml|yaml|sh)|<<'; then
    SCAN="$CMD"
  else
    exit 0
  fi
else
  SCAN=$(printf '%s' "$INPUT" | jq -r '.tool_input | tostring' 2>/dev/null || printf '%s' "$INPUT")
fi

if printf '%s' "$SCAN" | grep -q "$EM"; then
  jq -n '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: "U+2014 (em dash) detected in tool input. The em dash is banned on every surface per feedback_no_em_dashes.md. Replace with a comma, semicolon, period, or parentheses, then retry."
    }
  }'
fi
exit 0
