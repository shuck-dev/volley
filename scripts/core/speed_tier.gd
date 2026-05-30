class_name SpeedTier
extends Resource

## One rung of the speed ladder. Bounds are fractions of the derived world max so widening the court rescales the whole ladder.

## Tier entry speed as a fraction of BALL_WORLD_MAX_SPEED.
@export_range(0.0, 1.0) var floor_fraction := 0.0
## Tier ceiling speed as a fraction of BALL_WORLD_MAX_SPEED; crossing it completes the tier.
@export_range(0.0, 1.0) var ceiling_fraction := 0.0
## Per-tier promotion of the flat ball_speed_max_range stat, as a fraction of BALL_WORLD_MAX_SPEED.
@export_range(0.0, 1.0) var max_range_fraction := 0.0
## Reward key fired on tier completion; empty means no reward.
@export var reward := ""
