---
name: implementer-nits
description: Pre-push checklist for implementer agents. The mechanical rules reviewers used to flag round after round; consolidated here as one preloaded reference. Skim before declaring done.
---

# Implementer nits

Read this before pushing. Each rule names the do; the why links to the source.

## Comments

- One line max. Multi-line `#` blocks become a one-liner or move into a doc.
- WHY-only. Don't narrate what well-named code already says, don't reference the current task or callers. Source: `ai/skills/minions/code-comments.md`.
- Multi-line `##` docstrings on functions and headers are forbidden. One line.

## Variables and naming

- Full-word names. No `cfg`, `mgr`, `pos_x` shorthand.
- No single-letter variables. Exception: `_i`, `_j` for unused loop discards.
- Unused loop variables use the `_i` convention.

## Resources

- Every `.tres` file declares `uid="uid://…"` at the top.
- Every `[ext_resource type="Script" ...]` line in a `.tres` or `.tscn` carries `uid=`. Survives renames.
- Resource subclass over loose `@export` when 3+ tunables thematically cluster. Source: `feedback_resource_over_loose_exports`.

## Class-name async cache

- For a `class_name X` added in the current session: use `load("res://path/to/x.gd").new()` rather than `X.new()`. The class-name cache updates async; the load form bypasses. Source: CLAUDE.md "Known quirks."

## Exports

- `@export` over `@onready` for child node references. Source: `feedback_export_over_onready`.

## Tests

- Player-observable assertions over implementation details. Don't assert internal flag values when an external behaviour proves the same thing. Source: `feedback_test_behaviour`.
- Run `./scripts/ci/run_gut.sh` before declaring done.

## Eventually mechanical

The linter (SH-372) will mechanise the highest-frequency rules above so violations cannot ship. Until then, read this file before each push and run the checklist.
