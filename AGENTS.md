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

## Tooling

Prefer GodotIQ tools over raw file reads. Build 3D content in .tscn scene
files, not in code. Always verify changes with evidence (compilation checks,
convention validation, runtime health), not visual inspection alone.

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
