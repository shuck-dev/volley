# The Bot

An item with `role = &"court_side"` and a fixture that is a paddle-driver: it takes over the court when the player goes idle (space-bar handoff). The bot rides on the standard item and fixture plumbing, so the whole system is one authored `.tres` plus one prop scene.

**Dependencies:** Items (`08-items.md`), ItemManager (`08-item-manager.md`), Roles (`08-roles.md`), Fixtures (`08-fixtures.md`), World (`08-world.md`), Shop (`08-shop.md`), Idle Play (`10-idle-play.md`).

---

## Role in the world

The bot is an upgrade the player earns. **The starting game ships bot-free by design.** Idle play is covered by the generic default paddle from day one, so the player always has a way to step back from the controls. Owning a bot is the moment idle play becomes *good*: a second paddle with its own look, authored behaviour, stats that scale with levels.

The first bot purchase is a narrative beat: where idle used to be a placeholder, now there is a paddle on the court with its own character. Upgrading the bot at the tinkerer continues that arc; each level sharpens how the bot plays in your absence.

Mechanically, owning a bot turns every idle moment into productive, character-rich play. The rally keeps going, FP keeps climbing, and the court feels inhabited even when the player is not driving.

---

## Authoring

The bot is an item with `role = &"court_side"` and a `fixture` pointing at the bot-dock prop scene. Minimal `.tres`:

```
role = &"court_side"
effects = []
fixture = SubResource(BotFixture)

[sub_resource id="BotFixture" type="Resource" script=Fixture.gd]
prop_scene = ExtResource("res://scenes/fixtures/bot_dock.tscn")
dock_marker = &"BotDock"
```

A second bot variant is a second `.tres` pointing at a different prop scene (visually distinct paddle, different behaviour profile) or the same prop with different `@export` values on its root.

---

## Lifecycle

Driven entirely by the standard item path. The bot is a catalog purchase at the shop; it arrives by shipment like any catalog item (see `08-shop.md`, `08-shipments.md`).

- Order the bot from the friend's catalog → the order ships → the box lands on the shipment mat → opening the box sets `item_levels[bot_key] = 1`; the player carries the bot into the kit room where it occupies a floor space slot.
- Player carries the bot from the kit room to the court. `ItemManager.move_to_court(bot_key)` places it at the `court_side` role; `FixtureManager` spawns `bot_dock.tscn` at the `BotDock` marker.
- Player carries the bot back to the kit room. `move_to_kit` unregisters effects; `FixtureManager` frees the prop.
- Destroy at the Tinkerer → permanent removal, same teardown.

The bot follows the same court/kit rule every item follows: on the court it is active (the dock stands, the paddle plays on idle); in the kit it is at rest (generates passive FP like any other item; see `08-kit.md`).

---

## When the bot plays

The bot dock prop (`bot_dock.tscn`) owns its own active/parked state. It listens to the idle-play signal (see `10-idle-play.md`): when the player goes idle, the bot takes over; when the player reclaims control, the bot parks.

On active, the prop spawns a driven paddle entity at the bot's court position. On parked, it frees that paddle. Activation is the prop's responsibility, not the item system's.

The generic idle paddle (space-bar default from `10`) stays available for players without a bot, so idle play works from day one. Owning a bot upgrades that idle experience: better stats, authored behaviour, a second paddle with its own visual identity. Buying a bot changes how idle *feels*, not whether it exists.

---

## Handoff

Player paddle and bot paddle are two distinct bodies. Only one drives the ball at a time; the other is visually present as a prop in a resting pose.

- **Handoff to bot:** player paddle slides to a rest position (courtside slump, dropped to the floor, exact pose an art call). Bot rolls in to active position. ~0.25s, choreographed so a running rally does not miss a beat.
- **Handoff from bot:** inverse. Bot steps back; player resumes. Same duration.

Both paddles are on screen in their respective states. That visible presence is what makes the bot a character rather than a UI state. The animation lives on the bot dock prop (it knows when it activates and deactivates).

---

## Bot stats

The bot carries stats through the standard `effects` array on its `ItemDefinition`, same as any other item. Starting set:

| Stat | What it does | Level signal |
|---|---|---|
| `reach` | Portion of the court the bot can cover before a ball escapes it | Wider as level rises |
| `response` | Reaction delay after ball direction changes | Shorter as level rises |
| `anticipation` | How far ahead in the ball's trajectory the bot reads | Deeper as level rises |
| `endurance` | Whether the bot's accuracy drops over long rallies | Flatter as level rises |

These register with `EffectManager` when the bot is on the court, like any item's effects. The bot paddle entity reads them via `ItemManager.get_stat` when it needs to make a decision; no bot-specific stat channel.

Per-bot tuning (a defender bot vs an aggressive returner) rides on a `BotBehaviour` resource exposed on the prop scene's root, **not** on the `Fixture`. Authoring flow: each bot `.tres` + its prop scene + its behaviour resource together define that bot.

```gdscript
class_name BotBehaviour
extends Resource

@export var return_to_centre_bias: float = 0.5
@export var anticipation_depth: float = 0.3
@export var aggression: float = 0.5
@export var failure_mode: StringName = &"miss"
```

---

## Why item + fixture is a clean fit

Everything the bot needs already rides on the standard item pathway:

- Ownership, persistence, destruction, kit passive FP: `ItemManager` and the kit system handle these.
- Activation and deactivation: `FixtureManager` spawns and frees the prop as the bot moves between the court and the kit.
- Stats: the existing effect system carries them through the standard `effects` array.
- Physical presence on the court: the fixture's prop scene is that presence.
- Runtime play/park logic: the prop scene's own state machine owns it.

The only bot-specific additions are the handoff animation and the player's choice to bring the bot onto the court. Both live on the court scene and the bot prop, so the item system stays one clean category.

---

## Persistence

Nothing bot-specific at the item layer. `item_levels[bot_key]` holds the owned level, same as every other item. Runtime state on the prop (current active/parked state) is transient and recomputed from the idle-play signal on scene ready.

If a future feature wants "the player paused the bot manually" (a toggle on the dock prop to disable it during play), that flag lives on `ProgressionData` as a dedicated field (`bot_manually_paused: bool`) and is read by the prop. Not needed for prototype.

---

## Open design questions

1. **Bot paddle visible when the player plays?** Does the bot paddle sit courtside as a watching prop while the player is active, or is it off-scene until it plays? Leaning: off-scene. The bot appears only when it plays; keeps the handoff meaningful.
2. **Bot earnings modifier vs player earnings?** Should FP earned while the bot is playing be at a modifier (e.g. 0.7x) compared to player-earned FP? Leaning: slightly less at level 1, parity at max level. Gives bot levelling a mechanical reward beyond stat improvements.
3. **Endurance in prototype scope?** Ship `endurance` as a flat stat (no drop-off) and enable the drop-off logic later, or cut it from prototype? Leaning: ship flat; the schema is ready for later tuning.
4. **Multiple bots in Alpha?** Keep at one for Alpha, or allow multiple (defender, returner, night-shift)? Leaning: one in Alpha; multiple opens authoring and tuning volume we do not need yet.

---

## Rough ticket outline

Not filing yet.

1. Bot item `.tres` + bot dock prop scene + one authored `BotBehaviour` resource.
2. Bot paddle entity (reads stats, drives input, listens for ball events).
3. Bot dock prop state machine: activate/park on the idle-play signal.
4. Handoff animation between player paddle and bot paddle.
5. Bot earnings modifier config (if question 2 lands yes).

No new item-system tickets; those fold into the cross-cutting tickets in `08-fixtures.md`.
