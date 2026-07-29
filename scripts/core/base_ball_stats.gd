class_name BaseBallStats
extends Resource

## Slowest a ball ever travels; reset target on miss-to-rest and rally start.
@export var ball_speed_min := 450.0
## Fastest a ball may travel.
@export var ball_speed_max := 790.0
## Speed bump applied to the ball on each successful paddle hit.
@export var ball_speed_increment := 17.0
## Soul awarded per paddle hit; items can percentage-modify.
@export var soul_per_hit := 1.0


func to_dict() -> Dictionary:
	return {
		&"ball_speed_min": ball_speed_min,
		&"ball_speed_max": ball_speed_max,
		&"ball_speed_increment": ball_speed_increment,
		&"soul_per_hit": soul_per_hit,
	}
