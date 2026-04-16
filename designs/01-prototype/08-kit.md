# The Kit

The kit is every item the player owns. This doc covers where inactive items sit, how the player moves items between inactive and active, and the passive FP they generate while inactive.

**Dependencies:** Items (`08-items.md`), ItemManager (`08-item-manager.md`), Roles (`08-roles.md`), Venue (`08-venue.md`).

---

## Storage for inactive items

Two areas sit as siblings at the player's end of `venue.tscn`. Each is both the parent for its items at rest and the drop target for deactivation.

- **BallRack**: inactive ball items. The court's ball manager reads from here.
- **GearRack**: inactive equipment. Items here are dragged onto the main character to equip.

Court items have no inactive state; they are always active on the court.

---

## Activate and deactivate

The player drives every transition by drag-and-drop. The gesture depends on the role.

### Ball (`BallRack` and court)

Live drag, rally keeps going:

- **Activate:** drag a ball from `BallRack` onto the court. Ball enters play immediately.
- **Deactivate:** drag a live ball off the court back onto `BallRack`. Ball leaves play.

### Court (always active)

No deactivation. On shipment arrival, the player drags the item from the box straight onto the court; it snaps to the next free `Roles/Court` marker. Removal is via the Tinkerer only (destroy or level-up; see `08-tinkerer.md`).

### Equipment (`GearRack` and main character)

Requires the main character to step off:

1. Player calls a timeout. Main character walks off the court to an authored equip pose. The rally plays out without a defender and ends on the next miss. (Later, if the bot is owned and active, it takes over the court via the standard idle-play handoff so the rally continues. Not in prototype scope until the bot ships.)
2. Player drags from `GearRack` onto the main character to equip, or from the character back to `GearRack` to deactivate.
3. Player ends the timeout. Main character walks back on and resumes play at the next serve.

### Drag preview

During any drag, the preview shows any active role cooldown. Cooldown overlays appear on the target surface (court for ball, court marker for court, main character for equipment). Activation has no FP cost; the animation beat on equip and the cooldown are the friction.

---

## Passive FP

Inactive items generate FP over time. Rate scales with item cost and level. A well-stocked set of inactive items sustains the economy when the loadout is locked in. Active items (including all court items) do not generate passive FP.

**Signal layer** (the player never has to notice):

- **Partners.** Partner dialogue recognises what's inactive in the kit ("you kept that?") across long runs. The inactive items belong to the partner relationships.
- **The friend, once.** Late in pre-break: one line. "I saw you kept that. You don't have to use it."

After The Break: the warmth was always real. The main character's memory still generating something in the absence.

---

## Implementation

### Cadence

```
rate_per_second = sum over inactive items of _kit_rate_for(item)
kit_accumulated_points += rate_per_second * delta
```

Each whole-unit crossing adds 1 to the balance via `add_friendship_points`. The fractional remainder stays in `kit_accumulated_points`.

### Formula

```gdscript
@export var kit_rate_override: float = 0.0  # FP/sec; 0 means use default

func _kit_rate_for(item: ItemDefinition) -> float:
    var level := get_level(item.key)
    if item.kit_rate_override > 0.0:
        return item.kit_rate_override * level
    return item.base_cost * level * kit_rate_coefficient
```

```
kit_rate_coefficient: float = 0.0005   # config key
```

### Offline catch-up

On `_ready`, if `kit_last_tick_unix > 0`, award `elapsed * rate` in a single lump. Cap at `kit_offline_cap_seconds` (default 8 hours). `kit_last_tick_unix` is updated on every save.

### Save throttling

Kit-driven `add_friendship_points` skips autosave; a 30-second timer flushes. User-driven balance changes save immediately.

---

## Testing

- Rate arithmetic (fixed delta, expected points).
- Offline catch-up and cap.
- Save throttling.
- Active items (including all court items) contribute zero.

---

## Rough ticket outline

Not filing yet.

1. `BallRack` and `GearRack` in `venue.tscn`; drag targets wired per role.
2. Timeout gesture: main character walks off on timeout call, back on at timeout end.
3. Passive FP (cadence, formula, offline catch-up, save throttling).
