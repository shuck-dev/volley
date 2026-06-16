# Rack State Ownership Spike

## Question

Make `ItemManager` the single source of rack/inventory state, with `BallReconciler` and `RackDisplay` deriving from it rather than keeping parallel copies synced by signal order. This is the architecture answer to the #735 bug family; the same single-owner thesis as `ball-state-ownership-spike.md`, applied to the rack.

## Surfaces today

Three owners hold overlapping rack state, kept in sync only by signals firing in the right order:

| Owner | State | Sync mechanism |
| --- | --- | --- |
| `ItemManager` | `item_placements`, `rack_slot_index_by_key`, `loose_in_venue` (authoritative, persisted in `ItemState`) | mutated directly |
| `BallReconciler` | `_balls_by_key` (does a Ball exist for this key) | listens to `court_changed`, `item_level_changed` |
| `RackDisplay` | `_hidden_key`, the built slot nodes (`_slots`) | listens to `item_level_changed`, `item_placement_changed`, `ball_spawned`, `ball_removed` |

Nothing enforces agreement. When a mutation fires no signal, or fires one the consumer does not listen to, the copies drift from `ItemManager`'s truth.

ItemDragController reads from and writes through ItemManager directly. It keeps only transient gesture state (`_press_position`, `_pressed_on_rack`, `_moved_since_press`, `_held_slot_key`). This is healthy and needs no change.

18 signals fire across 4 owners: ItemManager emits 6, BallReconciler 8, RackDisplay 1, ItemDragController 3. All of RackDisplay's signal handlers call `refresh()`, which already rebuilds the entire slot tree from ItemManager state. The handlers are a relay layer; the real work is the pull.

## Divergence (the #735 family)

Each #735 symptom is a different un-emitted or unheard mutation:

- Ball shuffles slots, slot-2 unremovable, ghost ball: earlier manifestations.
- Slot-2 unclickable (2026-05-29): the slot-index mutators (`_assign_rack_slot`, `reassign_rack_slot`, `release_rack_slot`) mutated `rack_slot_index_by_key` silently, emitting nothing. `RackDisplay` never refreshed, so a ball with a valid slot index had no slot node and no `ClickArea`. Runtime-confirmed: `base_ball` at slot index 1 with `_slots` containing only `training_ball`; a manual `refresh()` rebuilt the missing slot.

Patched on #778 (SH-412) with a `rack_slots_changed` signal. That patch adds the one missing signal for that path; the architecture guarantees a next missing signal. The durable fix removes the possibility of divergence.

## Structural divergence points

Six divergence points remain, identified via full signal-path trace. Three are structural and will cause the next #735-class bug.

**Divergence A** -- `remove_level` (`item_manager.gd:367`): erases `rack_slot_index_by_key` without emitting any signal. The slot allocation disappears silently from RackDisplay and BallReconciler.

**Divergence B** -- `_set_item_placement` early return (`item_manager.gd:449`): slot bookkeeping (effect registration, rack slot assignment/release) runs unconditionally before the placement-identity check, but `item_placement_changed` only fires when placement actually changes. A no-op call that mutates the slot map or effect registrations is invisible to consumers.

**Divergence C** -- non-STORED branch (`item_manager.gd:443`): `_set_item_placement` does not clear `loose_in_venue` when activating an item into a non-STORED placement. The `bring_into_play` path can leave a stale overlay entry that makes `is_on_court` return false for an activated item.

**Divergence D** -- reconciler blind spot: BallReconciler listens to `court_changed` and `item_level_changed` but not `item_placement_changed`. Any placement change that does not cross the court boundary or change the item's level is invisible to `_balls_by_key`.

**Divergence E** -- CONNECT_DEFERRED on `rack_slots_changed` (`rack_display.gd:28`): one-frame window where slot indices (mutated synchronously) and slot nodes (rebuilt next frame) disagree. A click on the stale node during that frame sees the old slot map.

**Divergence F** -- cosmetic flicker on deferred rebuild: rebuilding one frame after the mutation causes a single-frame visual pop.

## Decision

Collapse the three overlapping change signals (`item_placement_changed`, `court_changed`, `rack_slots_changed`) into one `item_manager_state_changed`. Both consumers already do full rebuilds on every signal they receive; one signal per mutation batch is strictly less work and removes the ordering dependency.

BallReconciler switches from event-driven copying to reading ItemManager state directly: it holds no independent `_balls_by_key` and reads ball-to-existence directly from `ItemManager.item_placements` on each reconciliation pass. RackDisplay keeps `refresh()` but receives it from the single signal instead of five.

## Signal-timing impact

- **Before:** RackDisplay receives 5 signals from 3 emitters. If any signal fires out of order, the rack renders stale. If any path forgets to emit, the rack silently degrades.
- **After:** One signal fires after every batch of ItemManager mutations. RackDisplay calls `refresh()` once. Ordering is structural -- nothing to get wrong.
- **Deferred rebuild** (Divergence E): eliminated because `refresh()` is called synchronously from the single signal. The CONNECT_DEFERRED on `rack_slots_changed` is removed. A click on a stale Area2D in the same frame cannot happen because the signal fires after the mutation, not deferred to the next idle frame.

## Save-shape impact

No change. `ItemState` already persists `item_placements`, `rack_slot_index_by_key`, and `loose_in_venue`. BallReconciler's position provider (`collect_item_positions`) and play-state provider (`collect_ball_play_states`) inject into `ItemState` at save time. This pattern is orthogonal: BallReconciler owns the live Ball nodes and their runtime positions; ItemManager owns the inventory semantics. The derive-from-owner change is a runtime relationship, not a persistence change.

## Implementation split

1. **Collapse signals and fix divergences A-C.** Merge `item_placement_changed`, `court_changed`, and `rack_slots_changed` into `item_manager_state_changed`. Fix the three silent-mutation paths in ItemManager so every rack-state mutation emits the signal.

2. **Reconcile BallReconciler.** Replace `_balls_by_key` with a `reconcile()` method that reads `ItemManager.item_placements` directly. Remove `_on_court_changed` and `_on_item_level_changed` signal handlers. BallReconciler listens only to `item_manager_state_changed`.

3. **Single-source RackDisplay refresh.** Remove per-signal handlers (`_on_item_placement_changed`, `_on_rack_slots_changed`, `_on_item_level_changed`, `_on_ball_spawned`, `_on_ball_removed`). Connect `item_manager_state_changed` to `refresh()`. Remove CONNECT_DEFERRED.

Ticket order: (1) signals + divergences, (2) reconciler, (3) rack display. Each is independently shippable on trunk.
