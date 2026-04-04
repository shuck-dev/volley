# Stat Modifiers and Prototype Items

Spike output for SH-40. Defines the item effect framework and 8 prototype items.

---

## Design principle

Items are gameplay-first. The effect is immediately perceptible - the player figures out what an item does by owning it, not by reading a description. Most items will be causality-driven; passive stat boosts are a subset of the same system.

The Tinkerer carries the narrative meaning of each item. The item itself just does its thing.

FP is Act 1's incentive currency. Act 2 (battle mode) and Act 3 (enemy mode) introduce different objectives, so items designed for those acts may target different incentives entirely. Act 1 prototype items are FP-focused, but the framework must not assume FP is always the reward worth designing around. Items that carry across acts should stay useful under different objective conditions.

---

## Item effect framework

Every item effect is: **trigger + condition + outcome**.

A passive stat modifier is a causality effect with trigger `always`. There is no separate system.

### Level scaling

Each outcome has a `level_scaling` property (default 1.0) that controls how its value grows across item levels. The formula is:

```
effective_value = base_value * (1.0 + level_scaling * (level - 1))
```

Level 1 always applies the base value. `level_scaling` controls growth per additional level:
- `1.0` (default): linear scaling (x1, x2, x3)
- `0.5`: half growth (x1, x1.5, x2)
- `0.0`: no scaling, same value at all levels

---

### Triggers

Only triggers used by owned items need to be implemented.

#### Active

| Trigger | Fires when |
|---|---|
| `always` | Passively, while the item is owned |
| `on_miss` | Ball contacts a miss wall |
| `on_personal_best` | Streak exceeds the player's personal best |
| `on_hit` | Any paddle hit registers |
| `on_streak_multiple(n)` | Every n-th hit repeatedly (at n, 2n, 3n...) |
| `on_streak_start` | First hit of a new rally, immediately after a miss |
| `on_edge_hit` | Ball hits the extreme edge of the paddle |
| `on_max_speed_reached` | Ball hits the speed ceiling for the first time this rally |
| `on_ball_behind_paddle` | Ball passes behind a paddle toward the miss wall |
| `on_streak_milestone(n)` | Streak reaches threshold n, once per rally |

<details>
<summary>Ideas</summary>

| Trigger | Fires when |
|---|---|
| **Rally** | |
| `on_streak_lost_above(n)` | Missed while streak was above n |
| `on_consecutive_misses(n)` | Player has missed n times in a row |
| `on_long_rally(seconds)` | Rally has been running for n seconds |
| **Ball** | |
| `on_hit_at_max_speed` | Hit registered while ball is already at max speed |
| `on_speed_maintained(seconds)` | Ball stays at max speed continuously for n seconds |
| `on_speed_tier(speed)` | Ball crosses a specific speed threshold |
| `on_speed_approaching_max(margin)` | Ball is within margin px/s of the ceiling |
| `on_speed_reset` | Ball speed resets to min after a miss |
| `on_wall_bounce` | Ball bounces off top or bottom wall |
| **Skill** | |
| `on_near_miss` | Ball passes within a small margin of the paddle edge without hitting |
| `on_perfect_center_hit` | Ball hits the center zone of the paddle |
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

| Condition | Description | Parameters |
|---|---|---|
| `game_state_is(state)` | A named item-driven game state is currently active | `state` |
| `game_state_is_not(state)` | A named item-driven game state is not currently active | `state` |
| `delay_random(min, max)` | Outcome fires after a random delay within the range. If the trigger resets (e.g. miss) before the delay expires, the outcome never fires | `min_seconds`, `max_seconds` |
| `degradation_at(n)` | Item's hidden degradation counter has reached n | `n` |

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
| `deflect_ball` | Instantly change the ball's direction to a random angle | none |
| `spawn_gravity_well` | Create a gravity point on the court that curves ball trajectory | `strength`, `drift` (optional) |
| `intensify_gravity_well` | Temporarily increase gravity well pull strength | `multiplier`, `duration_seconds` |
| `award_friendship_points` | Award FP scaled by a game value | `base_amount`, `scale_by` (optional, e.g. `ball_speed`) |
| `expand_kit_slots` | Permanently add kit slots | `count` |
| `increment_degradation` | Add to an item's hidden degradation counter | `amount` |
| `share_stats_with_partner` | Partner receives all stat buffs the player has | none |
| `momentum_boost` | Temporary buff to both paddles | `stats[]`, `duration_seconds` |
| `oscillate_stat` | Continuously ramp a stat up and down in unpredictable waves | `key`, `wave_range` |
| `modify_stat_until_miss` | Add a delta to a stat key until the next miss. Stacks if triggered multiple times | `key`, `delta` |
| `roll_table` | Pick a random outcome from a set of equally weighted effects and execute it | `outcomes[]` |
| `set_ball_speed` | Immediately set ball to a specific speed | `value` |

<details>
<summary>Ideas</summary>

| Outcome | Description | Parameters |
|---|---|---|
| **Stat modification** | | |
| `modify_stat_temporary` | Add a delta to a stat key for a duration | `key`, `delta`, `duration_seconds` |
| `modify_stat_until_hit(n)` | Add a delta to a stat key until n more hits register | `key`, `delta`, `hits` |
| `set_stat_temporary` | Override a stat key to a specific value for a duration | `key`, `value`, `duration_seconds` |
| **Ball control** | | |
| `boost_ball_speed` | One-off speed burst on top of current speed | `delta` |
| **FP economy** | | |
| `award_friendship_points_flat` | Award a flat FP amount | `amount` |
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
| `ball_speed_min` | Ball starting/reset speed | 400.0 | px/s |
| `ball_speed_max_range` | Speed ceiling offset added to min | 300.0 | px/s |
| `ball_speed_increment` | Speed increase per paddle hit | 15.0 | px/s |
| `friendship_points_per_hit` | FP awarded per paddle hit | 1 | FP |
| `ball_magnetism` | Pull strength toward paddle when ball is near | 0.0 | force |
| `return_angle_influence` | Bias toward favorable return angles on hit | 0.0 | factor (0-1) |

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

Emitted by EffectManager for presentation layer consumers (HUD, entities, audio, VFX). Payloads contain only what downstream consumers need — current game state is queryable directly.

#### Active

| Signal | Payload | When |
|---|---|---|
| `game_state_entered(state, item_key)` | `state: String`, `item_key: String` | Named game state activated; drives frenzy fire VFX and equivalent |
| `game_state_exited(state, item_key)` | `state: String`, `item_key: String` | Named game state deactivated; drives explosion VFX and equivalent |
| `ball_spawned(item_key)` | `item_key: String` | Extra ball added to the game |
| `extra_balls_cleared(item_key)` | `item_key: String` | All extra balls removed |
| `item_buff_started(stat_key, duration, item_key)` | `stat_key: String`, `duration: float`, `item_key: String` | Temporary stat modification begins; entity starts visual state, duration drives countdown |
| `item_buff_expired(stat_key, item_key)` | `stat_key: String`, `item_key: String` | Temporary stat modification ends; entity stops visual state |
| `ball_deflected(item_key)` | `item_key: String` | Ball direction changed by item; drives flash VFX on ball |
| `gravity_well_spawned(position, item_key)` | `position: Vector2`, `item_key: String` | Gravity point placed on court; drives distortion VFX |
| `gravity_well_intensified(item_key)` | `item_key: String` | Gravity well pull spiked; drives surge VFX on well |
| `roll_result(outcome_name, item_key)` | `outcome_name: String`, `item_key: String` | Roll table resolved; drives colour flash or result reveal VFX |

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

## Item categories

### Kit and locker

All owned items are either in the kit or in the locker. The kit is what's active: causality effects and stat modifiers only fire from equipped kit items. The locker is everything else. Any item not in the kit sits in the locker and generates passive FP.

There is no "locker item" category. Every item can be in the kit or the locker. The player decides what to equip based on what they need. An item in the locker is still valuable because of passive FP generation.

Start with 3 kit slots; slots can be expanded by court items. Swapping kit items is allowed at any time but costs FP and triggers a per-slot cooldown. Both the FP cost and cooldown duration are Make Fun Pass tuning targets. The combined cost means swapping is a real decision without being a hard lock.

### Court items

No slot cost. Active without occupying a kit slot. Visually present on the court rather than in the kit bag. Can be lockered or destroyed like any other item.

Some court items expand kit slot count. These are early priority purchases: meta-progression that unlocks more active capacity.

Destroying a court item at the Tinkerer is a heavy decision and carries the heaviest Tinkerer dialogue.

---

## Locker and passive FP

All owned items generate FP passively while in the locker. Rate scales with item cost or level — investing in an item makes it a better bench earner even if it is never equipped. This gives every purchase value beyond its active effect and sustains the idle economy when the kit is locked in.

### Surface layer

Your gear earns FP just by being yours. You packed it, you own it, you care for it. A well-stocked locker is a kit that works for you even when you're not on the court. The bench contributes.

Passive FP is communicated through sound, not visuals. Late game the locker can be generating significant FP — visual pops would become noise. Instead: a gentle ambient audio texture that grows denser as the locker fills. Not louder, richer. Individual item ticks are near-subaudible. The overall feel is atmosphere, not UI events.

### Signal layer

The items are proxies for relationships. The FP from the locker is ambient warmth — the emotional residue of connection persisting through proximity and care. The player never needs to read this to understand the mechanic. It is for people paying attention.

The signal bleeds through in three places:

**Sound treatment.** Locker FP arrives differently from hit-earned FP. Hit FP pops. Locker FP glows. Different audio, different feeling. A player paying attention notices the game treats them differently without being told why.

**Partners.** Partners are who you are actually training with. They see your kit. They notice what you carry. Partner dialogue is where most of the locker signal layer lives — a partner noticing you still wear something, recognising something in your bag, remarking on how much you have accumulated after a long run together. Surface: they know your gear. Signal: they can see how much you have held onto and what it means. The Tinkerer and Shopkeeper carry their own weight elsewhere; the locker belongs to the partner relationships.

**The Shopkeeper, once.** Late Act 1, as the projection starts losing coherence, the Shopkeeper notices something in the locker. One line. Something like "I saw you kept that. You don't have to use it." Surface: friendly observation. Signal: the projection is aware of what the player is holding onto. After The Break the player looks back and understands what that line meant.

After The Break: the warmth from the locker was always real. It just was not the friend's warmth. It was the main character's memory of it, still generating something in the absence.

---

## Destruction and secret items

Any item can be destroyed at the Tinkerer. Destroying specific items unlocks secret items that cannot be obtained any other way. This is not signposted. The Tinkerer's destruction dialogue does not hint at it. Most players will never find these.

Secret items are for die-hards: players who destroy things out of curiosity, who pay close attention to what the Tinkerer says, who experiment beyond the obvious loop. The reward is the discovery itself.

Most item destructions do not unlock anything. The partial FP refund and the Tinkerer's dialogue are the only return. Secret unlocks are rare by design — one per specific item at most, and not every item has one.

Secret items entering the pool conditionally require the shop rotation system to support trigger-gated pool entries. See `04-upgrade-shop.md`.

---

## Item design categories

Starting categories. Not exhaustive; new items may introduce new ones.

- **Consolation** — rewards failure or loss. Softens the sting, gives the player something to hold onto after a miss. The Stray lives here.
- **Precision** — rewards consistency and streak-building. Stat modifiers that scale with sustained play. The opposite of consolation: you earn it by not dropping the ball.
- **Field-changing** — alters the play space or ball behaviour rather than the paddle or economy. Creates moments where the court itself feels different.
- **Slot-expanding (court)** — court items that expand kit capacity or provide always-on utility. Simple effects, big meta-progression value. Natural candidates for secret destruction unlocks.
- **Risk/reward** — injects variance into the economy or gameplay. Chance-based or high-stakes tradeoffs where the player opts into uncertainty for a bigger payoff.
- **Momentum** — snowball effects that build with sustained play. The longer you go, the bigger the payoff. A miss wipes everything. High ceiling, hard crash.
- **Recovery** — helps you bounce back after a miss. Different from consolation (which rewards the miss itself); recovery is about getting back on track faster.
- **Defensive** — makes it harder to miss. Bigger paddle, slower approach, second chances. The safety item.
- **Tempo** — changes the rhythm of the game. Speeds up or slows down in patterns. The game breathes differently.
- **Synergy** — weak alone, powerful when combined with specific other items. The build-around category.
- **Partner-enhancing** — buffs your partner's play. Invests in the relationship, not just yourself.

---

## Items

Items are designed around a **thing + twist** formula. The thing is a physical object. The twist gives it character and hints at the gameplay without explaining it. The physical description is for art direction and may differ from the name and description text.

Descriptions are short — a fragment of thought from the main character's mind. No second person. Leave the narrative to the other characters.

Because descriptions are short they can change dynamically. Variant text is keyed to item state and swapped silently in the UI — no announcement, no tooltip. The player notices the text has shifted and understands why through play.

Every item has exactly 3 variants: default, item power revealed (triggers once the player has witnessed the effect), and narrative revealed (Post-Break for Act 1 items; tied to the relevant story beat for Act 2 and Act 3 items).

Item card format:
```
Thing + twist | Physical description | Category (only if not Kit)
Name
Descriptions (state → text)
Effects per level
Cost | Scaling
```

Items have 3 levels: base (purchased), upgraded, max.
Cost is the purchase price at level 1. Cost scaling formula: `cost = base_cost * scaling^current_level`.

---

### The Stray

Lost ball + gunpowder | Worn ball dusted lightly in gunpowder, slightly singed around the seams

| State | Description |
|---|---|
| Default | "Nobody trained it" |
| After frenzy triggers once | "Fast. Too fast" |
| Post-Break | "It was always going to do that" |

| Level | Extra balls (cap) | Frenzy trigger |
|---|---|---|
| 1 | 1 ball (cap 2) | On personal best |
| 2 | 2 balls (cap 3) | On personal best |
| 3 | 3 balls (cap 4) | On personal best or streak milestone (tuning target) |

```
Effect 1
  trigger: on_miss
  condition: game_state_is_not("frenzy")
  outcome: spawn_ball [capped per level]

Effect 2
  trigger: on_personal_best [levels 1-2] / on_personal_best or on_streak_milestone(n) [level 3]
  outcome: set_game_state("frenzy")
  outcome: multiply_stat_temporary(ball_speed_min, 2.0, until_state_exits("frenzy"))

Effect 3
  trigger: on_miss
  condition: game_state_is("frenzy")
  outcome: clear_extra_balls
  outcome: set_game_state(null)
```

Base cost: 60 FP | Scaling: 1.7

---

### The Call

Referee card + shifting colour | Battered card, creased at the corners, colour different every time you glance at it

| State | Description |
|---|---|
| Default | "Looks official" |
| After first colour change | "That wasn't green" |
| Post-Break | "Why wasn't I there?" |

Every n-th hit, the card flips to a random colour. Each colour sets the FP-per-hit multiplier until the next flip. Every flip also deflects the ball to a random angle. The player learns colours through play, not a legend.

| Level | Fires every | Colours |
|---|---|---|
| 1 | 20 hits | Yellow (x1), Red (x2), Green (x3) |
| 2 | 15 hits | Yellow (x1), Red (x2), Green (x3), Blue (x5) |
| 3 | 10 hits | Yellow (x1), Red (x2), Green (x3), Blue (x5), Gold (x8) |

Blue and Gold do not exist in refereeing. The card is showing calls that cannot exist.

```
Effect 1
  trigger: on_streak_multiple(n) [n scales with level: 20/15/10]
  outcome: multiply_stat_temporary(friendship_points_per_hit, random_colour_tier, until_next_trigger)
  outcome: deflect_ball
```

Base cost: 80 FP | Scaling: 1.5

---

### Dead Weight

Medicine ball + dense metal | Small, impossibly heavy, dull grey surface with no grip. The court sags slightly where it sits.

| State | Description |
|---|---|
| Default | "Don't try to move it" |
| After first gravity-warped hit | "Why does my hand look weird?" |
| Post-Break | "Still there" |

A gravity well sits on the court, curving ball trajectory toward it. Hits on faster balls earn bonus FP. At max level, the well surges when the ball passes behind a paddle.

| Level | Gravity | FP bonus | Rescue pull |
|---|---|---|---|
| 1 | Mild pull, fixed position | FP scales with ball speed at hit | No |
| 2 | Stronger pull, point drifts | Better FP scaling | No |
| 3 | Stronger pull, point drifts | Better FP scaling | Intense temporary pull when ball passes behind paddle |

```
Effect 1
  trigger: always
  outcome: spawn_gravity_well(strength and drift scale with level)

Effect 2
  trigger: on_hit
  outcome: award_friendship_points(scale_by: ball_speed)
  tuning: on_hit fires every hit, so FP generation rate climbs sharply at high ball speeds. Cap or diminishing returns may be needed to keep FP economy balanced.

Effect 3 (level 3 only)
  trigger: on_ball_behind_paddle
  outcome: intensify_gravity_well(multiplier: tuning_target, duration: tuning_target)
```

Base cost: 100 FP | Scaling: 1.8

---

### Spare

Training cone + melted base | Court | Standard orange cone, base slightly warped like it was left in the sun too long. It doesn't move when you kick it.

| State | Description |
|---|---|
| Default | "There's always one left over" |
| After equipping 4th kit item | "Wasn't supposed to need it" |
| Post-Break | "Nobody noticed it was missing" |

Court item. Appears on the court in the background. Grants +1 kit slot. The bonus slot appears on the floor next to the kit bag in the kit UI, visually distinct from the base bag slots.

No levels. Single purchase.

```
Effect 1
  trigger: always
  outcome: expand_kit_slots(1)
```

Base cost: 150 FP

---

### Long Shot

Betting slip + race already ran | Crumpled slip, printed odds faded, creased from being folded and unfolded too many times.

| State | Description |
|---|---|
| Default | "Haven't checked yet" |
| After first roll resolves | "It was already decided" |
| Post-Break | "Held onto it this whole time" |

Each rally starts a hidden timer (random delay). If the timer fires before you miss, the slip rolls and an effect triggers. If you miss first, the race never finishes. Higher levels add outcomes to the table and tighten the delay window. All outcomes are equally weighted.

| Roll | Effect |
|---|---|
| **Payout** | FP burst |
| **Photo Finish** | Temporary ball speed boost |
| **Dead Heat** | Temporary paddle size increase |
| **False Start** | Ball speed immediately set to max |
| **Long Shot Pays** | All other positive effects fire simultaneously |

| Level | Roll table | Delay range |
|---|---|---|
| 1 | Payout, False Start | 5-30s |
| 2 | + Photo Finish, Dead Heat | 5-25s |
| 3 | + Long Shot Pays | 5-20s |

```
Effect 1
  trigger: on_streak_start
  condition: delay_random(min, max) [scales with level]
  outcome: roll_table([outcomes per level, equal weight])
```

Base cost: 70 FP | Scaling: 1.6

---

### Seven Years

Mirror + no end | Small rectangular locker mirror, scratched frame. Looks normal until you hold it at the right angle and the reflections don't stop.

**Whole:**

| State | Description |
|---|---|
| Default | "How deep does it go?" |
| Power revealed | "It's fine" |
| Post-Break | "Counted every one" |

**Broken:**

| State | Description |
|---|---|
| Default (just broke) | "Too late" |
| Power revealed (curse felt, or Tinkerer levels it) | "Sharper than before" |
| Post-Break | "Some things don't heal" |

Passive FP multiplier that scales with hidden crack count. Each miss adds a crack. The player never sees the number. More cracks = more fractal reflections = higher multiplier. At 100 cracks the mirror breaks and becomes a cursed item with a slight debuff (tuning target). The broken state persists until dealt with.

Leveling fully repairs the mirror, resetting cracks to zero and the multiplier back to base. The player chooses when to level: push the cracked multiplier higher, or repair before it breaks.

True power is in synergy with other items (future design).

| Level | Repair | Multiplier range (0-100 cracks) | Broken debuff |
|---|---|---|---|
| 1 | Fresh | x1.0 to x1.5 (tuning target) | Slight FP reduction |
| 2 | Full repair | x1.0 to x2.0 | Same |
| 3 | Full repair | x1.0 to x3.0 | Same |

```
Effect 1
  trigger: always
  condition: degradation_below(100)
  outcome: multiply_stat(friendship_points_per_hit, scale_by: crack_count)

Effect 2
  trigger: on_miss
  outcome: increment_degradation(1) [hidden]

Effect 3 (broken state)
  trigger: always
  condition: degradation_at(100)
  outcome: modify_stat(friendship_points_per_hit, -debuff)
```

Base cost: 90 FP | Scaling: 1.5

---

### Double Knot

Friendship bracelet + double knotted | Woven bracelet, faded colours, knotted twice at the clasp. Your partner wears the other one.

| State | Description |
|---|---|
| Default | "Made two" |
| After magnetism pull felt | "Closer than before" |
| Post-Break | "Still wearing it" |

Buffs both paddles equally. The connection strengthens with each level.

| Level | Buff (both paddles) |
|---|---|
| 1 | Ball magnetism: slight pull toward paddle when ball is near |
| 2 | + Return angle influence: hits send ball at more favorable angles |
| 3 | + Stat sharing + temporary momentum boost on edge hits |

At level 3, the partner receives all your stat buffs. Edge hits (clutch saves at the paddle's extreme) trigger a temporary surge for both paddles.

```
Effect 1
  trigger: always
  outcome: modify_stat(ball_magnetism, delta) [both paddles, scales with level]

Effect 2 (level 2+)
  trigger: always
  outcome: modify_stat(return_angle_influence, delta) [both paddles]

Effect 3 (level 3)
  trigger: always
  outcome: share_stats_with_partner

Effect 4 (level 3)
  trigger: on_edge_hit
  outcome: momentum_boost(both paddles, duration: tuning_target)
```

Base cost: 120 FP | Scaling: 1.6

---

### Cadence

Whistle + out of tune | Standard coach's whistle, brass tarnished, plays a note that's slightly flat. You can feel it in your teeth.

| State | Description |
|---|---|
| Default | "Sounds wrong" |
| After first ceiling raise | "Don't stop. Won't stop" |
| Post-Break | "Was anyone listening?" |

The whistle sets the tempo. Ball speed oscillates in waves: ramping up and down unpredictably. When the ball reaches max speed, the ceiling raises and speed keeps climbing.

| Level | Speed oscillation | Max raise on ceiling hit |
|---|---|---|
| 1 | Gentle waves | Small ceiling increase |
| 2 | Wider waves | Larger ceiling increase |
| 3 | Wilder swings | Largest ceiling increase + temporary speed burst |

```
Effect 1
  trigger: always
  outcome: oscillate_stat(ball_speed_min, wave_range scales with level)

Effect 2
  trigger: on_max_speed_reached
  outcome: modify_stat_until_miss(ball_speed_max_range, delta scales with level) [uncapped, stacks]
```

Base cost: 85 FP | Scaling: 1.5

---

## Simple stat items

Passive stat modifiers. No triggers, no conditions, no twist. These exist so the shop has straightforward purchases available early: the player picks one, feels the difference immediately, and understands the economy before encountering causality items.

These are not build-around items. They are reliable, boring, and useful. The kind of thing you buy because you need it, not because it excites you. They round out a kit without competing for attention.

---

### Ankle Weights

Leg weights + worn elastic | Scuffed ankle weights, elastic fraying, sand shifting inside. They've been used every day for a long time.

| State | Description |
|---|---|
| Default | "Heavy steps" |
| Power revealed | "Didn't notice the difference until I took them off" |
| Post-Break | "Still wearing them" |

Increases paddle movement speed per level. Max level 10.

| Level | Effect |
|---|---|
| 1-10 | +50 paddle speed per level |

```
Effect 1
  trigger: always
  outcome: modify_stat(paddle_speed, +50 per level)
```

Base cost: 30 FP | Scaling: 1.5

---

### Grip Tape

Sports tape + sticky residue | Roll of white grip tape, half used, end stuck to itself. Leaves marks on everything it touches.

| State | Description |
|---|---|
| Default | "Covers more than you think" |
| Power revealed | "Hard to miss now" |
| Post-Break | "Held it together" |

Increases paddle collision size per level. Max level 10.

| Level | Effect |
|---|---|
| 1-10 | +10 paddle size per level |

```
Effect 1
  trigger: always
  outcome: modify_stat(paddle_size, +10 per level)
```

Base cost: 30 FP | Scaling: 1.5

---

### Training Ball

Practice ball + always warm | Bright orange practice ball, slightly soft, always warm to the touch no matter how long it sits.

| State | Description |
|---|---|
| Default | "Already moving" |
| Power revealed | "Starts fast. Stays fast" |
| Post-Break | "Never cooled down" |

Raises the ball's starting speed per level. Max level 10.

| Level | Effect |
|---|---|
| 1-10 | +30 ball speed min per level |

```
Effect 1
  trigger: always
  outcome: modify_stat(ball_speed_min, +30 per level)
```

Base cost: 40 FP | Scaling: 1.6

---

### Court Lines

Chalk line + no end | Piece of court chalk, worn to a nub. The lines it draws keep going past where you stopped.

| State | Description |
|---|---|
| Default | "Wider than it looks" |
| Power revealed | "The ceiling keeps moving" |
| Post-Break | "Drew them everywhere" |

Raises the ball speed ceiling by increasing the max range above the minimum. Max level 10.

| Level | Effect |
|---|---|
| 1-10 | +50 ball speed max range per level |

```
Effect 1
  trigger: always
  outcome: modify_stat(ball_speed_max_range, +50 per level)
```

Base cost: 40 FP | Scaling: 1.6

---

## Implementation notes

### Implemented (SH-41, SH-43)

- All stat keys exposed via `GameRules.BASE_STATS` and queried through `ItemManager.get_stat()`.
- Event dispatch: `ItemManager.process_event()` fires registered effects with matching triggers. Game.gd wires ball signals (`at_max_speed_changed`, `missed`) to dispatch `on_max_speed_reached` and `on_miss`.
- Named game states tracked in `EffectState` via `set_state()`/`clear_state()`/`is_state_active()`.
- Ball reads speed limits every physics frame via `BallEffectProcessor._sync_speed_limits()`, enabling dynamic stat changes (oscillation, ceiling raises) to take effect immediately.
- `GameRules.BALL_SPEED_MIN` and `BALL_SPEED_MAX` constants removed; replaced by stat-driven values.

### Remaining

- Causality items need temporary outcome expiry (timer or per-frame tick) for `multiply_stat_temporary`.
- Multi-ball requires a ball spawner and a reference list of active balls in the scene. `clear_extra_balls` removes all but the original.
