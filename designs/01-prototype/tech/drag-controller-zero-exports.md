# Drag Controller: Zero Export Vars

Implementation spec for stripping every `@export` from `ItemDragController`, part of
[SH-542](https://linear.app/shuck-games/issue/SH-542).

## Current state

`ItemDragController` carries eleven `@export` references, all set via NodePath in `court.tscn`:

```
@export var rack: RackDisplay
@export var rack_drop_target: Area2D
@export var gear_rack: RackDisplay
@export var gear_rack_drop_target: Area2D
@export var timeout_controller: TimeoutController
@export var venue_bounds: Rect2
@export var court_bounds: Rect2
@export var reconciler: BallReconciler
@export var cursor_overlay: BallDropOverlay
```

These are the controller's runtime collaborators: rack for signal wiring and position
lookups, reconciler for ball lifecycle, timeout for rally gates. The Rect2 bounds drive
`CourtDropTarget` and `VenueDropTarget` projection checks. Every collaborator is wired by a
NodePath string in the scene file, invisible to grep, invisible to the IDE, breakable on
rename.

Drop targets (`CourtDropTarget`, `VenueDropTarget`, `RackDropTarget`, `CharacterDropTarget`)
are created by `_register_builtin_targets()` as plain Node children of the controller. They
cannot live as scene nodes because their dependencies (reconciler, item manager, world2d)
arrive through the controller's own exports.

## Target state

Zero `@export` vars on `ItemDragController`. Every collaborator resolves itself or
self-registers. The controller moves from Court child to Venue child since it handles drops
across the full venue.

## How each export disappears

### `rack` and `gear_rack`

The controller needs rack references for two things: connecting to `slot_pressed` signals,
and calling `get_slot_position_for()`, `hide_slot_for()`, `reveal_slot_for()`, and
`refresh()` on the rack during drag.

Signal connections move to the controller's `_ready()` via group lookup. Racks join
`&"racks"` group, distinguished by `role`:

```gdscript
for rack: RackDisplay in get_tree().get_nodes_in_group(&"racks"):
    rack.slot_pressed.connect(_on_rack_slot_pressed)
```

The `_on_rack_slot_pressed` handler already receives the rack's `role` implicitly: the
controller can read `rack.role` to know whether it is ball or gear.

Rack method calls (`hide_slot_for`, `reveal_slot_for`) are replaced by signal-driven
visibility. The rack listens to `pickup_started` and `drop_completed` on the controller and
manages its own hide/reveal. `get_slot_position_for` is called when the controller needs a
slot position during drag: the controller looks this up from the rack that emitted
`slot_pressed` (stored as `_origin_rack` during the grab).

`rack.refresh()` during grab is replaced by a `rack_slots_changed` signal the rack already
emits. The controller does not need to call refresh directly.

### `rack_drop_target` and `gear_rack_drop_target`

`RackDropTarget` becomes a self-registering scene node. It lives as a child of the rack,
finds the controller via `&"drag_controller"` group, and calls `register_target(self)` in
`_ready()`. The Area2D reference is an `@export` on the `RackDropTarget` itself, wired in
the rack scene. The controller never sees it.

### `reconciler`

`BallReconciler` is already in the `&"ball_trackers"` group. The controller finds it there:

```gdscript
reconciler = get_tree().get_first_node_in_group(&"ball_trackers")
```

### `timeout_controller`

Used only once, in `grab_equipped_from_character`, for `RallyGate.removal_allowed()`.
Resolved by a new `&"timeout"` group on `TimeoutController`, or by walking the Court scene.

### `cursor_overlay`

Used only once, in `_set_cursor_state`, to call `BallDropOverlay.update_state()`. Found by
a `&"cursor_overlay"` group on `BallDropOverlay`. One-shot lookup in `_ready()`.

### `venue_bounds` and `court_bounds`

Gone. Replaced by `Area2D` nodes on each drop target. `CourtDropTarget` holds an `@export
var court_area: Area2D` pointing at a `RectangleShape2D`-backed `Area2D` child of Court in
`court.tscn`. `VenueDropTarget` holds the same for venue. The existing Rect2 approach
hardcoded magic numbers that missed venue edges and could not be visually adjusted. Area2D
is editor-visible, resizable, and matches the rest of the drop target pattern (rack drop
targets already use Area2D).

## Drop target self-registration

Every built-in drop target becomes a scene node that self-registers in `_ready()`:

```gdscript
# CourtDropTarget._ready():
var ctrl: ItemDragController = get_tree().get_first_node_in_group(&"drag_controller")
if ctrl != null:
    ctrl.register_target(self)
```

`CourtDropTarget`, `VenueDropTarget`, `RackDropTarget`, and `CharacterDropTarget` all follow
this pattern. `ShopDropTarget` already does it. `_register_builtin_targets()` is deleted.

Each drop target holds its own `@export` dependencies: `CourtDropTarget` exports
`reconciler`, `item_manager`, and `court_area`. `VenueDropTarget` exports the same plus
`venue_area`. `RackDropTarget` exports `item_manager` and `drop_area`. These are wired in
the scene where the target lives, visible and refactorable.

## Scene changes

**`court.tscn`:**
- Remove `ItemDragController` node.
- Add `CourtDropZone` (Area2D, `input_pickable = false`, RectangleShape2D 1600x720) as
  child of Court.

**`venue.tscn`:**
- Add `ItemDragController` as direct child of Venue.
- Add `VenueDropZone` (Area2D, `input_pickable = false`, RectangleShape2D 2400x1440) as
  child of Venue.

**`court.gd`:**
- Replace `@export var drag_controller: ItemDragController` with group lookup.
- Wire `set_character_drop_target()` from `_ready()` as before (that is a method call, not
  an export).

**`item_drag_controller.gd`:**
- Remove all `@export var` declarations.
- Add group-based collaborator lookups in `_ready()`.
- Delete `_register_builtin_targets()`.
- Delete `configure()`.
- Delete `_make_court_target()`, `_make_venue_target()`, `_make_rack_target()`.

## Removes

- All `@export` vars from `ItemDragController`.
- `configure()` public API.
- `_register_builtin_targets()` and its three factory methods.
- `venue_bounds: Rect2` and `court_bounds: Rect2` from `ItemDragController`,
  `CourtDropTarget`, and `VenueDropTarget`.

## Preserves

- `register_target()` and `unregister_target()` on the controller.
- Group-based discovery of controller from consumers.
- All drag controller tests pass without calling `configure()`. Tests wire targets by
  calling `register_target()` directly, a pure API with no exports to mock.

## Delivery: outcome-oriented PR sequence

Four PRs carry this refactor, and each one closes a concern end to end rather than a layer
of the stack. Production code, scenes, tests, and any consumer land together; the old
surface for that concern is deleted in the same PR, so main never sits on a half-migrated
seam.

**PR 1: drop targets self-register.** `CourtDropTarget`, `VenueDropTarget`, `RackDropTarget`,
and `CharacterDropTarget` become scene nodes that register themselves with the controller on
`_ready()`. `_register_builtin_targets()` and its three factory methods are gone. Bounds and
collaborator wiring stay on whatever mechanism they use today; this PR only moves *where*
the targets live, not *how* they resolve their dependencies. Closes the "drop targets live
as scene nodes, not runtime-constructed" acceptance criterion on its own.

**PR 2: Rect2 bounds become Area2D drop zones.** `court_bounds` and `venue_bounds` stop
being hardcoded rectangles and become `Area2D` nodes a designer can see and resize in the
editor. `shop_item.gd`'s `venue_bounds` fix rides along since it depends on the same zone.

**PR 3: collaborators resolve by group, the controller moves under Venue.** `rack`,
`gear_rack`, `reconciler`, `timeout_controller`, and `cursor_overlay` stop being NodePath
exports and start resolving through group lookups in `_ready()`. The controller becomes a
child of Venue instead of Court, since its job (routing a drag to whichever target accepts
it) spans the whole venue, not just the court. `configure()` is deleted once nothing calls
it anymore. `shop_item.gd`'s reconciler fix rides along for the same reason as PR 2's.

**PR 4: state-machine enum.** `IDLE` / `DRAGGING` / `PENDING_RELEASE` replace the scattered
booleans (`_mouse_button_down`, `_release_pending`, `_gesture_below_threshold`) that
currently track gesture state by hand.

PR 4 is not a zero-export change; the export count is already at zero by the time it lands.
It is folded into SH-542 anyway, as a deliberate scope choice: the exports and the gesture
booleans are the same file, the same reviewer, and the same mental model of "state this
class shouldn't be carrying implicitly." Splitting the enum work into its own ticket would
mean touching `item_drag_controller.gd` a fifth time for a change that belongs with the
other three. A future reader of this doc should take the PR 4 inclusion as intentional, not
as scope creep that slipped past review.
