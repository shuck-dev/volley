# Starter Item Effect Blocks

Tech spike for the starter items (SH-436): each effect as trigger, condition, outcome, plus the primitives the effect system would need. Numbers are tuning, left open. Cadence is already specced among the prototype effect blocks.

## Split (ball)

```
Effect 1
  trigger: on_tier_completed(tier)
  outcome: split_ball(count = tier + 1)
Effect 2
  trigger: on_balls_collide
  outcome: merge_balls
  outcome: soul_burst(scale_by tier)
```

Split count rises with the tier; merging is the player driving two balls together. Levels and cost/scaling: TBD.

## Helmet (equipment)

```
grants: header (a head contact, distinct from the racquet)
Effect 1
  trigger: on_header_at_apex
  outcome: soul_burst
```

Levels (burst size) and cost/scaling: TBD.

## Friendship bracelet (equipment)

```
Effect 1
  trigger: on_hit
  outcome: spawn_soul_motes(n)
Effect 2
  trigger: on_mote_gathered
  outcome: add_soul
```

Motes drift to the player and auto-gather; routing the ball through them gathers more. Levels (motes per hit) and cost/scaling: TBD.

## Magnetism (equipment)

```
Effect 1
  trigger: always
  outcome: attract_balls_to_characters(strength)
```

A passive pull of every ball toward the player and partner. Levels (strength) and cost/scaling: TBD.

## New primitives the effect system needs

- `header` contact and an `on_header_at_apex` trigger (helmet).
- `split_ball`, an `on_balls_collide` trigger, `merge_balls` (split).
- `spawn_soul_motes` plus mote entities and an `on_mote_gathered` trigger (bracelet).
- `attract_balls_to_characters`, a passive force (magnetism).
- `soul_burst` outcome (shared).
