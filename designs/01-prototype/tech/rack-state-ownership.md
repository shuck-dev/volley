# Rack State Ownership Spike

## Question

Make `ItemManager` the single source of rack/inventory state, with `BallReconciler` and `RackDisplay` deriving from it rather than keeping parallel copies synced by signal order. This is the architecture answer to the #735 bug family; the same single-owner thesis as `ball-state-ownership-spike.md`, applied to the rack.

## Surfaces today

Three owners hold overlapping rack state, kept in sync only by signals firing in the right order:

| Owner | State | Sync mechanism |
| --- | --- | --- |
| `ItemManager` | `item_placements`, `rack_slot_index_by_key`, `loose_in_venue` (authoritative, persisted in `ItemState`) | mutated directly |
| `BallReconciler` | `_balls_by_key` (does a Ball exist for this key) | listens to `court_changed`, `item_level_changed` |
| `RackDisplay` | `_hidden_key`, the built slot nodes (`_slots`) | listens to `item_level_changed`, `item_placement_changed`, `ball_spawned`, `ball_removed`; `hide`/`reveal` calls |

Nothing enforces agreement. When a mutation fires no signal, or fires one the consumer does not listen to, the copies drift from `ItemManager`'s truth.

## Divergence (the #735 family)

Each #735 symptom is a different un-emitted or unheard mutation:

- Ball shuffles slots, slot-2 unremovable, ghost ball: earlier manifestations.
- Slot-2 unclickable (2026-05-29): the slot-index mutators (`_assign_rack_slot`, `reassign_rack_slot`, `release_rack_slot`) mutated `rack_slot_index_by_key` silently, emitting nothing. `RackDisplay` never refreshed, so a ball with a valid slot index had no slot node and no `ClickArea`. Runtime-confirmed: `base_ball` at slot index 1 with `_slots` containing only `training_ball`; a manual `refresh()` rebuilt the missing slot.

Patched on #778 (SH-412) with a `rack_slots_changed` signal. That patch adds the one missing signal for that path; the architecture guarantees a next missing signal. The durable fix removes the possibility of divergence.

## To decide in the spike

- How `BallReconciler` and both racks (ball + gear) become read-only derivations of `ItemManager`, what independent state is removed.
- Pull (re-derive on render) vs one change-signal; signal-timing impact.
- Where `Shop` sits (it feeds the same drag/placement path).
- Save-shape impact (`item_state.gd`).
