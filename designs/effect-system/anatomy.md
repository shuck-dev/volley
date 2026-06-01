# Anatomy of an Effect

## The shape

Every effect is exactly three parts: a trigger, zero or more conditions, and one or more outcomes.

**Trigger.** When the effect fires. `on_miss`, `on_hit`, `always`, `on_consolidation`, and others. See [reference.md](reference.md) for the full list.

**Conditions.** Optional gates that must pass before outcomes execute. A condition is a test on game state, degradation, or timing. All conditions must pass; failure cancels the effect for that event.

**Outcomes.** What happens when the effect fires. A stat change, a ball spawn, a game state toggle, a friendship point award. One effect can carry multiple outcomes; all execute on a successful fire.

A passive stat modifier follows the same shape. There is no separate system for passives: the trigger is `always`, evaluated once on registration and again on level change.

## Sources

Three sources register effects today. The registration path is the same for all three.

**Items.** A player activates an item; `ItemManager` calls `EffectManager.register_source`, passing the item definition and current level. Deactivate unregisters. Upgrade unregisters then re-registers at the new level.

**Partners.** A partner joins the session; the partner definition is registered as a source. The partner's `relationship_level` is the level parameter. The partner leaves; the source unregisters.

**The venue.** Built-in effects that represent the court's own behaviour. Consolidation is the primary example: `on_consolidation` fires when the ball tiers up, and the venue's built-in effect adds `+1` to `soul_multiplier`. Venue effects register alongside item and partner effects and resolve in the same evaluation loop.

## Level scaling

Each outcome carries a `level_scaling` property (default `1.0`) that controls how its value grows.

```
effective_value = base_value * (1.0 + level_scaling * (level - 1))
```

Level 1 always applies the base value. `level_scaling` controls growth per additional level:

- `1.0` (default): linear scaling (×1, ×2, ×3)
- `0.5`: half growth (×1, ×1.5, ×2)
- `0.0`: no scaling; the same value at every level

An effect can also declare `min_active_level` and `max_active_level` to restrict which levels it applies at. A multi-level item can use several effects with different level ranges rather than a single scaling formula.
