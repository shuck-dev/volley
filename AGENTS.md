<!-- GODOTIQ RULES START -->
<!-- godotiq-rules-version: 0.4.0 -->
# Volley

A Godot game built with AI assistance. Uses opencode (the coding agent)
and GodotIQ (the Godot editor bridge).

Read ../volley-ai/MEMORY.md at boot. It maps the project memory: a graph
of rules, lessons, and design decisions. The "forest" is that memory tree;
the "trunks" are its six main branches (dev cycle, docs, business, game
design, AI personality, unsorted). Descend a trunk when its domain comes up.
The "letters" are session handoff notes. Read the most recent one first;
it knows where we left off.

## GodotIQ

Prefer GodotIQ tools over raw file reads. Do not read .tscn or .gd files
directly; use godotiq_file_context, scene_map, and script_ops instead.
Do not grep for signal connections; use signal_map and dependency_graph
to trace the complete graph in one call. Do not guess positions or scales;
use placement and suggest_scale.

Build 3D content in .tscn scene files, not in code. Use build_scene for
batch node creation (grid, scatter, line, nodes). One call per logical
group. Verify each phase with spatial_audit before moving on.

Always verify changes with evidence: check_errors for compilation,
validate for conventions, verify_project_runs for runtime health,
read_debug_console for runtime errors. Screenshots only for visual
changes. Do not repeat tool calls; keep results in context.

## Swarm and Battle

The "swarm" is the set of parallel AI sub-sessions ("minions") that review
code, run tests, or write features concurrently. A "battle" is dispatching
reviewers against a pull request.

After dispatching reviewers: end the turn. Minion reports arrive through
the session harness naturally; do not poll for progress.

A minion report that ends with no verdict section is the complete report.
The minion finished its session at that point. Carry that review surface
yourself instead of waiting.

Ground every claim about pull request state with a live `gh` query before
stating it. Never carry CI or review state from memory across turns.

Reviewers post findings as inline comments at the specific file:line,
grouped into one GitHub Review per reviewer (never the main PR thread).
Fix discovered issues, push, verify CI resolves, then post the synthesis
verdict: `gh workflow run bot-review.yml -f pr=N -f event=VERDICT`.

Re-battle (re-review) only when new code substantively changes the diff.
Once reviewers converge and are just spinning, the bottleneck is a decision,
not more review signal.
<!-- GODOTIQ RULES END -->
