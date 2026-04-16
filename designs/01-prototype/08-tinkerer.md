# The Tinkerer at Work

A character with a workbench. The player drops items off; the tinkerer works at their own pace; finished items land on a done tray. Destruction mechanics live here (narrative: `08-items.md`).

**Dependencies:** Venue (`08-venue.md`), Items (`08-items.md`), ItemManager (`08-item-manager.md`).

---

## Scene

```
Workshop (child of venue.tscn, hidden until tinkerer unlocked)
├── TinkererCharacter      (root script runs the state machine)
├── Workbench              (current commission sits here while being worked on)
├── DoneTray               (finished commissions await pickup)
└── DropOffBasket          (where the player leaves items)
```

Gated by `&"tinkerer"` in `unlocked_characters`.

---

## State machine

| State | Progresses work? |
|---|---|
| `resting` | No; tea, staring out the window |
| `procrastinating` | No; reading, tidying, chatting |
| `working` | Yes; at the workbench |

Transitions are authored weighted durations, not player-triggered. State durations come from authored ranges; transition weights pick the next state.

```gdscript
@export var resting_range: Vector2 = Vector2(20, 60)
@export var procrastinating_range: Vector2 = Vector2(60, 300)
@export var working_range: Vector2 = Vector2(180, 900)
@export var weights_from_resting: Dictionary = { &"procrastinating": 0.7, &"working": 0.3 }
@export var weights_from_procrastinating: Dictionary = { &"working": 0.6, &"resting": 0.2, &"procrastinating": 0.2 }
@export var weights_from_working: Dictionary = { &"procrastinating": 0.5, &"resting": 0.5 }
```

Hot-reloadable. With an empty queue, the tinkerer still cycles; `working` becomes quiet bench-tidying.

---

## Work queue

```gdscript
class_name ItemCommission
extends RefCounted

var item_key: String
var kind: StringName           # &"level_up", &"destroy"
var work_required_seconds: float
var work_done_seconds: float   # accumulates only while working on this commission
var dropped_at_unix: int
```

Work progresses only while `working` and the commission is at the head of the queue. FIFO by `dropped_at_unix`. Complete when `work_done_seconds >= work_required_seconds`.

### Persistence

```gdscript
var tinkerer_queue: Array[Dictionary] = []
var tinkerer_current_state: StringName = &"resting"
var tinkerer_state_started_unix: int = 0
var tinkerer_state_duration_seconds: float = 0.0
```

On load: resume the state with remaining duration.

---

## Player flow

1. Player drags an item onto the drop-off basket (from `BallRack`, `GearRack`, or the court). `ItemCommission` enqueued.
2. Tinkerer rotates through states on their own.
3. On completion, the item lands on the done tray; a soft chime from the workshop side.
4. Player drags from the done tray: ball and equipment items to `BallRack`/`GearRack`, court items onto the court. `item_levels` updates at drop.

### Commission kinds

- **Level up:** `item_levels[item_key]` += 1. Ball and equipment items return inactive (to `BallRack` or `GearRack`); court items return to a free `Roles/Court` marker.
- **Destroy:** `item_levels[item_key] = 0`, append to `destroyed_items`, partial FP refund, any secret unlock enters the shop pool (see `04-upgrade-shop.md`). The tinkerer's dialogue holds its tongue on secret unlocks.

---

## Wall-clock catch-up

On resume: walk the state machine forward by the elapsed delta. For each `working` step on a head-of-queue commission, add its duration to `work_done_seconds`. Complete commissions that cross the threshold; advance the queue.

Cap at `tinkerer_offline_cap_seconds`. Fire `commission_completed` on scene ready for anything that finished offline so the done tray lights up at once.

Because work only progresses during `working`, wall-clock completion is always longer than `work_required_seconds`. A fast item might finish in ten minutes; a meaningful one might take a day.

---

## Not a shipment

The tinkerer works in view at the workshop. Shipments (see `08-shipments.md`) are the friend's delivery metaphor and stay single-purpose.

---

## Per-item work values

```gdscript
@export var tinker_level_seconds: float = 60.0
@export var tinker_destroy_seconds: float = 120.0
```

Overridable per item. Combined with the state-machine rhythm to produce the real wait.

---

## Audio and visual cues

- Working: quiet hammer/sand loop, fades in other states.
- Commission complete: soft chime from the workshop.
- Done tray: gentle pulse while unclaimed items sit on it.

All audio placeholder for prototype.

---

## Resolved questions

1. **Indicate the current commission.** The item sits on the workbench, inactive for the player. It is visible but not interactable until the commission completes.
2. **Queue capacity.** One commission at a time, possibly upgradeable later.
3. **Player can poke the tinkerer.** Yes: produces a sound effect and a small visual reaction. No gameplay effect.
4. **Procrastination spikes.** The tinkerer procrastinates more on items they do not want to work on, lengthening the real wait.
5. **Tinkerer mood affects output.** Alpha scope.

---

## Rough ticket outline

Not filing yet.

1. Workshop scene: workbench, done tray, drop-off basket, tinkerer.
2. Tinkerer unlock beat + gate + show/hide.
3. `TinkererCharacter` state machine.
4. `ItemCommission` + queue management.
5. Work-accumulator loop.
6. Done tray pickup gesture; `item_levels` / `destroyed_items` update.
7. Wall-clock catch-up.
8. `tinker_level_seconds` / `tinker_destroy_seconds` on `ItemDefinition`.
