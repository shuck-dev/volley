class_name PlayerPaddle
extends Paddle


func _physics_process(_delta: float) -> void:
	var direction := Input.get_axis("paddle_up", "paddle_down")
	velocity = Vector2(0.0, direction * _paddle_speed)
	move_and_slide()
	position.x = _lane_x
	clamp_to_arena()

	# Resolve the animation state after moving; this override shadows the base _physics_process,
	# so the shared FSM tick must be invoked here or the player paddle's state never updates.
	tick_animation_state()
