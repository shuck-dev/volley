# Starter Item Effects

Implementation effect blocks for the starter set. Designs and level intent live in `../design/starter-items.md`; this is the impl side. Cost and scaling tuning is TBD throughout.

## Split (ball): the goop ball

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

Split fires on soul consolidation; no dependency on the milestone system. Split balls are ephemeral: `is_temporary = true` (skipped by `BallReconciler` on adoption) with a `source_key` back-reference to the parent. They attach to `BallTracker` so effects and magnetism reach them but never enter `BallReconciler._balls_by_key`. Dragged off-court a split ball is destroyed, not racked (`ball_drag_controller.gd` branches on `is_temporary`). Merge keeps the survivor's `source_key` and takes the max speed and tier of the pair; `on_balls_close` is a per-frame pairwise distance test over `BallTracker.get_balls()`, not a RigidBody contact. Level 3 gates merging to pairs containing the original (the only ball carrying live soul) and tracks a per-cycle fully-merged flag to award the next split's bonus.

## Helmet (equipment): header

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

## Friendship bracelet (equipment)

```
Effect 1 (all levels)
  trigger: on_hit
  outcome: spawn_soul_beads(n; level 2 doubles n)
Effect 2 (all levels)
  trigger: on_bead_gathered
  outcome: bank_soul
Effect 3 (level 3)
  trigger: on_bead_gathered
  outcome: add_ball_speed(off-consolidation: speed that does not count toward the reconciliation cap)
```

Beads auto-gather to the player only; uncollected beads expire at rally end. Ball-through-bead re-collection reuses the merge distance test, not physics contact. Level 3 adds off-consolidation speed per bead.

## Magnetism (equipment): the comeback ball

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

## Pluck (cursor gear): the glove

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

## Engine work

The effect system as built carries five outcome types (`stat`, `stat_until_miss`, `oscillate_stat`, `halve_streak`, `game_action`) and `process_event` returns a payload-free `Array[StringName]`. Every parameterised outcome below is a dedicated Outcome subclass with its own `apply(context)`, not a key on the game-action channel:

- `split_ball`, `merge_balls`, the `on_consolidation` trigger, the `on_balls_close` distance check, the level-3 original-only merge gate, and the fully-merged-in-time split bonus (split).
- `soul_burst` and `bank_soul`, calculated grants through `ItemManager` (split, bracelet); `soul_reward` scaling with a header streak (helmet).
- `add_speed` scaling with header impact velocity, header-streak tracking, and `on_header` / `on_racquet_hit` triggers (helmet).
- `spawn_soul_beads`, bead entities, `on_bead_gathered`, and off-consolidation `add_ball_speed` (bracelet).
- `rescue_ball`, an `on_would_miss` trigger, and a per-consolidation save counter, with the level-3 save shared with the partner (magnetism).
- a held-ball limit above one, a release-flick launch speed, and gating picking behind glove ownership (Pluck).
- `lift_speed_cap`, the `on_whistle` player-input trigger, and `reconcile_now` (Cadence, see `05-items.md`).

Magnetism's pull needs no new primitive; it is a stat effect on the existing `ball_magnetism`, retargeted to the player.
