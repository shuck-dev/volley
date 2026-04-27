#!/usr/bin/env bash
# PreToolUse hook on Agent: prompts when subagent_type is general-purpose.
# Volley convention: specialist-first dispatch. If no specialist fits, raise
# the gap and propose a new agent rather than defaulting.
set -euo pipefail

subagent_type="$(jq -r '.tool_input.subagent_type // "general-purpose"')"

if [[ "$subagent_type" == "general-purpose" ]]; then
  jq -n '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "ask",
      permissionDecisionReason: "general-purpose dispatch detected. Volley convention is specialist-first. Available specialists include signals-lifecycle, test-author, code-quality, gdscript-conventions, godot-scene, save-format-warden, root-cause-analyst, runtime-verifier, refactor-planner, devils-advocate, integration-scenario-author, pr-describer, ticket-writer, docs-tender. If no specialist fits, raise the gap to Josh and propose a new agent rather than defaulting to general-purpose."
    }
  }'
fi
exit 0
