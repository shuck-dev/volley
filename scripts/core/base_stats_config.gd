class_name BaseStatsConfig
extends Resource

## Player paddle vertical speed in pixels per second.
@export var paddle_speed := 560.0
## Player paddle vertical extent in pixels at full size.
@export var paddle_size := 54.0
## Floor for paddle_size; paddle never shrinks below this.
@export var paddle_size_min := 27.0
## Slowest a ball ever travels; reset target on miss-to-rest and rally start.
@export var ball_speed_min := 450.0
## Range above ball_speed_min; effective max ball speed = min + this.
@export var ball_speed_max_range := 340.0
## Speed bump applied to the ball on each successful paddle hit.
@export var ball_speed_increment := 17.0
## Friendship points awarded per paddle hit; items can percentage-modify.
@export var friendship_points_per_hit := 1.0
## Per-frame pull strength of the ball toward the nearest paddle; 0.0 disables magnetism.
@export var ball_magnetism := 0.0
## Strength of the bias that lerps return angles toward horizontal after a hit; 0.0 disables.
@export var return_angle_influence := 0.0
## Number of equipment slots in the player's kit; item-tunable, not yet read in production.
@export var kit_slots := 3.0
## Additive offset applied on top of ball_speed_min when computing the rally floor.
@export var ball_speed_offset := 0.0
## Arena vertical extent in pixels; clamps paddle motion and paddle_size.
@export var arena_height := 660.0


func to_dict() -> Dictionary:
	return {
		&"paddle_speed": paddle_speed,
		&"paddle_size": paddle_size,
		&"paddle_size_min": paddle_size_min,
		&"ball_speed_min": ball_speed_min,
		&"ball_speed_max_range": ball_speed_max_range,
		&"ball_speed_increment": ball_speed_increment,
		&"friendship_points_per_hit": friendship_points_per_hit,
		&"ball_magnetism": ball_magnetism,
		&"return_angle_influence": return_angle_influence,
		&"kit_slots": kit_slots,
		&"ball_speed_offset": ball_speed_offset,
		&"arena_height": arena_height,
	}
