# Evaluation

## Event to outcome

A game event arrives at `EffectManager` with an event name and a payload. The manager walks every registered effect whose trigger matches the event name, checks each condition, and executes the outcomes for every passing effect. After all outcomes execute, temporary modifiers clear.

Built-in venue effects resolve in the same pass. There is no separate venue evaluation step; `on_consolidation` effects from the venue sit in the same registered-source list as item and partner effects and resolve in registration order.

`always` trigger effects are evaluated once on registration. They re-evaluate when the source changes level.

## Registration-order resolution

Effects fire in the order their sources were registered. Within a source, effects fire in the order they are declared. There is no priority field; the authored order is the execution order.

## Stat resolution

Three stages, applied in sequence.

```
1. Sum all add modifiers          → flat delta on the base value
2. Sum all percentage modifiers   → apply as (1 + total) multiplier
3. Apply multiply modifiers       → applied sequentially
```

Percentage modifiers are summed before applying. Two `+50%` modifiers give `+100%` (×2.0), not ×2.25. This prevents exponential stacking.

Example: base `50`, `+10` add, `+140%` percentage, `×2` multiply → `(50 + 10) × (1 + 1.4) × 2 = 288`.

`EffectManager.get_stat(key)` is the single query point. Game systems never read base values directly. The game never hardcodes a stat that exists in this system.

## Temporary modifiers and reset-on-miss

A modifier marked `temporary = true` is excluded from `get_base_stat` and cleared when `EffectManager` handles the miss event.

`get_base_stat` returns the value without temporary modifiers. Proportional outcomes that use `range_stat_key` resolve against this stable base, so a buff that raised a stat does not inflate the proportional calculation.

When a miss fires, `EffectState.clear_temporary_modifiers()` runs after all miss-event outcomes execute, removing every modifier with `temporary = true`.
