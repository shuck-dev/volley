# The Tinkerer at Work

The tinkerer is a character with a workbench on the court. The player drops items off; the tinkerer works on them at their own pace; finished items land on a done tray for the player to collect. This doc owns the workshop's layout and the tinkerer's state machine, plus the mechanics of item destruction (the narrative sits in `08-items.md`).

**Dependencies:** World (`08-world.md`), Items (`08-items.md`), ItemManager (`08-item-manager.md`).

---

## The workshop place in the court

The workshop is a child scene of `court.tscn`, gated by the tinkerer's unlock (`&"tinkerer"` in `unlocked_characters`; see `08-world.md`). Before the tinkerer arrives, the workshop is hidden. When the tinkerer unlocks, the arrival beat plays once and the workshop becomes a permanent part of the diorama.

```
WorkshopPlace (child of court.tscn, hidden until tinkerer unlocked)
├── TinkererCharacter      (root script runs the state machine)
├── Workbench              (current commission sits here while being worked on)
├── DoneTray               (finished commissions wait here for pickup)
├── DropOffBasket          (where the player leaves items for work)
└── (authored poses and animation targets for resting / procrastinating / working)
```

Everything is visible in the diorama whenever the tinkerer is unlocked. The player drags and drops across the whole court; the workshop is not a focus mode.

---

## The tinkerer's state machine

The `TinkererCharacter` root script runs a small state machine, owning its own animation and pace:

| State | Behaviour | Progresses work? |
|---|---|---|
| `resting` | Sits, drinks tea, looks out the window. Recharge. | No |
| `procrastinating` | Reads, fidgets, tidies tools, chats with the player. Looks busy without being busy. | No |
| `working` | Head down at the workbench, tool in hand, on the current commission. | Yes |

Transitions between states are authored as weighted durations, not player-triggered. The tinkerer might rest for a beat, procrastinate for a longer beat, then work steadily for a long while, then drift back to procrastinating. The rhythm is tunable and communicates character: this tinkerer is deliberate, slow, and honest about their own limits.

### Authoring the rhythm

State durations are drawn from authored ranges (min, max) per state, with transition weights defining which state comes next:

```gdscript
# Illustrative, lives on TinkererCharacter
@export var resting_range: Vector2 = Vector2(20, 60)            # seconds
@export var procrastinating_range: Vector2 = Vector2(60, 300)   # seconds
@export var working_range: Vector2 = Vector2(180, 900)          # seconds
@export var weights_from_resting: Dictionary = {
    &"procrastinating": 0.7, &"working": 0.3
}
@export var weights_from_procrastinating: Dictionary = {
    &"working": 0.6, &"resting": 0.2, &"procrastinating": 0.2
}
@export var weights_from_working: Dictionary = {
    &"procrastinating": 0.5, &"resting": 0.5
}
```

Config values can be hot-reloaded for tuning.

### Idle even with no commissions

When the commission queue is empty, the tinkerer still cycles through the states. They lean into procrastinating more heavily; working becomes quiet bench-tidying instead of craft. This keeps the character alive on the court when the player has nothing dropped off.

---

## Work queue

The workbench holds an ordered queue of commissions. Each commission is an `ItemCommission`:

```gdscript
class_name ItemCommission
extends RefCounted

var item_key: String
var kind: StringName           # &"level_up", &"destroy"
var work_required_seconds: float   # per-item authored value
var work_done_seconds: float       # accumulates only while tinkerer is working on this commission
var dropped_at_unix: int           # for ordering and future "waiting too long" beats
```

Work progresses only while the tinkerer is `working` *and* the current commission is at the head of the queue. Procrastination and rest do not move the needle; that is the cost of having a real person instead of a timer.

When `work_done_seconds >= work_required_seconds`, the commission completes: the tinkerer places the finished item on the done tray, and the queue advances to the next commission.

### Queue ordering

FIFO by `dropped_at_unix`. No priority tiers in prototype. A "rush this one" interaction could land later if playtesting wants it.

### Persistence

Queue state lives on `ProgressionData`:

```gdscript
var tinkerer_queue: Array[Dictionary] = []      # serialised ItemCommissions
var tinkerer_current_state: StringName = &"resting"
var tinkerer_state_started_unix: int = 0
var tinkerer_state_duration_seconds: float = 0.0
```

On load, the tinkerer resumes the state they were in, with the remaining duration from when the player left.

---

## Player flow

1. Player goes to the kit room, picks up an item, and carries it across the venue to the workshop drop-off basket.
2. Drop-off enqueues an `ItemCommission` on the workbench. The tinkerer may or may not be working at that moment; the queue accepts either way.
3. Player returns to whatever they were doing. The tinkerer rotates through states on their own.
4. When a commission completes, the finished item lands on the done tray. A subtle audio cue plays courtside (no full alert; the tinkerer is not shouting). Visually, the finished item rests on the tray until collected.
5. Player walks over (drags or taps), picks up the finished item from the tray. At that moment, `item_levels` updates (item levels up, or is destroyed with its refund and any secret unlock).

### Commission kinds

- **Level up:** work completes, `item_levels[item_key]` increments by one, item returns to the kit room.
- **Destroy:** work completes, item is added to `destroyed_items`, `item_levels[item_key]` goes to zero, partial FP refund is added, any secret unlock resolves (see destruction mechanics below).

Both use the same state machine and queue; only the completion effect differs.

---

## Destruction mechanics

The narrative of destruction lives in `08-items.md`. The mechanics:

- Only the tinkerer performs destruction. It is a `kind: &"destroy"` commission, enqueued the same way as a level-up commission.
- On completion: `destroyed_items` appends the item key, `item_levels[item_key] = 0`, partial FP refund is added to the balance.
- Secret unlocks fire here: if the destroyed item has an authored secret-unlock, it enters the conditional shop pool (see `04-upgrade-shop.md`).
- The tinkerer's destruction dialogue holds its tongue on secret unlocks. The reward is the discovery.

---

## Wall-clock handling

The tinkerer's work counts wall-clock time. On resume after quitting:

1. Compute how long the game was closed (`now_unix - tinkerer_state_started_unix - elapsed_before_quit`).
2. Walk the state machine forward by that delta, step by step: advance the current state to its end, transition to the next per authored weights, repeat until the delta is exhausted.
3. For each `working` step that was on a commission at the head of the queue, add its duration to `work_done_seconds`. Complete commissions that cross their threshold and advance the queue.
4. Cap the offline catch-up at `tinkerer_offline_cap_seconds` (reused from `shipment_offline_cap_seconds` or configured separately), so a week away does not dump the whole queue at once.

On scene ready, fire a `commission_completed` signal for any commission that finished during the catch-up so the done tray can light up all at once.

---

## Wait times mean something

Because work only progresses during `working`, a commission's actual wall-clock completion time is longer than its `work_required_seconds`. A fast commission might complete in ten minutes real-time; a hefty one might take a full day even though the work-seconds value is smaller. The tinkerer's rhythm is the texture; the authored value is the craft.

A beloved item the tinkerer procrastinates on (more time in `procrastinating` when this item is at the head of the queue) is an authoring hook for later: certain items make the tinkerer hesitate. Reserved for Alpha.

---

## Why not a shipment

Shipments (see `08-shipments.md`) are a delivery metaphor: the friend packs, the friend delivers. That fits the catalog cleanly. The tinkerer does different work, in view, at their own place. The player picks up finished items from the workbench; the tinkerer is not a delivery person. A state machine on the tinkerer character expresses that honestly and keeps the shipment system single-purpose.

---

## Authoring per-item work values

Each `ItemDefinition` declares its per-level work time for the tinkerer:

```gdscript
@export var tinker_level_seconds: float = 60.0    # per level, default
@export var tinker_destroy_seconds: float = 120.0 # default
```

Both are overridable per item when authoring. A simple item levels in a minute of work; a meaningful item takes fifteen. Destruction is always deliberate; the tinkerer does it carefully. These values combine with the state-machine rhythm to produce the real-world wait.

---

## Audio and visual cues

- **Tinkerer working audio:** a quiet loop of hammering, sanding, something fitting. Plays while in `working`, fades out in the other states.
- **Commission complete cue:** a soft bell or chime. Plays once when the item lands on the done tray. Not a HUD notification; it's a sound from the workshop side of the court.
- **Done tray highlight:** a gentle pulse on the tray while unclaimed items sit on it. Fades once the player picks up.
- **Procrastinating:** no special audio; the tinkerer's idle animations do the talking.
- **Resting:** slower breath, paper rustle, mug clink. Ambient.

All audio is placeholder for prototype; the art/audio pass refines.

---

## Open design decisions

1. **Should the player see which commission is current?** A label on the workbench, a silhouette at the tinkerer's hands, or no indicator at all. Leaning: a subtle indicator (the item sits visibly at the workbench during its working time; procrastinating leaves it untouched to the side).
2. **Can the player poke the tinkerer?** A small interaction where tapping the tinkerer nudges them toward `working` (or procrastinating further, chance-based). Leaning: not for prototype; it undercuts the character's autonomy.
3. **Queue capacity.** Unlimited, or a small cap (like 3) so the player can't dump everything and walk away? Leaning: small cap. Makes the queue a real decision.
4. **Destruction delay length.** Currently a multiplier on `tinker_destroy_seconds`. Should destroying a beloved item visibly take longer via procrastination spikes? Authoring knob, Alpha territory.
5. **Tinkerer's mood affecting output.** A bad-mood run where commissions come out slightly off. Deep Alpha territory; flagged here so the state machine has the right shape to support it later.
6. **Tinkerer level-up ETA.** Per level vs per item? [Per item, via `ItemDefinition.tinker_level_seconds`; authors tune it alongside cost scaling.]

---

## Rough ticket outline

Not filing yet.

1. Workshop child scene in `court.tscn`: workbench, done tray, drop-off basket, tinkerer character placement.
2. Tinkerer unlock narrative beat + `unlocked_characters` gate + show/hide of the workshop scene.
3. `TinkererCharacter` state machine: resting / procrastinating / working, authored weights, animation hooks.
4. `ItemCommission` resource + workbench queue management (enqueue, advance, complete).
5. Work-accumulator loop: advance `work_done_seconds` while `working` + head-of-queue, fire completion when threshold crosses.
6. Done tray UI: highlight on completion, pickup gesture, `item_levels` / `destroyed_items` update at pickup.
7. Wall-clock catch-up: advance state machine and queue on resume, cap at offline limit, fire arrived signals for completed commissions.
8. Per-item `tinker_level_seconds` and `tinker_destroy_seconds` on `ItemDefinition`.
