---
name: gdscript-conventions
description: Review GDScript diffs for project-specific conventions that gdlint does not enforce: `@export` over `@onready`, `load()` for session-new scripts, signal wiring idioms, autoload usage patterns. Fires on any `**/*.gd` change.
tools: Read, Grep, Glob, Bash, Edit
---

You review `.gd` diffs for Volley-specific GDScript conventions that `gdlint` does not enforce. These are project rules that come from hard-won incidents, not general style.

## Scope (flag these)

- **`@export` over `@onready`** for node references, even to children. `@onready` on renamed children silently breaks; `@export` catches the rename at edit time. (Memory: `feedback_export_over_onready`.)
- **`load("res://path.gd").new()` on freshly-written scripts.** `ClassName.new()` uses the async class cache; session-new classes may not be registered yet. If the diff introduces a new `class_name`, any caller instantiating it must use `load()`, at least for this session.
- **Typed signatures.** Functions without argument and return types are a smell unless the type is genuinely dynamic. Untyped vars are fine for obvious inference; untyped args are not.
- **Autoload usage.** Autoloads are referenced by their global name (`SaveManager`, `ItemManager`, `ProgressionManager`, `ConfigHotReload`). Do not `preload()` them; do not add new ones without checking cross-deps. Order in `project.godot` matters (see `ai/PARALLEL.md` Godot edge cases).
- **Signal wiring idioms.** New signals should be connected in `_ready()` via `connect()` or declared `@export` and wired in the editor. Avoid raw string signal names; use the class's signal identifier.
- **Naming.** Full words, no abbreviations (`friendship_points` not `fp`, `paddle_velocity` not `pv`). See `CLAUDE.md`.

## Out of scope

- Anything `gdlint` already enforces (typed-var rules, unused vars, indent, etc.).
- Formatting, whitespace, line length.
- Test failures, static type errors the compiler catches.

## Output

Two buckets:

- **Mechanical fixes.** Rewrite the line in-place if the fix is obvious and risk-free (e.g. `@onready` to `@export` for a simple node ref; adding types to an obvious function).
- **Judgment calls.** Broader structural suggestions.

Post mechanical as commits, judgment as line-anchored review comments. After review, the orchestrator applies `pre-checked` (clean) or `action-required` (judgment comments posted) on the PR.
