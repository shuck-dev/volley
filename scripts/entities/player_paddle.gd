class_name PlayerPaddle
extends Paddle

## Racket position while grounded-low; swapped in for crouch/low-hit animation states.
@export var low_anchor: Marker2D

## Racket position while grounded, upright; swapped in for the standing ready/swing animations.
@export var mid_anchor: Marker2D

## What soul motes land on to be collected by the player.
@export var soul_catcher: SoulCatcher

var _default_racket_position: Vector2
var _low_states := [&"ready_grounded_low", &"swing_grounded_low"]
var _mid_states := [&"ready_grounded", &"swing_grounded"]


func _ready() -> void:
	_default_racket_position = racket_hitbox.position

	super()


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


func _on_animation_state_changed(state: StringName) -> void:
	super(state)

	if state in _low_states:
		racket_hitbox.position = low_anchor.position
	elif state in _mid_states:
		racket_hitbox.position = mid_anchor.position
	else:
		racket_hitbox.position = _default_racket_position


## Manual play uses down key; autoplay usus AI's predicted low-stance decision
func _is_crouching() -> bool:
	if not is_grounded():
		return false
	if input_blocked:
		return wants_low_stance
	return Input.is_action_pressed("paddle_down")
