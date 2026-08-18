class_name ComebackBall
extends Ball


class RescueState:
	var active := false
	var swept_degrees := 0.0
	var sweep_sign := 1.0


## How fast the ball's heading turns toward the paddle once attraction is active.
@export var attract_degrees_per_second: float = 30.0

## Distance to the paddle within which attraction can activate.
@export var attract_range: float = 400.0

## How fast a rescue turns the ball's heading around, in degrees per second.
@export var rescue_degrees_per_second: float = 360.0

var _ball_tracker: Node
var _rescue_available := true
var _rescue := RescueState.new()


func _ready() -> void:
	super._ready()
	_ball_tracker = get_parent()
	if not tier_advanced.is_connected(_on_tier_advanced):
		tier_advanced.connect(_on_tier_advanced)


func _physics_process(delta: float) -> void:
	if _rescue.active:
		rescuing(delta)
		return

	if linear_velocity == Vector2.ZERO:
		return

	if play_state == PlayState.PLAY_NORMAL or play_state == PlayState.PLAY_ARC:
		_attract(delta)

	super._physics_process(delta)


func _on_tier_advanced(_ball: Ball, _new_tier: int) -> void:
	_rescue_available = true


func _attract(delta: float) -> void:
	var paddle_position: Variant = _ball_tracker.get_player_paddle_position()
	if paddle_position == null:
		return

	var to_paddle: Vector2 = paddle_position - global_position
	if to_paddle.length() > attract_range:
		return

	var current_direction: Vector2 = linear_velocity.normalized()
	if current_direction.dot(to_paddle.normalized()) <= 0.0:
		return

	var target_direction: Vector2 = Vector2(linear_velocity.x, to_paddle.y).normalized()

	var max_turn_radians: float = deg_to_rad(attract_degrees_per_second) * delta
	var turn_radians: float = clampf(
		current_direction.angle_to(target_direction), -max_turn_radians, max_turn_radians
	)

	linear_velocity = current_direction.rotated(turn_radians) * linear_velocity.length()


func _on_miss_zone_body_entered(body: Node) -> void:
	if body == self and rescue():
		return

	super._on_miss_zone_body_entered(body)

	if body == self and not _suppress_miss_detection:
		_rescue_available = true


func rescue() -> bool:
	if _suppress_miss_detection or not _rescue_available:
		return false

	_rescue_available = false
	_rescue.active = true
	_rescue.swept_degrees = 0.0
	_rescue.sweep_sign = _rescue_sweep_sign()
	_suppress_miss_detection = true

	return true


## Sweeping toward the paddle's side means curving down if it's below, up if it's above.
func _rescue_sweep_sign() -> float:
	var paddle_position: Variant = _ball_tracker.get_player_paddle_position()
	if paddle_position == null:
		return 1.0

	var sweep_sign: float = signf(global_position.y - paddle_position.y)
	return sweep_sign if sweep_sign != 0.0 else 1.0


func rescuing(delta: float) -> void:
	_update_play_state()

	var turn_radians: float = deg_to_rad(rescue_degrees_per_second) * delta * _rescue.sweep_sign
	linear_velocity = linear_velocity.rotated(turn_radians).normalized() * scaled_speed
	_rescue.swept_degrees += rescue_degrees_per_second * delta

	if _rescue.swept_degrees < 180.0:
		return

	_rescue.active = false
	_suppress_miss_detection = false
