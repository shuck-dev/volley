class_name ComebackBall
extends Ball

## How fast the ball's heading turns toward the paddle once attraction is active.
@export var attract_degrees_per_second: float = 30.0

## Distance to the paddle within which attraction can activate.
@export var attract_range: float = 400.0

var _ball_reconciler: BallReconciler


func _ready() -> void:
	super._ready()
	_ball_reconciler = get_parent() as BallReconciler


func _physics_process(delta: float) -> void:
	if linear_velocity == Vector2.ZERO:
		return

	if play_state == PlayState.PLAY_NORMAL or play_state == PlayState.PLAY_ARC:
		_attract(delta)

	super._physics_process(delta)


func _attract(delta: float) -> void:
	if _ball_reconciler == null or _ball_reconciler.player_paddle == null:
		return

	var to_paddle: Vector2 = _ball_reconciler.player_paddle.global_position - global_position
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


func _on_miss_zone_body_entered(_body: Node) -> void:
	pass
