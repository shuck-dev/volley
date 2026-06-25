class_name PlayerPaddle
extends Paddle

var _base_racket_y: float = 0.0


func _ready() -> void:
	super()

	if racket_hitbox != null:
		_base_racket_y = racket_hitbox.position.y


func _physics_move(_delta: float) -> void:
	if input_blocked:
		return
	var direction := Input.get_axis("paddle_up", "paddle_down")
	if direction > 0.0 and is_grounded():
		velocity = Vector2.ZERO
		return
	velocity = Vector2(0.0, direction * _paddle_speed)
	move_and_slide()
	position.x = _lane_x
	clamp_to_arena()

	if racket_hitbox == null or _body_shape == null or _racket_shape == null:
		return

	if is_grounded() and Input.is_action_pressed("paddle_down"):
		racket_hitbox.position.y = (
			collision.position.y + _body_shape.size.y * 0.5 - _racket_shape.size.y * 0.5
		)
	else:
		racket_hitbox.position.y = _base_racket_y

	_refresh_overlay_shapes()


func _is_crouching() -> bool:
	return is_grounded() and Input.is_action_pressed("paddle_down")
