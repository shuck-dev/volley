# Code style

Two kinds of comment do two different jobs in the codebase, and it helps to keep them apart.

## Inline comments explain why

An inline `#` comment says why the code is the way it is: the reason behind a choice that the code itself cannot show. Keep it to one line, and do not narrate what the line does; the code already says that. A comment that restates the statement below it is noise, and reviewers will ask for it to go.

```gdscript
# Peak entry still fires the legacy max-speed event Cadence latches on.
func _on_ball_peak_changed(in_peak: bool) -> void:
```

## Doc-comments describe the public API

A Godot `##` doc-comment documents the surface other code calls: the class, its public methods, its signals, its exported and public variables. These render as tooltips in the Godot editor and feed the generated class reference, so they describe what a thing is for the caller, not how it works inside.

```gdscript
## Spawns floating soul labels on each per-hit award.
class_name SoulFloatLayer
extends CanvasLayer

## Carries the screen anchor where the float should appear.
signal soul_earned(amount: int, anchor: Vector2)

## Vertical offset applied on top of the signal anchor.
@export var anchor_offset: Vector2 = Vector2(0.0, -40.0)
```

The tags worth reaching for: `@deprecated`, `@experimental`, `@tutorial`, and the `[member x]`, `[method x]`, `[signal x]` cross-references that link one symbol to another.

## Document as you go

New code gets `##` on its public surface, and edited code gains it on the parts you touch. There is no expectation to retrofit the whole tree at once; the coverage grows with the work.
