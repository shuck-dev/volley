---
name: data-driven
description: Data-driven design policy every minion follows when writing tunable code. Anything affecting feel, balance, layout, or visual tuning is an `@export var`, not a `const`. Read before writing or editing any source file.
---

# Data-driven design

Tuning lives in data, not code. A value that affects how the game feels, balances, lays out, or looks belongs in the inspector so a designer can move it without a recompile and a code review. Code names the relationship; data fills it in.

## When to use `@export var` over `const`

Any value that affects feel, balance, layout, or visual tuning. Defaults stay at the const's old value, so promoting a const is a zero-behaviour-change move at the call site. The const becomes the default of the export.

If the value is a structural fact of the algorithm (array sizes derived from logic, mask bits, hard-coded enum-like keys), `const` is still right. The test is whether a designer could reasonably want to retune it.

## The ladder

- One tunable on its owning node: `@export var` on that node.
- Three or more knobs that move together: a `Resource` config (`BallDynamicsConfig`, `GrabFeelConfig`) exported as a single field. Co-tuned values stay together in the inspector and on disk.
- Per-item or per-instance variation: a field on the relevant `ItemDefinition` (or sibling definition resource), so authoring lives next to the item it tunes.

Climb the ladder when the next rung earns its weight. A second tunable on the same node does not need a Resource yet.

## `@export_range` for sensible bounds

When a value silently misbehaves outside a range (negative, sub-1.0, out-of-range), constrain the inspector. The bound is documentation a designer reads while tuning. Examples from PR #533 and PR #535: `expansion_ring_scale` (>= 1.0), `press_hitbox_inflation` (>= 1.0), `grab_ease_duration_s` (>= 0.0).

## Tests derive from the export, not the literal

A test that pins the old literal value re-pins it on every inspector tune:

```gdscript
# wrong: stale the moment the export moves
assert_almost_eq(press_circle.radius, 1.6 * 10.0)

# right: derives from the same source the production code reads
assert_almost_eq(press_circle.radius, _ball.press_hitbox_inflation * authored_radius)
```

The literal in the test is a magic number that lies. Read the export, multiply through, assert on the result.

## Why this rule keeps slipping

The implementer instinct is to write `const` first because it's faster and locally simpler. Pickle Jar (PR #533 SH-287, PR #535 SH-297) turned this finding up across `expansion_ring_scale`, `expansion_ring_duration_s`, `press_hitbox_inflation`, `grab_ease_duration_s`, `cursor_radius_px`, `ring_width_px`, and four cursor-state colours. Each one shipped as a const, was caught in review, and required a refine round to promote. Treat any new const that names a feel, balance, layout, or visual value as a code smell.

## What this skill replaces

Memory rule `feedback_data_driven_tuning.md`; this skill is the canonical version minions read before writing code.
