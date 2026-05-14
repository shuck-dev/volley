---
name: implementer-nits
description: Pre-push checklist for implementer agents. The mechanical rules reviewers used to flag round after round; consolidated here as one preloaded reference. Skim before declaring done.
---

# Implementer nits

Read this before pushing. Each rule names the do; the why links to the source.

## Comments

- `##` is Godot's documentation-comment syntax. Attach it to the declaration directly below (no blank line between), surfaces in the editor inspector and class reference. Volley keeps `##` to one line per declaration; multi-line blocks compress or move into a doc.
- `#` is a narrative inline comment. Default is none. A `#` earns its place only when both: (a) the information is truly inscrutable from the code itself, and (b) it is too implementation-focused for design, tech, or narrative docs to host. If both don't hold, drop it. Source: `ai/skills/minions/code-comments.md`.
- One line max for either kind. Multi-line blocks become a one-liner or move into a doc.
- A blank line precedes every comment, like any other block.
- File-path references inside comments are forbidden. No `designs/...md` pointers, no `.gd`/`.tscn`/`.tres` filenames; the reader finds the spec by name.
- Don't reference tasks, tickets, or callers in comments.

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

## Test output is clean

CI fails on **any** of these in the GUT output. The gate lives in `scripts/ci/run_gut.sh` and `.github/workflows/test.yml`:

- `WARNING:` / `ERROR:` / `SCRIPT ERROR:` / `USER WARNING:` / `USER ERROR:` lines (Godot's `push_warning` / `push_error`, addon noise, `ObjectDB instances leaked at exit`).
- Per-test orphan counts > 0 (yellow `N Orphans` lines after each test method).

What that means for the code:

- **Don't `push_warning` for a design-intended silent no-op.** If the contract is "refuse and stay quiet," the code must stay quiet. Use a return value or state flag the caller / test can assert on.
- **Don't `queue_free` a node you just `remove_child`'d** unless it has live consumers (`_process`, `_physics_process`, or pending signals). The idle-frame gap leaves it orphaned. Use `free()` when ownership is exclusive.
- **Don't `await get_tree().process_frame` inside `while is_inside_tree():` polling loops.** When the host is freed mid-await, the coroutine state survives. Use a signal (`get_tree().node_added`, a typed ready-signal on the producer) and disconnect in `_exit_tree`.
- **In test files, route every `Node.new()` / `add_child` / `PackedScene.instantiate()` through `autofree` / `add_child_autofree`** unless GUT already manages the host (e.g. doubles, which are auto-freed).

See `ai/scratchpads/gut-orphans-research.md` for the diagnostic recipe and Volley-specific suspect list.

## Blank-line spacing inside function bodies

- **One blank line before every `if` statement.** Exceptions: the first statement of a function body, and `elif`/`else` continuations. Applies whether the preceding statement is one line or many.
- One blank line after an early-return guard (`if cond: return`) before the main work begins.
- One blank line between logical clusters within a function body. Variable declarations, signal wiring, mutation, and cleanup are different clusters; visually separate them.
- One blank line after a multi-statement `if`/`for` block before the next statement, when the next statement is a new logical step rather than a continuation.
- gdformat preserves single blanks; it only collapses 2+ in a row. So advisory blanks survive lefthook.

Calibrating example, post-Josh-edit on `scripts/hud/dev_ball_state_panel.gd`:

```gdscript
func _on_ball_removed(ball: Ball) -> void:
    if not _rows.has(ball):
        return

    var row: Dictionary = _rows[ball]
    var label: Label = row["label"]

    if is_instance_valid(ball) and ball.play_state_changed.is_connected(row["callable"]):
        ball.play_state_changed.disconnect(row["callable"])

    if is_instance_valid(label):
        label.queue_free()

    _rows.erase(ball)
```

Four clusters: guard, var decls, signal disconnect, label free, dict erase. Each blank-separated.

## Eventually mechanical

The linter (SH-372) will mechanise the highest-frequency rules above so violations cannot ship. Until then, read this file before each push and run the checklist.
