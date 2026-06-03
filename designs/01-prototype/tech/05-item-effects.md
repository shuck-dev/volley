# Item Effect Blocks

Per-item effect definitions, level tables, and cost/scaling for the prototype item set. Designs live in [`../design/items.md`](../design/items.md) (the causality and stat items) and [`../design/starter-items.md`](../design/starter-items.md) (the starter items).

Cost formula: `cost = base_cost * scaling ^ current_level`. Level 1 cost is `base_cost`. Starter-item cost and scaling are TBD.

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
  outcome: multiply_stat_temporary(soul_per_hit, random_colour_tier, until_next_trigger)
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
  outcome: award_soul(scale_by: ball_speed)
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
  outcome: multiply_stat(soul_per_hit, scale_by: crack_count)

Effect 2
  trigger: on_miss
  outcome: increment_degradation(1) [hidden]

Effect 3 (broken state)
  trigger: always
  condition: degradation_at(100)
  outcome: stat(soul_per_hit, -debuff)
```

Base cost: 90 friendship | Scaling: 1.5

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

---

## Starter items

### Split (ball): the goop ball

```
Effect 1 (all levels)
  trigger: on_consolidation
  outcome: split_ball(level 1: to two; levels 2-3: one more each consolidation)
Effect 2 (levels 1-2)
  trigger: on_balls_close
  outcome: merge_balls (any pair)
  outcome: soul_burst(scale_by count merged)
Effect 3 (level 3)
  trigger: on_balls_close
  condition: one of the pair is the original (source) ball
  outcome: merge_balls (only the original absorbs; husk pairs do not merge)
  outcome: soul_burst(scale_by count merged)
Effect 4 (level 3)
  trigger: on_consolidation
  condition: the court was folded back to the single original before this consolidation
  outcome: split_bonus(+1 to this split) [snowballs while the player keeps fully merging in time]
```

Split fires on soul consolidation; no dependency on the milestone system. Split balls are ephemeral: `is_temporary = true` (skipped by `BallReconciler` on adoption) with a `source_key` back-reference to the parent. They attach to `BallTracker` so effects and magnetism reach them but never enter `BallReconciler._balls_by_key`. Dragged off-court a split ball is destroyed, not racked (`item_drag_controller.gd` branches on `is_temporary`). Merge keeps the survivor's `source_key` and takes the max speed and tier of the pair; `on_balls_close` is a per-frame pairwise distance test over `BallTracker.get_balls()`, not a RigidBody contact. Level 3 gates merging to pairs containing the original (the only ball carrying live soul) and tracks a per-cycle fully-merged flag to award the next split's bonus.

### Helmet (equipment): header

```
grants: header (reworked racquet contact, struck with the head)
Effect 1 (levels 2-3)
  trigger: on_header
  outcome: add_speed(steps scale with header impact velocity; a normal hit adds one step)
Effect 2 (level 3)
  trigger: on_header
  outcome: increment_header_streak
  outcome: soul_reward(scale_by header_streak)
Effect 3 (level 3)
  trigger: on_racquet_hit or on_miss
  outcome: reset_header_streak
```

The header reworks the existing racquet collision rather than adding a head collider or a second input path. Level 1 grants the contact with no further effect. Level 2 reads the contact's impact velocity (how hard the player rams) and adds speed steps on top of the normal per-hit increment. Level 3 rewards consecutive headers with a growing soul reward; any racquet hit or miss resets the streak. The earlier apex-burst is dropped.

### Friendship bracelet (equipment)

```
Effect 1 (all levels)
  trigger: on_hit
  outcome: spawn_soul_beads(n; level 2 doubles n)
Effect 2 (all levels)
  trigger: on_bead_gathered
  outcome: bank_soul
Effect 3 (level 3)
  trigger: on_bead_gathered
  outcome: add_ball_speed(off-consolidation: speed that does not count toward the consolidation cap)
```

Beads auto-gather to the player only; uncollected beads expire at rally end. Ball-through-bead re-collection reuses the merge distance test, not physics contact. Level 3 adds off-consolidation speed per bead.

### Magnetism (equipment): the comeback ball

```
Effect 1 (all levels)
  trigger: always
  outcome: stat(ball_magnetism, +strength) [pull toward where the player reaches]
Effect 2 (levels 2-3)
  trigger: on_would_miss
  condition: the cycle's save is unspent
  outcome: rescue_ball(semicircle the ball back into play); spend the cycle's save
Effect 3 (level 3)
  trigger: on_would_miss (player or partner side)
  note: the single per-consolidation save covers either side, first to need it
```

`ball_magnetism` is a registered stat and `BallEffectProcessor._apply_magnetism` already pulls each ball toward a paddle every frame; the level-1 delta is retargeting that pull to the player (today it picks the nearest paddle). Levels 2-3 add a once-per-consolidation rescue: an `on_would_miss` trigger, a per-cycle save counter reset on consolidation, and a semicircle return path. Level 3 lets the partner's near-miss consume the same single save.

### Cadence (equipment): the whistle

| Level | Behaviour |
|---|---|
| 1 | Ball speed rises and falls in a steady rhythm |
| 2 | The speed cap lifts so the ball climbs past max instead of consolidating there; the player consolidates on demand by blowing the whistle, and the longer they wait the bigger the step up |
| 3 | The rhythm turns uneven, its fast and slow stretches changing length so the fast moment is no longer predictable |

```
Effect 1 (all levels)
  trigger: always
  outcome: oscillate_stat(ball_speed_offset, scales with level)
  level 3: randomise the oscillation period (the fast and slow stretch lengths), not the peak speed, so the rhythm reads irregular

Effect 2 (levels 2-3)
  trigger: always
  outcome: lift_speed_cap (ball climbs past ball_speed_max without auto-consolidating at the limit)

Effect 3 (levels 2-3)
  trigger: on_whistle (player input)
  outcome: consolidate_now (consolidate at current speed; the floor raise scales with how far past the old cap)
```

Base cost: 85 friendship | Scaling: 1.5

### Pluck (cursor gear): the glove

```
grants: pick (the cursor grabs a ball in play; held balls enter OUT_HELD, frozen and miss-suppressed)
Effect 1 (level 1)
  outcome: hold one ball; release rejoins the rally at its held speed
Effect 2 (level 2)
  outcome: raise the held-ball limit above one
Effect 3 (level 3)
  outcome: launch a held ball on release, speed set by the release-flick velocity
```

Picking already exists in the engine for any in-play ball (`grab_area.gd` to `grab_live_ball`, the `OUT_HELD` state, release velocity from `_compute_release_velocity`). Pluck's work is gating that ability behind owning the glove, raising the single-held-ball limit (the drag controller refuses a second grab today), and reading the flick to set launch speed at level 3. Cursor gear is a proposed fourth role (SH-441).

---

## Engine work

The effect system as built carries five outcome types (`stat`, `stat_until_miss`, `oscillate_stat`, `halve_streak`, `game_action`) and `process_event` returns a payload-free `Array[StringName]`. Every parameterised outcome below is a dedicated Outcome subclass with its own `apply(context)`, not a key on the game-action channel:

- `split_ball`, `merge_balls`, the `on_consolidation` trigger, the `on_balls_close` distance check, the level-3 original-only merge gate, and the fully-merged-in-time split bonus (split).
- `soul_burst` and `bank_soul`, calculated grants through `ItemManager` (split, bracelet); `soul_reward` scaling with a header streak (helmet).
- `add_speed` scaling with header impact velocity, header-streak tracking, and `on_header` / `on_racquet_hit` triggers (helmet).
- `spawn_soul_beads`, bead entities, `on_bead_gathered`, and off-consolidation `add_ball_speed` (bracelet).
- `rescue_ball`, an `on_would_miss` trigger, and a per-consolidation save counter, with the level-3 save shared with the partner (magnetism).
- a held-ball limit above one, a release-flick launch speed, and gating picking behind glove ownership (Pluck).
- `lift_speed_cap`, the `on_whistle` player-input trigger, and `consolidate_now` (Cadence).

Magnetism's pull needs no new primitive; it is a stat effect on the existing `ball_magnetism`, retargeted to the player.
