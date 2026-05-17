# Ball State Ownership Spike

## Decision

`ItemManager._set_item_placement` is the canonical owner of role state for every owned item. `Ball.play_state` becomes the physics presentation of the ball-role placement, kept in sync by `BallReconciler` listening to `item_placement_changed`. Equipment-role items already have no `Ball`; ItemManager already owns their placement; pinning the same owner for balls removes the drift without inventing a third state machine.

## Surfaces today

Two state fields describe ball role:

- `Ball.play_state` (`scripts/entities/ball/ball.gd:36`): taxonomy canonical in `02-ball-lifecycle.md`. Funnelled through `set_play_state`; `enter_*` helpers flip physics flags and call the funnel.
- `ItemManager.state.item_placements` (`scripts/items/item_manager.gd:335`, via `_set_item_placement`): `STORED`, `EQUIPPED`, `ON_COURT`, with a `LOOSE_IN_VENUE` overlay in `state.loose_in_venue`. Persisted in `ItemState`.

Both fields carry an idea of "where this ball is in the run." They are written from different call sites and rarely cross-check each other. Concrete drift surfaces:

- `BallDragController.enter_out_held` (`ball_drag_controller.gd:228`, `:293`) sets `play_state = OUT_HELD` without touching `item_placements`; the placement still reads `ON_COURT` (or whatever it was). The `LOOSE_IN_VENUE` overlay only fires when the gesture actually deposits the ball on the floor (`:361`, `:511`).
- `ItemManager._set_item_placement` emits `court_changed`; `BallReconciler._on_court_changed` calls `enter_stored` on deactivate, but a `LOOSE_IN_VENUE` write does not change `play_state` at all; the ball is still whatever the drag controller most recently set.
- Save-restore reads `ball_play_states` (from `Ball.play_state`) and `item_placements` independently; nothing reconciles them on load.

`BallReconciler._balls_by_key` is the third surface and stays as-is; see `02-ball-lifecycle.md` and memory `project_ball_tracker_membership_is_existence`.

## Options considered

### A. ItemManager canon, Ball mirrors (chosen)

`item_placements` is the source of truth for role. `Ball.play_state` becomes a derived view: ball reads its placement on transition and applies the matching physics config. `BallReconciler` listens to `item_placement_changed` and routes through `Ball.enter_*` helpers for the cases that need a Ball.

Pros:

- Equipment items already live here; one owner across all roles.
- `item_placement_changed` is the broadcast every UI consumer already wires up (rack display, equipped panel, speed bar, paddle stats).
- Save shape unchanged; `item_placements` was already persisted.
- Removes the need for `collect_ball_play_states` and the matching save field; a placement plus a `LOOSE_IN_VENUE` flag already encodes the same five states the ball needs (modulo `PLAY_NORMAL`/`PLAY_ARC`, see below).

Cons:

- `PLAY_NORMAL` vs `PLAY_ARC` is a physics detail not in `Placement`. The split stays in `Ball`, derived from `global_position.y` and `friendship_bound_y`; not a role placement, not promoted to ItemManager.
- `OUT_HELD` is currently driven by the drag controller before any placement write happens; the controller must call `ItemManager.mark_loose_in_venue` (or a new `mark_held`) at gesture start, not only at gesture end.

### B. Ball canon, ItemManager projects

`Ball.play_state` is canon; ItemManager derives `item_placements` from a registry walk.

Pros:

- Physics flags and state already co-located in `Ball`.

Cons:

- Equipment has no Ball. Either equipment lives in a different ownership model (the drift we're trying to remove), or a phantom `Ball`-like state machine has to exist for equipment, which is worse than today.
- `item_placement_changed` would have to be re-derived and re-emitted from ball-side events, inverting the current signal wiring (every UI subscriber would re-wire).
- Save / load currently pulls placement from ItemState; flipping the source means a save-format change.

Rejected: equipment-role is the load-bearing case and Ball cannot own it.

### C. Third state machine owns it, both consume

New `ItemRoleStateMachine` autoload (or per-item state objects) that ItemManager and Ball both subscribe to.

Pros:

- Symmetric.

Cons:

- Net adds a third surface to the two we already disagree about. The dispatch's escalation rule names this as a "rename play_state AND _placement AND introduce a new owner" shape and tells us not to ship it as one spike. Skipped.

## Equipment-role handling

Equipment items have no `Ball` and never will. They live entirely in `item_placements`: `STORED` on the gear rack, `EQUIPPED` on the paddle. There is no `OUT_HELD`-equivalent equipment state today; the held-mid-drag regime in `22-equip-loop-regime.md` rejects-or-accepts at the drop target and never writes a "carried" placement.

Under the chosen owner, equipment continues to write through `_set_item_placement` exactly as today. The new contract for the rest of the codebase is "any role-state question goes to ItemManager." The split between `_set_item_placement` (immediate placement write) and `mark_loose_in_venue` (overlay flag) stays for ball-role only; equipment does not use the overlay.

If a future "equipment held mid-gesture" state is needed (e.g. a wrap visibly in the player's hand mid-swap), it lands as a sibling overlay on ItemManager, not on a phantom Ball.

## What `Ball.play_state` becomes

A presentation enum, not a role enum. Two responsibilities survive on it:

1. `PLAY_NORMAL` vs `PLAY_ARC` (the physics split below / above the friendship bound).
2. The integration-frame physics flags (`gravity_scale`, damping, freeze, miss-detection suppression) the `BallStateConfig` resources apply.

The role-level transitions (`STORED`, `OUT_REST`, `OUT_HELD`) collapse into: "Ball reacts to a placement change broadcast and runs the matching `enter_*` helper." `Ball.set_play_state` stops being a public funnel and becomes an internal step inside the helpers.

`collect_ball_play_states` and `ItemState.ball_play_states` retire; placement plus position is enough.

## Drift cases the new owner closes

- `OUT_HELD` no longer reads as `ON_COURT` in `item_placements`. The drag controller calls `mark_loose_in_venue` (or a renamed `mark_held`) at gesture start; the ball follows.
- Save-restore reads one source for role; `_apply_saved_play_state` collapses to a `placement -> enter_*` switch driven by ItemManager.
- `_on_court_changed` extends to cover every placement transition, not just on/off-court for ball-role items.

## Migration shape

The consolidation breaks into independent slices. Each holds against current main, and the order between them does not matter; later slices just see fewer redundant call sites.

The earliest move introduces a `HELD` overlay on ItemManager, sibling to `LOOSE_IN_VENUE`, with `mark_held` and `clear_held` entry points. The drag controller calls them at gesture start and release. Ball's `play_state` write stays where it is for this slice; ItemManager just gains the second source of truth, which closes the "`OUT_HELD` reads as `ON_COURT`" drift before any reader migrates.

A separate slice migrates the readers. BallReconciler subscribes to `item_placement_changed` and routes into `Ball.enter_*`, extending the existing `_on_court_changed` handler. Direct `enter_*` calls from the drag controller stay in place during this slice. Both paths converge on the same Ball, and `set_play_state` is idempotent enough to make the double-write safe.

The save shape collapses on its own. SaveManager stops pulling `ball_play_states`; `_apply_saved_play_state` reconstructs role from `item_placements` plus the `HELD` and `LOOSE_IN_VENUE` overlays. The save field either bumps per `03-save-versioning.md` or rides serialised-but-ignored until the next planned wipe.

The legacy write path and the legacy name retire together. The drag controller stops calling `enter_*` directly; the reconciler-driven route becomes the only writer of the Ball field, which lets `set_play_state` go private. The field renames `play_state -> physics_state` in the same change, and `02-ball-lifecycle.md` rewrites to match (prose to `HELD`, enum references to `physics_state`). All three moves close the same loop, so they belong together: the field stops being a role surface, and the doc stops naming the retired surface.

## Names

- **`Ball.play_state` becomes `Ball.physics_state`.** The residual job is `PLAY_NORMAL` vs `PLAY_ARC` plus the integration-frame physics flags; `physics_state` reads true to that job and stops the field from competing with `item_placements` as a role surface. The rename lands with the legacy-write-path retirement slice, once `set_play_state` goes private.
- **`HELD` is the canonical name for held-mid-gesture, on ItemManager.** `Ball.play_state = OUT_HELD` is the old name for the same state. The lifecycle doc Mermaid already uses `HELD`; this spike makes it the canonical noun and lands it on the canonical owner. The Ball enum value retires when `play_state` retires. `LOOSE_IN_VENUE` stays as its own overlay for floor-deposit.
- These names ride into the migration. Implementation work inherits them; it does not rename them.

## Out of scope

- `BallReconciler._balls_by_key` membership semantics. Already correct per memory `project_ball_tracker_membership_is_existence`.
