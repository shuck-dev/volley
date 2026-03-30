# Upgrade Mechanics

## Goal
Replace the attribute upgrade system with an item-based system. Items are objects with narrative identity: they affect the paddle's mechanical performance without describing how, and carry character context through their description and the Tinkerer's dialogue when levelling them. This is the economic and narrative backbone for the shop, the Tinkerer, and the signal layer.

**Points:** 8
**Dependencies:** Progression System (FP economy, save/load)
**Unlocks:** Upgrade Shop (rotation, display), The Shopkeeper and the Tinkerer (character integration), Upgrade Art (item visuals)

---

## Why items instead of attributes

The previous design (Paddle Speed Lv2 [40 FP]) has no narrative surface. Items give every upgrade a name, a presence, and a description that can carry meaning without explaining mechanics. A player reads "your friend's spare headphones, still charged" and feels something before they feel the effect. The mechanical effect is discovered through play. The description is a clue.

This also enables synergies (deferred to Beta) and world causality to extend the same data model without structural changes.

---

## Scope

### In scope
1. Item data model (extensible template)
2. 24 Act 1 items (other pools deferred to Post-Break phase)
3. A single description per item
4. Items affect AI paddle identically to player paddle
5. FP cost per item purchase and per level upgrade (scale-based)
6. Item levelling (3 levels: base, upgraded, max) via the Tinkerer
7. Item inventory (owned items persist, effects scale with current level)
8. One world causality item in prototype (exact form determined by design spike)

### Out of scope
- Synergies (Beta: two items combined at the Tinkerer for a fee)
- Broken item (Content Updates: an item that appears inert and activates later)

### World causality
World causality items cause something to appear or change in the scene when owned -- an interactive element, an environmental object, a new zone. The scope of what is feasible needs to be defined in the design spike before any world causality items are authored. The prototype includes one example item of this type to prove the implementation model works and establish the pattern for future items.

The spike must answer:
- What types of scene change are feasible (spawned nodes, visual-only changes, new interactive zones, etc.)
- Whether world causality effects scale with item level or are binary (owned or not)
- How the scene responds to owning multiple world causality items simultaneously

---

## Item data model

Each item is a resource with the following fields. The effect system must be extensible: new effect types should be addable without modifying existing items.

```
ItemDefinition (scripts/items/item_definition.gd) [Resource]
  - id: String
  - display_name: String
  - purchase_cost: int           # FP cost to buy from the shop
  - level_cost_scale: float      # multiplier applied to purchase_cost per level upgrade
  - max_level: int               # always 3 for prototype
  - pool: String                 # availability gate: "act1", "act2", "act3", "peace"
  - description: String          # single description, same across all acts
  - tinkerer_dialogues: Array[String]  # what the Tinkerer says per upgrade [lvl2, max]
  - effects: Array[ItemEffect]
  - synergy_ids: Array[String]   # ids of items this can synergise with (Beta)

ItemEffect (scripts/items/item_effect.gd) [Resource]
  - effect_type: String          # "stat_modifier", "world_causality" (future), etc.
  - effect_key: String           # which value is modified (e.g. "paddle_speed")
  - value_per_level: float       # effect magnitude added per level (level * value_per_level)
```

Level upgrade costs are calculated from `purchase_cost * level_cost_scale` for level 2 and `purchase_cost * level_cost_scale^2` for max. Consistent with the existing scale-based system.

The `effect_type` field is the extensibility hook. Stat modifiers are the only implemented type in prototype. World causality is added later as a new type without touching existing items.

Effect magnitude scales linearly with level: a level 1 item applies `1 * value_per_level`, level 2 applies `2 * value_per_level`, max (level 3) applies `3 * value_per_level`. Tuned during Make Fun pass.

---

## Items and the AI

The AI paddle reads the same modified values from `GameRules` that the player's paddle does. An item that increases paddle speed increases it for the AI too. This is intentional: the AI should reflect the current upgrade state, making the idle loop feel like it belongs to the same game as active play.

AI difficulty is tuned separately (miss rate, reaction time) and is not affected by items.

---

## Item descriptions

Each item has a single description. It does not change between acts. Narrative development across acts is carried by new items entering the pool at each act, not by existing items changing text. This concentrates the writing where it has the most impact: new items arrive with fresh meaning, and the Tinkerer's levelling dialogue carries the per-item signal layer.

Descriptions are written signal-layer first: the surface read is written to nearly but not quite bury the deeper meaning. The player who notices will notice. The player who doesn't will still feel something.

---

## Target inventory

50 items total across four pools:

| Pool | Items | Synergies | Notes |
|---|---|---|---|
| Act 1 | 24 | 10 | Available from game start |
| Act 2 | 14 | 8 | Unlocks at The Break |
| Act 3 | 8 | 5 | Unlocks at Act 2 prestige |
| Peace | 4 | 2 | Unlocks at Act 3 resolution |
| **Total** | **50** | **25** | |

Act 2, 3, and Peace items and their exact distribution are content decisions made during the Post-Break phase, once The Event is decided. The figures above are targets, not constraints.

Prototype scope covers Act 1 items only (24 items, 10 synergies). All other pools are authored in the Post-Break phase.

Synergy partners do not have to be in the same pool, but both items must be owned and at max level before a synergy attempt can be made.

New items and synergy pairs can be added in post-v1 updates without structural changes to the item system. Additional items slot into existing pools or introduce new ones; new synergy pairs extend the existing discovery space. This is the intended expansion path after v1.

---

## Open questions (pre-implementation spike required)

Before implementation, a design spike is needed to define:
- The full list of effect keys (what stat attributes items can modify)
- The world causality implementation model: what types of scene change are feasible, how they scale with level, and how multiple world causality items interact
- One concrete world causality item design to validate the model
- An agreed extensible template covering both stat modifiers and world causality so the data model supports both from the start

This spike should produce a doc or appendix used as the reference when authoring all items. It does not need to define all 50 items, only the schema they conform to and the one prototype world causality example. Prototype scope is 24 Act 1 items.
