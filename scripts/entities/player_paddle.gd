class_name PlayerPaddle
extends Paddle

@export var low_anchor: Marker2D

var _default_racket_position: Vector2
var _low_states := [&"ready_grounded_low", &"low_swing_grounded"]


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

	var current_offset := racket_hitbox.position
	var anchor_position: Vector2

	if state in _low_states:
		anchor_position = low_anchor.position
	else:
		anchor_position = _default_racket_position

	current_offset -= anchor_position
	racket_hitbox.position = anchor_position + current_offset
	_refresh_overlay_shapes()


func _is_crouching() -> bool:
	return is_grounded() and Input.is_action_pressed("paddle_down")
