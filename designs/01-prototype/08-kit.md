# The Kit Room and Passive FP

The kit is the at-rest store for every item not currently on the court. This doc owns the kit room's physical layout, the player's flow in and out of it, and the passive FP system: cadence, formula, offline catch-up, save throttling, and the signal/audio layer.

**Dependencies:** Items (`08-items.md`), ItemManager (`08-item-manager.md`), Roles (`08-roles.md`), World (`08-world.md`).

---

## The kit room

The `KitPlace` child scene of `court.tscn` is the gear room at the player's end of the venue. It is always present and always accessible. The player navigates to it the same way as the shop or workshop: by moving toward it, with the camera following within the scene. See `08-world.md` for the venue layout and framing.

### Physical layout

Three zones inside the kit room, each a distinct physical surface:

- **Ball rack:** ball items at rest (Training Ball, The Stray, etc.). A rack or low hopper holds them visibly when not in play on the court.
- **Gear area:** paddle and equipment items (Grip Tape, Cadence, Seven Years, The Call, Ankle Weights, etc.). Shelving or an open case keeps these legible at room scale.
- **Floor space:** larger props and court items when inactive (Spare cone, Dead Weight, etc.). These sit on the floor at their natural scale.

Items active on the court are not present in the kit room; they are at their court positions. Items in the kit room are those currently at rest.

### Player flow

The player enters the kit room by moving toward it. The rally stops on entry; the bot holds the court if active (see `08-bot.md`). Inside the room:

- **Kit → court:** the player picks up an item from its zone and carries it to the court. On arriving at the court with the item, `ItemManager.move_to_court(key)` fires; the item snaps to its authored role and the FP cost is charged.
- **Court → kit:** the player picks up an active item from its court position and carries it to the kit room. `ItemManager.move_to_kit(key)` fires on drop in the appropriate zone.
- **Role swap:** carrying a kit item to an occupied exclusive role on the court fires `ItemManager.swap_at_role(role, new_key)`; the previous occupant returns to the kit room.

### Cooldown and cost display

When the player picks up an item in the kit room intending to bring it to the court, the FP cost and any active role cooldown are shown on the carry preview. Role cooldown overlays appear on the relevant court-side role marker as the player approaches with the item.

---

## Passive FP: surface layer

All owned items generate FP passively while in the kit. Rate scales with item cost and level. Investing in an item makes it a better at-rest earner even if it never comes onto the court. Every purchase has value beyond its active effect, and the economy sustains itself when the loadout is locked in.

Your gear earns FP just by being yours. You packed it, you own it, you care for it. A well-stocked kit is a loadout that works for you even when it is at rest. The bench contributes.

Passive FP is communicated through sound, not visuals. Late game the kit can generate significant FP; visual pops would become noise. Instead: a gentle ambient audio texture that grows denser as the kit fills. Not louder, richer. Individual item ticks are near-subaudible. The overall feel is atmosphere rather than UI events.

---

## Passive FP: signal layer

The items are proxies for relationships. The FP from the kit is ambient warmth: the emotional residue of connection persisting through proximity and care. The player never needs to read this to understand the mechanic. It is for those paying attention.

The signal bleeds through in three places:

**Sound treatment.** Kit FP arrives differently from hit-earned FP. Hit FP pops. Kit FP glows. Different audio, different feeling. A player paying attention notices the game treats the two differently without being told why.

**Partners.** Partners are who the player is actually training with. They see the loadout. They notice what the player carries. Partner dialogue is where most of the kit signal layer lives: a partner recognising something in the kit, remarking on how much has accumulated over a long run together. Surface: they know your gear. Signal: they can see how much has been held onto and what it means. The Tinkerer and the friend carry their own weight elsewhere; the kit belongs to the partner relationships.

**The friend, once.** Late in pre-break, as the projection begins to lose coherence, the friend notices something in the kit. One line. "I saw you kept that. You don't have to use it." Surface: a friendly observation. Signal: the projection sees what the player is holding onto. After the break the player looks back and understands.

After The Break: the warmth from the kit was always real. It was the main character's memory of it, still generating something in the absence.

---

## Passive FP: implementation

### Cadence

`ItemManager._process(delta)` accumulates:

```
rate_per_second = sum over kit items of _kit_rate_for(item)
kit_accumulated_points += rate_per_second * delta
```

On each whole unit crossing (`floor(kit_accumulated_points) > last_committed_whole`) emit `kit_points_ticked(item_key, 1)` for the audio layer, and add 1 to the balance via `add_friendship_points`. The fractional remainder stays in `kit_accumulated_points`.

Per-item attribution for the tick is weighted by each item's contribution to `rate_per_second`: the item that tips the accumulator over each whole-unit crossing is picked weighted by rate. Weighted pick over exact attribution because the audio layer only needs a plausible source.

### Formula

Cost-weighted by default, with a per-item override:

```gdscript
# ItemDefinition
@export var kit_rate_override: float = 0.0  # FP per second; 0 means use default

# ItemManager (illustrative)
func _kit_rate_for(item: ItemDefinition) -> float:
    var level := get_level(item.key)
    if item.kit_rate_override > 0.0:
        return item.kit_rate_override * level
    return item.base_cost * level * kit_rate_coefficient
```

```
kit_rate_coefficient: float = 0.0005  # Default multiplier, config key
```

Investment in an item is the primary driver, with authoring room to set a specific item's rate when narrative weight diverges from cost.

### Offline / idle handling

On `_ready`, if `kit_last_tick_unix > 0` and the wall-clock gap is positive, compute the catch-up FP and award it as a single lump into `add_friendship_points`. Cap the gap at `kit_offline_cap_seconds` (default 8 hours) to avoid absurd payouts after a week away. The audio layer does not play catch-up ticks: it gets one "welcome back" cue from the UI layer instead.

`kit_last_tick_unix` is updated every save.

### Save frequency

Current `SaveManager.save()` is called on every balance change. With continuous kit ticks that becomes a per-second disk write. Gate it: kit-driven `add_friendship_points` calls skip the autosave, and a 30-second timer flushes the accumulated state. User-driven balance changes (purchases, court moves) save immediately as before.

---

## Testing

Unit-testable without a Viewport:

- Kit passive FP rate arithmetic (drive a fixed delta, assert accumulated points).
- Offline catch-up and the offline cap.
- Save throttling (kit ticks skip autosave; user-driven changes save immediately).

---

## Rough ticket outline

Not filing yet.

1. Kit room scene: ball rack, gear area, floor space, player navigation, carry-to-court interaction, cooldown and cost display.
2. Kit passive FP (cadence, formula, offline catch-up, save throttling).
3. Kit passive-FP audio layer (post-prototype polish).
