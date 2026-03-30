# Stat Modifiers and Prototype Items

Spike output for SH-40. Defines the item effect framework and 8 prototype items.

---

## Design principle

Items are gameplay-first. The effect is immediately perceptible - the player figures out what an item does by owning it, not by reading a description. Most items will be causality-driven; passive stat boosts are a subset of the same system.

The Tinkerer carries the narrative meaning of each item. The item itself just does its thing.

---

## Item effect framework

Every item effect is: **trigger + condition + outcome**.

A passive stat modifier is a causality effect with trigger `always`. There is no separate system.

---

### Triggers

Only triggers used by owned items need to be implemented.

#### Active

| Trigger | Fires when |
|---|---|
| `always` | Passively, while the item is owned |
| `on_miss` | Ball contacts a miss wall |
| `on_personal_best` | Streak exceeds the player's personal best |

<details>
<summary>Ideas</summary>

| Trigger | Fires when |
|---|---|
| **Rally** | |
| `on_hit` | Any paddle hit registers |
| `on_streak_start` | First hit of a new rally, immediately after a miss |
| `on_streak_milestone(n)` | Streak reaches threshold n, once per rally |
| `on_streak_multiple(n)` | Every n-th hit repeatedly (at n, 2n, 3n...) |
| `on_streak_lost_above(n)` | Missed while streak was above n |
| `on_consecutive_misses(n)` | Player has missed n times in a row |
| `on_long_rally(seconds)` | Rally has been running for n seconds |
| **Ball** | |
| `on_max_speed_reached` | Ball hits the speed ceiling for the first time this rally |
| `on_hit_at_max_speed` | Hit registered while ball is already at max speed |
| `on_speed_maintained(seconds)` | Ball stays at max speed continuously for n seconds |
| `on_speed_tier(speed)` | Ball crosses a specific speed threshold |
| `on_speed_approaching_max(margin)` | Ball is within margin px/s of the ceiling |
| `on_speed_reset` | Ball speed resets to min after a miss |
| `on_wall_bounce` | Ball bounces off top or bottom wall |
| **Skill** | |
| `on_near_miss` | Ball passes within a small margin of the paddle edge without hitting |
| `on_perfect_center_hit` | Ball hits the center zone of the paddle |
| `on_edge_hit` | Ball hits the extreme edge of the paddle |
| **Session / time** | |
| `on_session_start` | Game opens |
| `on_return_after_idle` | Player returns after being away |
| `on_time_elapsed(seconds)` | Fires every n seconds while the game is running |
| **Economy** | |
| `on_item_purchased` | Any item bought from the shop |
| `on_item_destroyed` | Any item destroyed at the Tinkerer |
| `on_shop_refresh` | Shop rotation turns over |
| `on_fp_spent(amount)` | Cumulative FP spent crosses a threshold |
| `on_balance_threshold(amount)` | FP balance crosses a threshold (high or low) |
| **World (future)** | |
| `on_partner_rally_started` | Partner joins a rally |
| `on_ball_returned_by_partner` | Partner hits the ball back |
| `on_record_approached(margin)` | Personal best is within margin of the world record |
| **Meta** | |
| `on_item_synergy_active(item_id)` | A specific other item is also owned |
| `on_owned_item_count(n)` | Player owns exactly n items |

</details>

---

### Conditions

Optional. If omitted the outcome always fires when the trigger does. Multiple conditions on one effect are all required (AND logic). OR logic is handled by authoring multiple effects on one item.

#### Active

| Condition | Description |
|---|---|
| `game_state_is(state)` | A named item-driven game state is currently active |
| `game_state_is_not(state)` | A named item-driven game state is not currently active |

<details>
<summary>Ideas</summary>

| Condition | Description |
|---|---|
| **Streak** | |
| `streak_above(n)` | Current streak is greater than n |
| `streak_below(n)` | Current streak is less than n |
| **Ball state** | |
| `ball_at_max_speed` | Ball is currently at the speed ceiling |
| `ball_above_speed(n)` | Ball is above a specific speed threshold |
| `ball_below_speed(n)` | Ball is below a specific speed threshold |
| **Economy** | |
| `fp_above(n)` | Player has more than n FP |
| `fp_below(n)` | Player has less than n FP |
| **Ownership** | |
| `item_owned(id)` | A specific other item is owned |
| `item_at_level(id, level)` | A specific other item is at a given level |
| `items_owned_above(n)` | Player owns more than n items total |
| **Rate limiting** | |
| `cooldown(seconds)` | Outcome cannot fire again until cooldown expires |
| **Firing limits** | |
| `first_occurrence` | Fires only the first time ever, then never again |
| `once_per_session` | Fires once per session, resets on game open |
| `times_triggered_below(n)` | Fires at most n times total across all sessions |
| **Chance** | |
| `chance(percent)` | Fires with a given probability |

**Firing limit balance note:** items using `first_occurrence`, `once_per_session`, or `times_triggered_below` must have effects large enough to justify the purchase. `first_occurrence` should pair with permanent or long-lasting outcomes. `once_per_session` should set up the whole session. When in doubt, make the effect bigger.

</details>

---

### Outcomes

#### Active

| Outcome | Description | Parameters |
|---|---|---|
| `modify_stat` | Add a delta to a stat key. Permanent while owned | `key`, `delta` |
| `multiply_stat_temporary` | Multiply a stat key by a factor for a duration or until a state exits | `key`, `multiplier`, `duration_seconds` or `until_state_exits(state)` |
| `spawn_ball` | Add an additional ball to the game | none |
| `clear_extra_balls` | Remove all balls except the original | none |
| `set_game_state(state)` | Enter or exit a named item-driven game state. Null clears the state | `state: String` or null |

<details>
<summary>Ideas</summary>

| Outcome | Description | Parameters |
|---|---|---|
| **Stat modification** | | |
| `modify_stat_temporary` | Add a delta to a stat key for a duration | `key`, `delta`, `duration_seconds` |
| `modify_stat_until_miss` | Add a delta to a stat key until the next miss | `key`, `delta` |
| `modify_stat_until_hit(n)` | Add a delta to a stat key until n more hits register | `key`, `delta`, `hits` |
| `set_stat_temporary` | Override a stat key to a specific value for a duration | `key`, `value`, `duration_seconds` |
| **Ball control** | | |
| `set_ball_speed` | Immediately set ball to a specific speed | `value` |
| `boost_ball_speed` | One-off speed burst on top of current speed | `delta` |
| **FP economy** | | |
| `award_friendship_points` | Award a flat FP amount | `amount` |
| `award_friendship_points_per_streak` | Award FP equal to `streak * multiplier` | `multiplier` |
| `award_friendship_points_percentage_of_balance` | Award a percentage of the current FP balance | `percent` |
| `award_friendship_points_per_items_owned` | Award FP per item currently owned | `amount_per_item` |
| `award_friendship_points_on_session_end` | Bank FP to be paid out when the game closes | `amount` |
| `multiply_friendship_points_temporary` | All FP earnings are multiplied for a duration | `multiplier`, `duration_seconds` |
| `subtract_friendship_points` | Remove a flat FP amount | `amount` |
| `subtract_friendship_points_per_streak` | Remove FP proportional to streak length (cursed) | `multiplier` |
| **Streak manipulation** | | |
| `extend_streak_on_miss` | Streak does not reset on the next miss | none |
| `boost_streak` | Add n to the current streak count | `amount` |
| **Persistence** | | |
| `carry_streak_between_sessions` | Streak survives closing the game | none |

</details>

---

### Stat keys

All values items can target via `modify_stat` or `modify_stat_temporary`.

#### Active

| Key | Target | Base value | Unit |
|---|---|---|---|
| `paddle_speed` | Paddle movement speed | 500.0 | px/s |
| `paddle_size` | Paddle collision height | 50.0 | px |
| `ball_speed_min` | Ball starting/reset speed | 500.0 | px/s |
| `ball_speed_max_range` | Speed ceiling offset added to min | 600.0 | px/s |
| `ball_speed_increment` | Speed increase per paddle hit | 15.0 | px/s |
| `friendship_points_per_hit` | FP awarded per paddle hit | 1 | FP |

`ball_speed_max_range` is not the absolute ceiling. Ceiling = `ball_speed_min + ball_speed_max_range`. At base values: 1100 px/s.

<details>
<summary>Ideas</summary>

| Key | Target | Base value | Unit |
|---|---|---|---|
| `offline_friendship_points_rate` | FP per minute during idle/offline | 0 | FP/min |

`offline_friendship_points_rate` is 0 until idle play lands. Pre-defined so idle items need no framework changes later.

</details>

---

### Signals

Emitted by ItemManager for presentation layer consumers (HUD, entities, audio, VFX). Payloads contain only what downstream consumers need — current game state is queryable directly.

#### Active

| Signal | Payload | When |
|---|---|---|
| `game_state_entered(state, item_key)` | `state: String`, `item_key: String` | Named game state activated; drives frenzy fire VFX and equivalent |
| `game_state_exited(state, item_key)` | `state: String`, `item_key: String` | Named game state deactivated; drives explosion VFX and equivalent |
| `ball_spawned(item_key)` | `item_key: String` | Extra ball added to the game |
| `extra_balls_cleared(item_key)` | `item_key: String` | All extra balls removed |
| `item_buff_started(stat_key, duration, item_key)` | `stat_key: String`, `duration: float`, `item_key: String` | Temporary stat modification begins; entity starts visual state, duration drives countdown |
| `item_buff_expired(stat_key, item_key)` | `stat_key: String`, `item_key: String` | Temporary stat modification ends; entity stops visual state |

<details>
<summary>Ideas</summary>

| Signal | Payload | When |
|---|---|---|
| `friendship_points_burst(amount, item_key)` | `amount: int`, `item_key: String` | Causality item awards FP; HUD scales pop animation by amount |
| `streak_saved(item_key)` | `item_key: String` | `extend_streak_on_miss` fires; suppresses normal miss reaction |
| `fp_multiplier_changed(multiplier)` | `multiplier: float` | FP multiplier window starts or ends; HUD shows active state above 1.0, clears at 1.0 |
| `ball_speed_changed_by_item(item_key)` | `item_key: String` | Item directly sets ball speed; distinct from natural acceleration |

</details>

---

## 8 prototype items

_To be designed collaboratively._

Items have 3 levels: base (purchased), upgraded, max. Effect values scale with level.

Cost is the purchase price at level 1. Cost scaling formula: `cost = base_cost * scaling^current_level`.

---

## Notes for SH-41 (Item system core)

- `friendship_points_per_hit` must be exposed as a query. Currently hardcoded as `1` in `game.gd:_on_paddle_hit()`.
- `ball_speed_increment` must be exposed as a query. Currently hardcoded as `GameRules.BALL_SPEED_INCREMENT` in `ball.gd:increase_speed()`.
- Causality items require ItemManager to subscribe to game signals and evaluate owned items on each trigger. Temporary outcomes need an expiry model (timer or per-frame tick).
- Named game states (for `set_game_state`, `game_state_is`) need a lightweight state registry in ItemManager or a dedicated GameStateManager.
- Multi-ball requires a ball spawner and a reference list of active balls in the scene. `clear_extra_balls` removes all but the original.
- `GameRules.BALL_SPEED_MIN` (400.0) and `GameRules.BALL_SPEED_MAX` (700.0) are unused. Remove in SH-41.
