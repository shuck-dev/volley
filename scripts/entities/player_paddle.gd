class_name PlayerPaddle
extends Paddle

@export var low_anchor: Marker2D

var _dev_offset := Vector2.ZERO
var _low_states := [&"ready_grounded_crouch", &"low_swing_grounded"]


func _ready() -> void:
	super()


func _physics_move(_delta: float) -> void:
	var direction := Input.get_axis("paddle_up", "paddle_down")
	if direction > 0.0 and is_grounded():
		velocity = Vector2.ZERO
		return
	velocity = Vector2(0.0, direction * _paddle_speed)
	move_and_slide()
	position.x = _lane_x
	clamp_to_arena()


func _apply_racket_position(state: StringName) -> void:
	if racket_hitbox == null:
		return

	if state in _low_states and low_anchor != null:
		racket_hitbox.position = low_anchor.position
	else:
		racket_hitbox.position = _default_racket_pos

	racket_hitbox.position += _dev_offset
	_refresh_overlay_shapes()


func _is_crouching() -> bool:
	return is_grounded() and Input.is_action_pressed("paddle_down")


func set_racket_position_x(offset_x: float) -> void:
	_dev_offset.x = offset_x
	_apply_racket_position(get_movement_state())


func set_racket_position_y(offset_y: float) -> void:
	_dev_offset.y = offset_y
	_apply_racket_position(get_movement_state())
