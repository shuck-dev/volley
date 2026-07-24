# Drag Controller: Autoload and Groups

Design for making `ItemDragController` a global service that finds its collaborators through groups, part of [SH-542](https://linear.app/shuck-games/issue/SH-542).

## The problem: the controller reaches out to everything, and holds it all

`ItemDragController` is the hub of item dragging. It talks to the racks, the ball reconciler, the timeout gate, the cursor overlay, and four kinds of drop target. Today it reaches every one of them through an `@export` NodePath wired in `court.tscn`: nine references, each a string in a scene file. It also keeps a hand-built list of drop targets, which those targets register into one by one.

Both halves are fragile. A NodePath string in a `.tscn` is invisible to grep and invisible to the IDE, so a rename or a move silently severs the link with no compile error. The registered list is worse: because a target has to find the controller and call `register_target` at the right moment, the wiring carries deferred calls, timing races between sibling `_ready` order, and null guards against a controller that has not joined its group yet. The bounds are hardcoded `Rect2` magic numbers because the controller constructs its targets by hand, so a designer cannot see or resize a drop region.

## The idea: a global controller that queries groups on demand, holding nothing

Two moves, and everything else follows.

**The controller becomes an autoload.** There is one drag controller for the whole game, every consumer reaches for the same one, and it coordinates dragging wherever a match is running. That is a service, so it lives as a service: a single autoload instance, globally reachable by name, with no NodePath wiring to reach it and no scene that owns its lifetime.

**Drop targets live in a `&"drop_targets"` group, and the controller queries it on release.** Instead of holding a registered list that targets push themselves into, the controller asks the tree for the current targets at the moment of a drag: `get_tree().get_nodes_in_group(&"drop_targets")`, sorted by each target's declared priority, first `can_accept` wins. The targets that exist are whatever the loaded scene contributes; when the venue unloads, its targets leave the group with it. Nothing is registered, nothing is held, nothing goes stale.

Holding nothing is what lets the controller be an autoload safely. An autoload persists across every scene, so a held reference to a scene node would dangle the moment that scene unloads. A controller that queries a group at use-time keeps no such reference: group membership already tracks whatever scene is loaded now.

## Target state

`ItemDragController` is an autoload with zero `@export` vars and no registered target list. Its collaborators resolve at use-time through groups: drop targets from `&"drop_targets"`, the reconciler from `&"ball_trackers"`, racks from `&"racks"`, the timeout gate and cursor overlay from their own groups. Each drop target is an `Area2D` scene node that declares a priority and reads its region from its own shape.

How each of today's nine exports resolves in the target state:

| Export | Resolves by |
| --- | --- |
| `rack`, `gear_rack` | `&"racks"` group, distinguished by `role`; method calls become signals |
| `rack_drop_target`, `gear_rack_drop_target` | a `RackDropTarget` in the `&"drop_targets"` group |
| `reconciler` | `&"ball_trackers"` group (already populated) |
| `timeout_controller` | new `&"timeout"` group |
| `cursor_overlay` | new `&"cursor_overlay"` group |
| `venue_bounds`, `court_bounds` | each target's own `Area2D` shape, replacing the `Rect2` numbers |

Each built-in drop target (`CourtDropTarget`, `VenueDropTarget`, `RackDropTarget`, `CharacterDropTarget`) is an `Area2D` scene node that joins `&"drop_targets"`, declares an `@export var priority: int`, and reads its region from its own shape. The base `DropTarget` extends `Area2D`, so a target is its own drop region rather than a `Node` pointing at a separate one. This is why the four targets converge on a single shape and why no `court_area` or `drop_area` NodePath survives.

Priority replaces registration order. Today a target's place in the accept walk is an emergent property of when it registered; a declared `priority` makes that order explicit and visible on the target itself, so a reader sees "rack before court before venue" in the data rather than inferring it from wiring timing.

## Scene changes

**`court.tscn`:** remove the `ItemDragController` node; the `CourtDropTarget` is itself an Area2D (`input_pickable = false`, RectangleShape2D 1600x720) that joins `&"drop_targets"`, sized where Court's players can see it.

**`venue.tscn`:** the `VenueDropTarget` Area2D (RectangleShape2D 2400x1440) lives here as its own drop region and joins `&"drop_targets"`. The controller no longer lives in any scene; it is an autoload.

**`project.godot`:** register `ItemDragController` as an autoload.

**`court.gd`:** reach the controller by its autoload name; keep the `set_character_drop_target()` wiring from `_ready()`, since that is a method call, not an export.

## What the refactor removes and keeps

Removed: every `@export` on `ItemDragController`; the `configure()` public API; `register_target()`, `unregister_target()`, and the `_targets` list; `_register_builtin_targets()` and its factory methods; the `Rect2` bounds on the controller and targets; the `drop_area` and `court_area` NodePaths.

Changed: `ItemDragController` becomes an autoload; `DropTarget` extends `Area2D`; drop targets join `&"drop_targets"` and carry a `priority`.

Kept: the accept walk (first `can_accept` wins), now over a sorted group query rather than a held list; group-based discovery, generalized to every collaborator. Tests place targets in the group and drive the controller through its public accept path, with nothing to mock.

## Delivery: outcome-oriented PR sequence

Five PRs carry this refactor, and each one closes a concern end to end rather than a layer of the stack. Production code, scenes, tests, and any consumer land together; the old surface for that concern is deleted in the same PR, so main never sits on a half-migrated seam.

**PR 1: targets carry themselves.** The four drop targets become scene nodes: each joins `&"drop_targets"`, declares its `priority`, and the controller finds them by querying that group and sorting, first `can_accept` wins. `register_target()`, `unregister_target()`, `_targets`, and the factory methods are gone. Court and Venue still carry their bounds as `Rect2` exports and the controller still lives in the scene; this PR changes only how targets are discovered. Closes the "drop targets live as scene nodes, not runtime-constructed" criterion on its own.

**PR 2: a drop target is its own Area2D.** `DropTarget` extends `Area2D` instead of `Node`, so every target owns its geometry directly rather than pointing at a separate area. This unifies the four targets on one shape and clears the base-class barrier that kept a target's script off an Area2D. `RackDropTarget`'s `drop_area` export and the shop target's constructed area collapse into the target node itself.

**PR 3: Rect2 bounds become editor zones.** With each target already an Area2D, `court_bounds` and `venue_bounds` stop being `Rect2` numbers and become the target's own `RectangleShape2D`, sized in the editor. `shop_item.gd`'s `venue_bounds` dependency is fixed here, since it reads the same shape.

**PR 4: the controller becomes an autoload.** `ItemDragController` moves out of the scene tree into `project.godot` as an autoload, and its remaining collaborators (`rack`, `gear_rack`, `reconciler`, `timeout_controller`, `cursor_overlay`) resolve through group lookups at use-time. `configure()` is deleted once nothing calls it. `shop_item.gd`'s reconciler dependency is fixed here for the same reason.

**PR 5: state-machine enum.** `IDLE` / `DRAGGING` / `PENDING_RELEASE` replace the scattered booleans that track gesture state by hand today.

PR 5 does not change the export count; that is already zero by the time it lands. It is folded into SH-542 as a deliberate scope choice: the exports and the gesture booleans live in the same file, under the same reviewer, and answer the same question of what state this class should stop carrying implicitly. Splitting the enum into its own ticket would mean touching `item_drag_controller.gd` an extra time for a change that belongs with the rest. Read the PR 5 inclusion as intentional, not as scope creep.
