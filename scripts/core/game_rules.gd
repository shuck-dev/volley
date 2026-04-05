class_name GameRules
extends RefCounted

const BASE_STATS: Dictionary = {
	&"paddle_speed": 500.0,
	&"paddle_size": 50.0,
	&"paddle_size_min": 50.0,
	&"ball_speed_min": 400.0,
	&"ball_speed_max_range": 300.0,
	&"ball_speed_increment": 15.0,
	&"friendship_points_per_hit": 1.0,
	&"ball_magnetism": 0.0,
	&"return_angle_influence": 0.0,
	&"kit_slots": 3.0,  # float: effect system operates on floats; cast to int at point of use
	&"ball_speed_offset": 0.0,
	&"arena_height": 986.0,
}
