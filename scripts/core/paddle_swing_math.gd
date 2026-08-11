class_name PaddleSwingMath
extends RefCounted

## Pure math for scaling the swing animation's playback speed to the incoming ball's speed.


## Seconds until the ball reaches the racket hitbox's x position, or -1.0 if the ball is
## effectively stationary on the x-axis (no meaningful contact time to derive).
static func time_to_contact(hitbox_x: float, ball_x: float, ball_velocity_x: float) -> float:
	if absf(ball_velocity_x) < 1.0:
		return -1.0
	return absf(hitbox_x - ball_x) / absf(ball_velocity_x)


## Playback speed multiplier so the animation's contact frame lands on `time_to_contact`,
## clamped to `max_speed_scale`.
static func speed_scale_for_contact_time(
	time_to_contact_seconds: float,
	contact_frame_index: int,
	base_fps: float,
	max_speed_scale: float,
) -> float:
	if time_to_contact_seconds <= 0.0:
		return max_speed_scale

	var natural_seconds: float = contact_frame_index / base_fps
	return clampf(natural_seconds / time_to_contact_seconds, 0.0, max_speed_scale)
