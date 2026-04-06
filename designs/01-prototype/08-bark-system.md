# Bark System

## Goal

A lightweight system for partners to surface short, unprompted lines during play. Barks are not dialogue: no conversation, no player response, no branching. They are things a partner says to themselves, to the player, or to no one in particular. They appear briefly and fade.

The system must feel alive, not repetitive. A partner who repeats themselves feels hollow. A partner who speaks rarely, never repeats, and sometimes surprises you feels like a person.

**Dependencies:** Effect System (trigger types, including `on_timer` and `on_return_after_idle`), Partner data model
**Separate from:** Any future dialogue system. Barks are standalone. If a dialogue system absorbs them later, the migration is moving data, not rewriting logic.

All bark triggers (`on_miss`, `on_streak_milestone`, `on_return_after_idle`, `on_timer`) are effect system triggers. Any new trigger added for barks becomes available to the effect system for use by items or other sources.

---

## Design principles

1. **Silence is the default.** Most triggers produce no bark. When a partner speaks, it should feel like they chose to.
2. **Never repeat within a session.** A line that fired this session is excluded from selection until the session resets.
3. **Gaps are characterisation.** A partner does not bark on every trigger type. Which triggers they respond to and which they ignore defines who they are.
4. **Context matters.** The same trigger in different game states should draw from different pools.
5. **Big pools.** Each pool needs enough lines that the player cannot exhaust them in a single session. Minimum 8 lines per pool. Target ~100 total lines per partner across all pools, distributed by expected trigger frequency: pools that fire more often need more lines.

---

## Architecture

### Bark data

Bark data lives on the `Partner` resource as authored data, not in code. Each partner defines a set of **bark pools**. A bark pool is:

```
BarkPool:
  trigger: StringName           # effect system trigger type or "on_timer" (fires periodically)
  context: Dictionary           # optional conditions that narrow when this pool is active
  lines: Array[String]          # the lines
  chance: float                 # probability of firing when triggered (0.0 - 1.0)
  cooldown: float               # minimum seconds between barks from this pool
  priority: int                 # higher priority pools are checked first
```

Multiple pools can share the same trigger with different contexts. The system checks pools in priority order and fires the first one whose context matches and whose chance roll succeeds.

### Context conditions

Context narrows which pool is active based on game state. Conditions are simple key-value checks against queryable game state:

| Key | Type | Description |
|---|---|---|
| `miss_side` | String | Which side missed: `"player"` or `"partner"` |
| `streak_above_percentage_of_pb` | float | Current streak is above this fraction of the player's personal best (0.0 - 1.0) |
| `streak_below_percentage_of_pb` | float | Current streak is below this fraction of the player's personal best |
| `session_time_above` | float | Seconds since session started |
| `is_autoplay` | bool | Player is in autoplay mode |

Context conditions are optional. A pool with no context is always eligible when its trigger fires. Multiple conditions on one pool are AND logic.

New context keys can be added without changing the bark system; they just need to be queryable from game state.

### Selection

When a trigger fires:

1. Collect all bark pools for the active partner that match the trigger.
2. Filter by context: discard pools whose conditions do not match current game state.
3. Sort remaining pools by priority (highest first).
4. Walk the sorted list. For each pool:
   a. Check cooldown. If the pool fired too recently, skip it.
   b. Roll against `chance`. If the roll fails, skip it.
   c. Select a line from the pool using recency-weighted random (see below).
   d. Fire the bark. Stop checking further pools.
5. If no pool fires, silence. This is normal and expected.

### Recency weighting

Track which lines have fired this session per pool. On selection:

- Exclude any line that has already fired this session (hard exclusion, not just weighting).
- If all lines in a pool have fired this session, reset the pool's history and pick freely.
- Within eligible lines, pick uniformly at random. No need for complex weighting when the hard exclusion already prevents repeats.

This means a pool of 8 lines will cycle through all 8 before any line repeats. A pool of 20 lines may never repeat in a typical session.

### Cooldown scaling

Each pool has a base `cooldown` in seconds. Additionally, a global bark cooldown prevents any bark from any pool firing too close to another. This stops Martha from commenting on a miss and then immediately commenting on the streak start.

| Cooldown | Value | Purpose |
|---|---|---|
| Pool cooldown | Per pool, authored | Prevents the same trigger from producing barks too frequently |
| Global cooldown | System-wide, configurable | Prevents bark spam across different triggers |

Starting values are tuning targets. Pool cooldowns of 30-60s and a global cooldown of 15-20s are reasonable starting points.

### Presentation

Barks appear as text in the game view, near the partner's paddle. The text always comes from the source: Martha's lines appear on Martha's side, regardless of which game event triggered them. They fade in, hold briefly, and fade out. No UI chrome, no speech bubble, no portrait. Just text.

Timing:
- Fade in: ~0.2s
- Hold: ~2.0s
- Fade out: ~0.5s

If a new bark fires while one is visible, the old bark fades out immediately and the new one fades in. Barks do not queue.

---

## Authoring a partner's barks

Each partner defines their bark pools on their `Partner` resource. The pools define who they are: which moments they respond to, what they say, and how often they speak.

### Example: Martha

Martha speaks rarely. She comments on misses, long rallies, and returning after being away. She fills comfortable silences with idle chatter. Her full bark pools (pre-break and post-break) are in `08-first-partner-unlock.md`.

She has 5 pools totalling 100 lines (15 + 15 + 20 + 20 + 30), weighted by trigger frequency. Post-break, the same 5 pools swap to a different set of 100 lines where the shop and the memory bleed through.

| Pool | Trigger | Context | Chance | Cooldown | Lines |
|---|---|---|---|---|---|
| Player miss | `on_miss` | `miss_side: "player"` | 0.35 | 45s | 15 |
| Martha miss | `on_miss` | `miss_side: "partner"` | 0.35 | 45s | 15 |
| Long rally | `on_streak_milestone` | `streak_above_percentage_of_pb: 0.5` | 0.3 | 60s | 20 |
| Return after idle | `on_return_after_idle` | none | 0.8 | 0s | 20 |
| Idle chatter | `on_timer` | none | 0.3 | 120s | 30 |

Martha has no pools for `on_hit`, `on_max_speed_reached`, `on_personal_best`, or `on_streak_start`. Her silence on those triggers is deliberate: she's not a coach, she's a friend. She speaks when it matters to her, not when it matters to the game.

---

## Extensibility

The bark system is data-driven. Adding a new partner's barks means authoring pools on their `Partner` resource. Adding a new trigger type means adding a new pool with that trigger. Adding a new context condition means exposing a new queryable game state.

No per-partner code. No bark scripts. The system evaluates pools and selects lines. Partners differ in what they say, when they say it, and how often they speak. That is enough.

### Post-break line swapping

Each pool can define two sets of lines: pre-break and post-break. The bark system checks whether the break has occurred and draws from the corresponding set. The pools, triggers, contexts, chances, and cooldowns stay the same. Only the lines change. This means personality is consistent across the break; the weight of what's said is what shifts.

---

## Test plan

- A bark fires only when the trigger matches, context passes, cooldown has elapsed, and chance roll succeeds
- No line repeats within a session until all lines in the pool have been used
- Higher priority pools are checked before lower priority ones
- Global cooldown prevents barks from different pools firing in rapid succession
- A pool with unmet context conditions is skipped
- Silence is the most common outcome for any given trigger
