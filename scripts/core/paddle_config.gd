class_name PaddleConfig
extends Resource

## Paddle tunables: travel speed, height range, and bounce-direction stats.

## Maximum paddle travel speed in pixels per second.
@export var paddle_speed := 560.0
## Default paddle height in pixels.
@export var paddle_size := 54.0
## Maximum return-angle magnitude (degrees off horizontal) when the ball strikes the paddle edge.
@export_range(0.0, 90.0) var paddle_return_angle_max_degrees := 0.0
## Scales paddle vertical velocity into a bounce-angle bias (radians per pixel/sec).
@export_range(0.0, 0.05) var paddle_english_coefficient := 0.0
## Dead-zone floor (degrees off horizontal); bounces never land closer than this to pure horizontal.
@export_range(0.0, 30.0) var paddle_bounce_min_angle_degrees := 3.0
## Ceiling (degrees off horizontal); bounces never land closer than this to pure vertical.
@export_range(0.0, 90.0) var paddle_bounce_max_angle_degrees := 87.0


func to_dict() -> Dictionary:
	return {
		&"paddle_speed": paddle_speed,
		&"paddle_size": paddle_size,
		&"paddle_return_angle_max_degrees": paddle_return_angle_max_degrees,
		&"paddle_english_coefficient": paddle_english_coefficient,
		&"paddle_bounce_min_angle_degrees": paddle_bounce_min_angle_degrees,
		&"paddle_bounce_max_angle_degrees": paddle_bounce_max_angle_degrees,
	}
