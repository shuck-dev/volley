class_name PlayerPaddle
extends Paddle

@export var low_anchor: Marker2D

var _default_racket_position: Vector2
var _development_offset := Vector2.ZERO
var _low_states := [&"ready_grounded_low", &"swing_grounded_low"]


func _ready() -> void:
	super()

	if racket_hitbox != null:
		_default_racket_position = racket_hitbox.position


func _physics_move(_delta: float) -> void:
	var direction := Input.get_axis("paddle_up", "paddle_down")
	if direction > 0.0 and is_grounded():
		velocity = Vector2.ZERO
		return
	velocity = Vector2(0.0, direction * _paddle_speed)
	move_and_slide()
	position.x = _lane_x
	clamp_to_arena()


func _on_animation_state_changed(state: StringName) -> void:
	super(state)

	if racket_hitbox == null or low_anchor == null:
		return

	if state in _low_states:
		racket_hitbox.position = low_anchor.position + _development_offset
	else:
		racket_hitbox.position = _default_racket_position + _development_offset

	_refresh_overlay_shapes()


func _is_crouching() -> bool:
	return is_grounded() and Input.is_action_pressed("paddle_down")


func set_racket_position_x(offset_x: float) -> void:
	_development_offset.x = offset_x
	var state := get_movement_state()
	_on_animation_state_changed(state)


func set_racket_position_y(offset_y: float) -> void:
	_development_offset.y = offset_y
	var state := get_movement_state()
	_on_animation_state_changed(state)
