# Drag Controller: Scene Targets and Explicit State

Design for turning `ItemDragController`'s drop targets into scene nodes it discovers, and its gesture state into something named, part of #1075.

## The problem: targets are built and registered at runtime

`ItemDragController` is the hub of item dragging. It talks to the racks, the ball reconciler, the timeout gate, the cursor overlay, and four kinds of drop target. The first five are collaborators one scene owns and wires: one each, present for the controller's whole life. The drop targets are not. They are many, they vary by what is loaded, and the controller built them by hand and kept a list that each target pushed itself into.

That list is where the fragility sits. Because a target has to find the controller and call `register_target` at the right moment, the wiring carries deferred calls, timing races between sibling `_ready` order, and null guards against a controller that has not joined its group yet. The bounds are hardcoded `Rect2` magic numbers because the controller constructs its targets by hand, so a designer cannot see or resize a drop region. Gesture state is tracked in loose booleans that a caller has to set in the right order.

## The idea: targets are scene nodes, found by group at use-time

**Drop targets live in a `&"drop_targets"` group, and the controller queries it on release.** Instead of holding a registered list that targets push themselves into, the controller asks the tree for the current targets at the moment of a drag: `get_tree().get_nodes_in_group(&"drop_targets")`, keeping the lowest priority among those that accept. The targets that exist are whatever the loaded scene contributes; when the venue unloads, its targets leave the group with it. Nothing is registered, nothing is held, nothing goes stale.

Group discovery earns its place here because the set is open: a scene may contribute any number of targets, and which ones exist depends on what is loaded. The controller's other five collaborators are the opposite case, so they stay `@export`, wired in the scene that holds the controller, where the inspector shows the wiring, the type is checked, and an unfilled slot is visible before the game runs. Trading that for a group lookup would buy nothing and cost the editor feedback.

## Target state

`ItemDragController` has no registered target list and no `configure()`. It holds its five singular collaborators as `@export` references, and finds drop targets through the `&"drop_targets"` group at use-time. Each drop target is an `Area2D` scene node that declares a priority and reads its region from its own shape.

The controller lives in `venue.tscn` rather than `court.tscn`, because that is the scope it serves. A drag runs from the shop's shelf into the court, and the venue drop target covers ground the court does not, so a controller inside Court sits below half the things it coordinates. That is why the Shop reaches it through a `&"drag_controller"` group today: it cannot hold a NodePath into a sibling's subtree. At Venue level the controller is above every scene it serves, and ordinary wiring reaches it.

Venue is a `Node2D`. It is a 2D world holding a parallax background, the court, and the shop, and it was a `Control` only by inheritance from an earlier layout; a controller doing cursor math in a Control's transform chain is the same coordinate-space problem in milder form.

How each of today's nine exports resolves in the target state:

| Export | Resolves by |
| --- | --- |
| `rack`, `gear_rack` | unchanged: `@export`, rewired from `venue.tscn` |
| `reconciler`, `timeout_controller`, `cursor_overlay` | unchanged: `@export`, rewired from `venue.tscn` |
| `rack_drop_target`, `gear_rack_drop_target` | deleted; a `RackDropTarget` in the `&"drop_targets"` group |
| `venue_bounds`, `court_bounds` | deleted; each target reads its region from its own `Area2D` shape |

Each built-in drop target (`CourtDropTarget`, `VenueDropTarget`, `RackDropTarget`, `CharacterDropTarget`) is an `Area2D` scene node that joins `&"drop_targets"`, carries a priority, and reads its region from its own shape. The base `DropTarget` extends `Area2D`, so a target is its own drop region rather than a `Node` pointing at a separate one. This is why the four targets converge on a single shape and why no `court_area` or `drop_area` NodePath survives.

Priority replaces registration order. Today a target's place in the accept walk is an emergent property of when it registered; a declared priority makes that order explicit and visible on the target itself, so a reader sees the precedence in the data rather than inferring it from wiring timing. It is Area2D's own `priority` field rather than a new export, and the accept walk keeps the lowest value among the targets that accept, so specificity reads as ordering: character 0, shop 10, racks 20, court 30, venue 50. The catch-all sits last on purpose, since a venue that accepts anything anywhere would otherwise swallow every release before a narrower target is asked.

The character target needs more than the accept walk: the controller configures it with the paddle and timeout, wires its `equipped_art_pressed` signal, and toggles its equipped visuals during a drag. It reaches that one target through a `&"character_target"` sub-group, a `get_first_node_in_group` when the paddle spawns, replacing the `set_character_drop_target()` push and the `_character_target` handle the old registration kept.

## Scene changes

**`court.tscn`:** the `CourtDropTarget` is itself an Area2D (`input_pickable = false`, RectangleShape2D 1600x720) that joins `&"drop_targets"`, sized where Court's players can see it. The `ItemDragController` node moves out.

**`venue.tscn`:** the root becomes a `Node2D`. The `ItemDragController` lives here, keeping its `@export` wiring to the racks, reconciler, timeout gate and cursor overlay. The `VenueDropTarget` Area2D (RectangleShape2D 2400x1440) is its own drop region and joins `&"drop_targets"`.

**`court.gd`:** the paddle's character target joins `&"character_target"` itself, so Court no longer hand-wires it through `set_character_drop_target()`.

## What the refactor removes and keeps

Removed: the `configure()` public API; `register_target()`, `unregister_target()`, and the `_targets` list; `set_character_drop_target()` and the `_character_target` handle; `_register_builtin_targets()` and its factory methods; the drop-target and bounds exports on the controller; the `Rect2` bounds on the targets; the `drop_area` and `court_area` NodePaths; the release clamp that pulled an out-of-bounds shop drop back inside the venue.

Changed: `DropTarget` extends `Area2D`; drop targets join `&"drop_targets"` and carry a `priority`; the character target joins `&"character_target"`; gesture state becomes a named machine rather than loose booleans.

Kept: the accept walk, now over a group query rather than a held list; the controller's `@export` wiring to its five singular collaborators, which the Venue scene owns for the controller's whole life. Tests place targets in the group and drive the controller through its public accept path, with nothing to mock.

## Delivery: outcome-oriented PR sequence

Six PRs carry this refactor, and each one closes a concern end to end rather than a layer of the stack. Production code, scenes, tests, and any consumer land together; the old surface for that concern is deleted in the same PR, so main never sits on a half-migrated seam.

**PR 1: targets carry themselves.** The four drop targets become scene nodes: each joins `&"drop_targets"`, declares its `priority`, and the controller finds them by querying that group and sorting, first `can_accept` wins. The character target also joins `&"character_target"` so the controller reaches it for equipping without the old push. `register_target()`, `unregister_target()`, `_targets`, `set_character_drop_target()`, and the factory methods are gone. Court and Venue still carry their bounds as `Rect2` exports and the controller still sits inside `court.tscn`; this PR changes only how targets are discovered. Closes the "drop targets live as scene nodes, not runtime-constructed" criterion on its own.

**PR 2: a drop target is its own Area2D.** `DropTarget` extends `Area2D` instead of `Node`, so every target owns its geometry directly rather than pointing at a separate area. This unifies the four targets on one shape and clears the base-class barrier that kept a target's script off an Area2D. `RackDropTarget`'s `drop_area` export and the shop target's constructed area collapse into the target node itself.

**PR 3: Rect2 bounds become editor zones.** With each target already an Area2D, `court_bounds` and `venue_bounds` stop being `Rect2` numbers and become the target's own `RectangleShape2D`, sized in the editor. Every containment question routes through one `DropTarget.contains_point()` that asks the shape, so the rect-reconstruction helper and the per-target bounds checks collapse into it. `shop_item.gd` holds its own release path, so it checks containment itself rather than reading bounds off the controller. A release no target accepts is refused, leaving the item held until the cursor reaches somewhere valid, rather than being clamped to a position nothing agreed to.

**PR 4: the controller moves to Venue.** `venue.tscn`'s root becomes a `Node2D` and takes the `ItemDragController` node from `court.tscn`, with its exports rewired to reach the racks, reconciler, timeout gate and cursor overlay from their new relative position. Venue holds nothing Control-specific, so the root change is a node type and an `extends` line.

**PR 5: `configure()` goes.** The method exists so tests can push the collaborators the scene already wires, which means the production path and the test path set up the controller differently. Tests instantiate the controller and assign its exports directly, the same way the scene does, and `configure()` is deleted. `shop_item.gd` stops duck-typing `"reconciler" in controller` and reaches the reconciler through the `&"ball_trackers"` group it already joins.

**PR 6: state-machine enum, and gesture data in one place.** `IDLE` / `DRAGGING` / `PENDING_RELEASE` replace the scattered booleans that track gesture state by hand today, so `_gesture_below_threshold` stops being a flag a test has to reach in and set.

The cursor sampling moves with it. `_cursor_samples`, `_track_cursor_motion` and `_compute_release_velocity` are four private members implementing one idea, and they become a single gesture object the controller holds rather than state smeared across the class. That is what "gesture data is carried in one place" asks for; the enum alone answers what state a drag is in, not where its history lives.

The sampling stays. The release gesture is what lets a player aim a ball out of the rack: `ItemManager.get_default_ball_launch_velocity()` is a fixed diagonal, so a launch without gesture data departs along the same line at the same speed every time. Nothing branches on the velocity and every consumer only seeds a `RigidBody2D`, so the machinery invites deletion; what deletion costs is the aiming.

PR 6 does not change the export count; that is zero by the time it lands. It belongs to this refactor because the exports and the gesture state live in the same file and answer the same question of what state this class should stop carrying implicitly.
