#!/usr/bin/env bash
# UserPromptSubmit hook: detects debrief / mission-close trigger phrases
# and injects a system reminder pointing at ai/skills/gru/debrief.md so
# the six-step flow runs instead of an inline orchestrator summary.
set -euo pipefail

prompt="$(jq -r '.prompt // empty')"
[[ -z "$prompt" ]] && exit 0

if printf '%s' "$prompt" | grep -qiE "(\\bdebrief\\b|mission complete|mission close|close[a-z' ]{0,14}mission|wrap.?up|\\bretro\\b|\\bpulse\\b|done with )"; then
  jq -n '{
    hookSpecificOutput: {
      hookEventName: "UserPromptSubmit",
      additionalContext: "Debrief / mission-close trigger detected. Read .claude/skills/debrief/SKILL.md before producing any wrap-up text. Six-step flow: (1) git status first, (2) dispatch three independent agents (cold-read, devils-advocate, CI miner), (3) fold their drafts, (4) post via mcp__linear__save_status_update on the relevant project, (5) route every action item Filed / Memory-only / Parked, (6) list every flag added or state none. Never the orchestrator inline summary."
    }
  }'
fi
exit 0
