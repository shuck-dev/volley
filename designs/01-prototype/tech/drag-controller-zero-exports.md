# Drag Controller: Zero Export Vars

Design for inverting how `ItemDragController` finds its collaborators, part of [SH-542](https://linear.app/shuck-games/issue/SH-542).

## The problem: the controller reaches out to everything

`ItemDragController` is the hub of item dragging. It talks to the racks, the ball reconciler, the timeout gate, the cursor overlay, and four kinds of drop target. Today it reaches every one of them through an `@export` NodePath wired in `court.tscn`: nine references, each a string in a scene file.

NodePath wiring is fragile in ways that do not show up until they break. A string in a `.tscn` is invisible to grep and invisible to the IDE, so a rename or a move silently severs the link with no compile error. Because the controller owns all these references, the drop targets cannot be scene nodes in their own right: they depend on the reconciler, the item manager, and the world, and the only place those arrive is the controller's exports. So the controller also constructs its drop targets by hand, which is why the court and venue bounds are hardcoded `Rect2` magic numbers rather than shapes a designer can see.

## The idea: collaborators find the controller, not the reverse

Invert the wiring. Instead of the controller holding a NodePath to each collaborator, each collaborator finds the controller (or is found) through a Godot group. The controller carries zero exports; discovery happens in `_ready()` by group lookup, or by the collaborator registering itself.

This is the same pattern the codebase already uses for `ShopDropTarget`, which self-registers, and for `BallReconciler`, which already lives in a group. The refactor generalizes it to the whole collaborator set.

Once nothing depends on the controller's exports, two things follow for free. Drop targets can live as ordinary scene nodes that register themselves, so a designer edits them in the scene where they belong. And the court and venue bounds become `Area2D` zones a designer can see and resize, instead of `Rect2` numbers that quietly missed the venue edges.

## Target state

Zero `@export` vars on `ItemDragController`. Every collaborator resolves through a group or registers itself. Each drop target is a scene node holding its own dependencies, wired in its own scene. The controller moves from a child of Court to a child of Venue, since routing a drag to whichever target accepts it spans the whole venue, not just the court.

How each of today's nine exports resolves in the target state:

| Export | Resolves by |
| --- | --- |
| `rack`, `gear_rack` | `&"racks"` group, distinguished by `role`; method calls become signals |
| `rack_drop_target`, `gear_rack_drop_target` | the `RackDropTarget` self-registers; controller never sees the Area2D |
| `reconciler` | `&"ball_trackers"` group (already populated) |
| `timeout_controller` | new `&"timeout"` group |
| `cursor_overlay` | new `&"cursor_overlay"` group |
| `venue_bounds`, `court_bounds` | `Area2D` zones the drop targets own, replacing the `Rect2` numbers |

Each built-in drop target (`CourtDropTarget`, `VenueDropTarget`, `RackDropTarget`, `CharacterDropTarget`) becomes a scene node that calls `register_target(self)` on the controller in its own `_ready()`, and holds its dependencies as its own exports wired in its scene. `_register_builtin_targets()` and the controller's factory methods are deleted.

## Scene changes

**`court.tscn`:** remove the `ItemDragController` node; add `CourtDropZone` (Area2D, `input_pickable = false`, RectangleShape2D 1600x720) as a child of Court.

**`venue.tscn`:** add `ItemDragController` as a direct child of Venue; add `VenueDropZone` (Area2D, RectangleShape2D 2400x1440) as a child of Venue.

**`court.gd`:** replace the `drag_controller` export with a group lookup; keep the `set_character_drop_target()` wiring from `_ready()`, since that is a method call, not an export.

## What the refactor removes and keeps

Removed: every `@export` on `ItemDragController`; the `configure()` public API; `_register_builtin_targets()` and its factory methods; the `Rect2` bounds on the controller and on the court and venue targets.

Kept: `register_target()` and `unregister_target()` as the controller's target-facing API; group-based discovery of the controller from its consumers. Tests wire targets through `register_target()` directly, a pure API with nothing to mock.

## Delivery: outcome-oriented PR sequence

Four PRs carry this refactor, and each one closes a concern end to end rather than a layer of the stack. Production code, scenes, tests, and any consumer land together; the old surface for that concern is deleted in the same PR, so main never sits on a half-migrated seam.

**PR 1: drop targets self-register.** The four drop targets become scene nodes that register themselves with the controller on `_ready()`; the factory methods are gone. Bounds and collaborator wiring stay on today's mechanism; this PR moves only *where* the targets live. Closes the "drop targets live as scene nodes, not runtime-constructed" criterion on its own.

**PR 2: Rect2 bounds become Area2D drop zones.** `court_bounds` and `venue_bounds` become `Area2D` nodes a designer can see and resize. `shop_item.gd`'s `venue_bounds` dependency is fixed here, since it reads the same zone.

**PR 3: collaborators resolve by group, the controller moves under Venue.** The remaining exports resolve through group lookups in `_ready()`, the controller becomes a child of Venue, and `configure()` is deleted once nothing calls it. `shop_item.gd`'s reconciler dependency is fixed here for the same reason.

**PR 4: state-machine enum.** `IDLE` / `DRAGGING` / `PENDING_RELEASE` replace the scattered booleans that track gesture state by hand today.

PR 4 does not change the export count; that is already zero by the time it lands. It is folded into SH-542 as a deliberate scope choice: the exports and the gesture booleans live in the same file, under the same reviewer, and answer the same question of what state this class should stop carrying implicitly. Splitting the enum into its own ticket would mean touching `item_drag_controller.gd` a fifth time for a change that belongs with the other three. Read the PR 4 inclusion as intentional, not as scope creep.
