class_name BaseStatsConfig
extends Resource

@export var paddle_speed := 560.0
@export var paddle_size := 54.0
@export var paddle_size_min := 45.0
@export var ball_speed_min := 450.0
@export var ball_speed_max_range := 340.0
@export var ball_speed_increment := 17.0
@export var friendship_points_per_hit := 1.0
@export var ball_magnetism := 0.0
@export var return_angle_influence := 0.0
@export var kit_slots := 3.0
@export var ball_speed_offset := 0.0
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
