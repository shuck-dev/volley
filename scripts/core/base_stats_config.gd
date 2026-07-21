class_name BaseStatsConfig
extends Resource

## Slowest a ball ever travels; reset target on miss-to-rest and rally start.
@export var ball_speed_min := 450.0
## Range above ball_speed_min; effective max ball speed = min + this.
@export var ball_speed_max_range := 340.0
## Speed bump applied to the ball on each successful paddle hit.
@export var ball_speed_increment := 17.0
## Soul awarded per paddle hit; items can percentage-modify.
@export var soul_per_hit := 1.0
## Per-frame pull strength of the ball toward the nearest paddle; 0.0 disables magnetism.
@export var ball_magnetism := 0.0
## Additive offset applied on top of ball_speed_min when computing the rally floor.
@export var ball_speed_offset := 0.0
## Arena vertical extent in pixels; upper bound for the paddle and the AI math half-height.
@export var arena_height := 660.0


func to_dict() -> Dictionary:
	return {
		&"ball_speed_min": ball_speed_min,
		&"ball_speed_max_range": ball_speed_max_range,
		&"ball_speed_increment": ball_speed_increment,
		&"soul_per_hit": soul_per_hit,
		&"ball_magnetism": ball_magnetism,
		&"ball_speed_offset": ball_speed_offset,
		&"arena_height": arena_height,
	}
