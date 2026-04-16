# The Bot

A `court` item whose fixture is a paddle-driver. Takes over the court when the player goes idle.

**Dependencies:** Items (`08-items.md`), ItemManager (`08-item-manager.md`), Roles (`08-roles.md`), Fixtures (`08-fixtures.md`), Venue (`08-venue.md`), Shop (`08-shop.md`), Idle Play (`10-idle-play.md`).

---

## Role

The starting game ships bot-free. Idle play is covered by the generic default paddle from day one (see `10-idle-play.md`). Owning a bot upgrades idle: a second paddle with its own look, authored behaviour, scaling stats. First purchase is a narrative beat.

---

## Authoring

```
role = &"court"
effects = []
fixture = SubResource(BotFixture)

[sub_resource id="BotFixture" type="Resource" script=Fixture.gd]
prop_scene = ExtResource("res://scenes/fixtures/bot_dock.tscn")
dock_marker = &"BotDock"
```

A second bot variant is another `.tres` with a different prop scene or `BotBehaviour`.

---

## Lifecycle

Pure standard-item path:

- Order from the friend's catalog, ships, box lands on the shipment mat, `item_levels[bot_key] = 1`.
- Player drags the bot from the box directly onto the court. `activate(bot_key)` fires at the `court` role; `FixtureManager` spawns `bot_dock.tscn` at `BotDock`.
- Court items never leave the court except through the Tinkerer. Drag the bot to the workshop drop-off basket for level-up (returns to a court marker when done) or destruction (permanent removal).

The bot does not generate passive FP; only kit items do.

---

## When the bot plays

The dock prop (`bot_dock.tscn`) owns its active/parked state and listens to the idle-play signal (see `10-idle-play.md`).

- Player goes idle → bot takes over, prop spawns a driven paddle entity.
- Player reclaims control → bot parks, paddle entity frees.

---

## Handoff

Player paddle and bot paddle are two bodies; only one drives the ball at a time. The other sits in a resting pose.

- To bot: player paddle slides to a rest pose; bot rolls in. ~0.25s.
- From bot: inverse.

Both paddles are visible in their respective states. The animation lives on the dock prop.

---

## Stats

Standard `effects` array on the bot `.tres`:

| Stat | Effect | Level signal |
|---|---|---|
| `reach` | Court coverage | Wider |
| `response` | Reaction delay after direction change | Shorter |
| `anticipation` | How far ahead it reads the ball | Deeper |
| `endurance` | Accuracy drop over long rallies | Flatter |

The bot paddle entity reads stats via `ItemManager.get_stat`.

Per-bot tuning lives on a `BotBehaviour` resource on the prop scene's root (not on `Fixture`):

```gdscript
class_name BotBehaviour
extends Resource

@export var return_to_centre_bias: float = 0.5
@export var anticipation_depth: float = 0.3
@export var aggression: float = 0.5
@export var failure_mode: StringName = &"miss"
```

---

## Persistence

Nothing bot-specific at the item layer. `item_levels[bot_key]` holds the level. Active/parked state is transient, recomputed from the idle-play signal on scene ready.

A future `bot_manually_paused: bool` on `ProgressionData` would let the player disable the bot during play. Not in prototype.

---

## Open questions

1. **Bot paddle visible while the player plays?** Leaning off-scene.
2. **Bot-earned FP modifier?** Leaning 0.7x at level 1, parity at max.
3. **Endurance in prototype?** Leaning flat (schema ready for later).
4. **Multiple bots in Alpha?** Leaning one.

---

## Rough ticket outline

Not filing yet.

1. Bot `.tres` + `bot_dock.tscn` + one `BotBehaviour`.
2. Bot paddle entity.
3. Bot dock activate/park on idle-play signal.
4. Handoff animation.
5. Bot earnings modifier config (if open question 2 lands yes).
