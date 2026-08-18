class_name BaseBallStats
extends Resource

## Slowest a ball ever travels; reset target on miss-to-rest and rally start.
@export var ball_speed_min := 450.0

## Fastest a ball may travel.
@export var ball_speed_max := 790.0

## Speed bump applied to the ball on each successful paddle hit.
@export var ball_speed_increment := 17.0

## Scales the consolidation reward.
@export var consolidation_multiplier := 1.0
