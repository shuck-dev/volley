---
name: bash-timeouts
description: Bash tool timeout budgets for volley. Read at brief-open before running any command.
---

# Bash timeouts in volley

Set the Bash tool's `timeout` parameter explicitly on every command. Defaults swallow 120 seconds of silent hang; pick a budget that surfaces a stall as a TIMEOUT you can act on.

## Budgets

- **Local git** (`status`, `log`, `checkout`, `branch -d`): 15000ms.
- **Remote git** (`pull`, `push`, `fetch`): 30000ms; 60000ms on a slow network.
- **`gh` API / PR ops**: 20000ms; 60000ms when polling for state change.
- **GUT suite, `godot --headless`, lint**: **3000ms**. Volley's full GUT run is ~2.5s. Anything past 3s is hung. Abort and investigate; do not bump the timeout and retry. The instinct that a Godot run "needs minutes" comes from heavier projects and does not apply here.
- **Builds, exports**: use `run_in_background: true`; do not block on them.
- **Interactive commands** (`gh auth login`, `gcloud auth login`): never run via Bash. Surface the `!` prefix to Josh.

## Anti-patterns

- Shell-wrapping with `timeout 60 ...` to "be safe". The Bash tool's `timeout` parameter is the right knob; a shell wrapper hides the signal.
- Bumping a timeout after it fires without checking why. A TIMEOUT in volley means something is wrong, not slow.
- Setting a long timeout "just in case". Long timeouts mask hangs and waste turns.

## When a timeout fires

Read the error. Identify the step that stalled. Cut the chain at that step, then either fix the underlying issue or change approach. Do not silently retry the same command with a higher timeout.
