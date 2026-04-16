# The Kit

The kit is the at-rest store. Not one room: three areas (`BallRack`, `GearCase`, `Floor`) sit as siblings at the player's end of `court.tscn`. Together they are "the kit."

**Dependencies:** Items (`08-items.md`), ItemManager (`08-item-manager.md`), Roles (`08-roles.md`), World (`08-world.md`).

---

## Areas

- **Ball rack** — ball items at rest.
- **Gear case** — equipment (grip wraps, braces, ankle weights, charms, tools).
- **Floor** — larger court props (Spare cone, Dead Weight, bot dock when idle).

Items on the court are not present in the kit; items in the kit are at rest.

---

## Player flow

- **Kit → court:** pick up an item from its area, carry it to the court. `move_to_court(key)` fires on arrival; the FP cost is charged and the item snaps to its role.
- **Court → kit:** pick up an active item, carry it to the matching kit area (ball → rack, equipment → case, court prop → floor). `move_to_kit(key)` fires on drop.

The carry preview shows the FP cost and any role cooldown. Cooldown overlays appear on the target role marker as the player approaches.

---

## Passive FP

Every owned kit item generates FP over time. Rate scales with item cost and level. A well-stocked kit sustains the economy when the loadout is locked in.

**Signal layer** (the player never has to notice):

- **Partners.** Partner dialogue recognises what's in the kit — "you kept that?" — across long runs. The kit belongs to the partner relationships.
- **The friend, once.** Late in pre-break: one line. "I saw you kept that. You don't have to use it."

After The Break: the warmth from the kit was always real. The main character's memory still generating something in the absence.

---

## Implementation

### Cadence

```
rate_per_second = sum over kit items of _kit_rate_for(item)
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

---

## Rough ticket outline

Not filing yet.

1. Kit areas in `court.tscn`: ball rack, gear case, floor; navigation; carry-to-court; cooldown and cost display.
2. Passive FP (cadence, formula, offline catch-up, save throttling).
