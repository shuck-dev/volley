# Prototype Item Effect Blocks

Per-item effect definitions and cost/scaling tables for the 8 prototype items plus the simple stat items.

Cost formula: `cost = base_cost * scaling ^ current_level`. Level 1 cost is `base_cost`.

---

## The Stray

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

Base cost: 60 friendship | Scaling: 1.7

---

## The Call

| Level | Fires every | Colours |
|---|---|---|
| 1 | 20 hits | Yellow (x1), Red (x2), Green (x3) |
| 2 | 15 hits | Yellow (x1), Red (x2), Green (x3), Blue (x5) |
| 3 | 10 hits | Yellow (x1), Red (x2), Green (x3), Blue (x5), Gold (x8) |

```
Effect 1
  trigger: on_streak_multiple(n) [n scales with level: 20/15/10]
  outcome: multiply_stat_temporary(friendship_points_per_hit, random_colour_tier, until_next_trigger)
  outcome: deflect_ball
```

Base cost: 80 friendship | Scaling: 1.5

---

## Dead Weight

| Level | Gravity | Friendship bonus | Rescue pull |
|---|---|---|---|
| 1 | Mild pull, fixed position | Friendship scales with ball speed at hit | No |
| 2 | Stronger pull, point drifts | Better friendship scaling | No |
| 3 | Stronger pull, point drifts | Better friendship scaling | Intense temporary pull when ball passes behind paddle |

```
Effect 1
  trigger: always
  outcome: spawn_gravity_well(strength and drift scale with level)

Effect 2
  trigger: on_hit
  outcome: award_friendship_points(scale_by: ball_speed)
  tuning: on_hit fires every hit, so friendship generation rate climbs sharply at high ball speeds. Cap or diminishing returns may be needed to keep friendship economy balanced.

Effect 3 (level 3 only)
  trigger: on_ball_behind_paddle
  outcome: intensify_gravity_well(multiplier: tuning_target, duration: tuning_target)
```

Base cost: 100 friendship | Scaling: 1.8

---

## Spare

No levels. Single purchase. Court role.

```
Effect 1
  trigger: always
  outcome: expand_kit_slots(1)
```

Base cost: 150 friendship

The `expand_kit_slots` outcome is deprecated under the role model in [`06-roles.md`](06-roles.md); kit-slot enforcement for Spare is tracked in Linear (Kit slot enforcement).

---

## Long Shot

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

Base cost: 70 friendship | Scaling: 1.6

---

## Seven Years

| Level | Repair | Multiplier range (0-100 cracks) | Broken debuff |
|---|---|---|---|
| 1 | Fresh | x1.0 to x1.5 (tuning target) | Slight friendship reduction |
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
  outcome: stat(friendship_points_per_hit, -debuff)
```

Base cost: 90 friendship | Scaling: 1.5

---

## Cadence

| Level | Speed oscillation | Max raise on ceiling hit |
|---|---|---|
| 1 | Gentle waves | Small ceiling increase |
| 2 | Wider waves | Larger ceiling increase |
| 3 | Wilder swings | Largest ceiling increase + temporary speed burst |

```
Effect 1
  trigger: always
  outcome: oscillate_stat(ball_speed_offset, 25% of ball_speed_max_range, scales with level)

Effect 2
  trigger: on_max_speed_reached
  outcome: stat_until_miss(ball_speed_max_range, +25 per level) [uncapped, stacks]
```

Base cost: 85 friendship | Scaling: 1.5

---

## Simple stat items

Passive stat modifiers. Max level 10.

### Ankle Weights

| Level | Effect |
|---|---|
| 1-10 | +50 paddle speed per level |

```
Effect 1
  trigger: always
  outcome: stat(paddle_speed, +50 per level)
```

Base cost: 30 friendship | Scaling: 1.5

### Grip Tape

| Level | Effect |
|---|---|
| 1-10 | +140% paddle size per level |

```
Effect 1
  trigger: always
  outcome: percentage(paddle_size, +140% per level)
```

Base cost: 30 friendship | Scaling: 1.5

### Training Ball

| Level | Effect |
|---|---|
| 1-10 | +30 ball speed min per level |

```
Effect 1
  trigger: always
  outcome: stat(ball_speed_min, +30 per level)
```

Base cost: 40 friendship | Scaling: 1.6

### Court Lines

| Level | Effect |
|---|---|
| 1-10 | +50 ball speed max range per level |

```
Effect 1
  trigger: always
  outcome: stat(ball_speed_max_range, +50 per level)
```

Base cost: 40 friendship | Scaling: 1.6

### Wrist Brace

Cursed item.

| Level | Effect |
|---|---|
| 1-10 | +8 ball speed increment per level, -140% paddle size per level [cursed] |

```
Effect 1
  trigger: always
  outcome: stat(ball_speed_increment, +8 per level)

Effect 2
  trigger: always
  outcome: percentage(paddle_size, -140% per level) [cursed]
```

Base cost: 35 friendship | Scaling: 1.5
