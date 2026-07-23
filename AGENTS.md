# Volley

**Dispatch first. Plan, dispatch, review, synthesise. Code is minion work.
Never write game code from the main session. Switch to the Dispatch agent to
plan work; switch to Memory to edit memory.**

A Godot game built with AI assistance.

Read ../volley-ai/MEMORY.md at boot. It maps the project memory: a graph
of rules, lessons, and design decisions. The "forest" is that memory tree;
the "trunks" are its six main branches (dev cycle, docs, business, game
design, AI personality, unsorted). Descend a trunk when its domain comes up.
The "letters" are session handoff notes. Read the most recent one first;
it knows where we left off.

## Working in this codebase

GDScript conventions live in `CODE_STYLE.md`; read it before writing or
editing any `.gd` file. Test discipline and GUT usage live in
`tests/TESTING.md`; read it before writing or editing any test.

Scenes (`.tscn`) are the source of truth for game objects, terrain, and UI
layout. Prefer authoring or editing scene files directly over building
node trees at runtime in code; runtime `Node.new()` construction is for
genuinely dynamic pools (spawned balls, particles), not static world
content. A scene edit is a real change to a text-based `.tscn` file, so
review the diff the same way you would a `.gd` change.

After any code or scene change, run the project's GUT suite
(`./ci/run_gut.sh` or `godot --headless -s addons/gut/gut_cmdln.gd -gexit`)
and treat a green run as the correctness bar. A passing suite that covers
the change is the evidence; do not declare something done on the strength
of "it should work" alone.

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
