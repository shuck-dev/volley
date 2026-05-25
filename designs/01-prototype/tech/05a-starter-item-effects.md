# Starter Item Effect Blocks

Tech spike for the starter items (SH-436): each effect as trigger, condition, outcome, plus the engine work each needs against the system as built. Numbers are tuning, left open. Cadence is already specced among the prototype effect blocks.

Soul is the canonical name for the currency the code still calls `friendship` (`ItemManager.add_friendship_points`, `friendship_points_per_hit`). The rename is pending and tracked separately; every soul outcome below routes through that existing economy path.

## Split (ball)

```
Effect 1
  trigger: on_consolidation
  outcome: split_ball(count = current_tier + 1)
Effect 2
  trigger: on_balls_close
  outcome: merge_balls
  outcome: soul_burst(scale_by current_tier)
```

Split fires at the consolidation beat, not on a tier-ladder event; the only read of the tier ladder is `current_tier` for the count, so there is no dependency on the unbuilt SH-88 system.

Split balls are ephemeral. They carry `is_temporary = true` (the flag `BallReconciler` already skips on adoption) and a `source_key` back-reference to the parent item. They attach to `BallTracker` so effects and magnetism reach them, but never enter `BallReconciler._balls_by_key`, so the save providers and reconcile never see them. Dragged off-court a split ball is destroyed, not racked: the drag controller's off-court path (`ball_drag_controller.gd`) branches on `is_temporary`.

Merge keeps the survivor's `source_key` (both copies share it, so no key arbitration) and takes the max speed and tier of the pair. `on_balls_close` is a per-frame pairwise distance check over `BallTracker.get_balls()`, not a RigidBody contact: closing speed up to twice world-max is the tunnelling regime, and a distance test sidesteps CCD.

Levels and cost/scaling: TBD.

## Helmet (equipment)

```
grants: header (reworked racquet contact, struck with the head)
Effect 1
  trigger: on_header_at_apex
  outcome: soul_burst
```

The header reworks the existing racquet collision rather than adding a head collider or a second input path. Apex is an enumerated arc phase: the ball's arc state gains an APEX value between rising and falling, built on the `bound_y` / PLAY_ARC machinery already in `ball.gd`, and `on_header_at_apex` fires only in that phase. Levels (burst size) and cost/scaling: TBD.

## Friendship bracelet (equipment)

```
Effect 1
  trigger: on_hit
  outcome: spawn_soul_motes(n)
Effect 2
  trigger: on_mote_gathered
  outcome: soul_burst
```

Motes auto-gather to the player only; uncollected motes expire at rally end. Ball-through-mote re-collection reuses the merge distance test, not physics contact. Levels (motes per hit) and cost/scaling: TBD.

## Magnetism (equipment)

```
Effect 1
  trigger: always
  outcome: stat(ball_magnetism, +strength)
```

Mostly built: `ball_magnetism` is a registered stat and `BallEffectProcessor._apply_magnetism` already pulls each ball toward a paddle every frame. The delta is retargeting that pull to the player only; today it picks the nearest paddle. So this is a stat always-effect, not a new primitive. Levels (strength) and cost/scaling: TBD.

## Engine work

The effect system as built carries five outcome types (`stat`, `stat_until_miss`, `oscillate_stat`, `halve_streak`, `game_action`), and `process_event` returns a payload-free `Array[StringName]`. So every outcome below that carries a parameter is a dedicated Outcome subclass with its own `apply(context)`, not a key on the game-action channel:

- `split_ball`, `merge_balls`, an `on_consolidation` trigger, and an `on_balls_close` distance check (split).
- `soul_burst`, a calculated grant through `ItemManager.add_friendship_points` (split, helmet, bracelet).
- `spawn_soul_motes` plus mote entities and an `on_mote_gathered` trigger (bracelet).
- a reworked racquet contact and an `on_header_at_apex` trigger keyed to the arc-phase enum (helmet).

Magnetism needs no new primitive; it is a stat effect on the existing `ball_magnetism` pull, retargeted to the player.
