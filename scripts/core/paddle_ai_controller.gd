class_name PaddleAIController
extends Node

@export var paddle: CharacterBody2D
@export var config: PaddleAIConfig

var ball: RigidBody2D

var _enabled := false
var _tracker: BallTracker

# --- reaction delay ---
var _position_buffer: Array[float]
var _position_buffer_index := 0

# --- noise ---
var _noise_offset := 0.0
var _last_ball_direction_x := 0.0


func _ready() -> void:
	_init_position_buffer()


func _init_position_buffer() -> void:
	_position_buffer.resize(config.reaction_delay_frames)
	_position_buffer.fill(0.0)


## Replaces Court-mediated `controller.ball = ...` injection; the tracker drives enable/disable lifecycle.
func bind_tracker(tracker: BallTracker) -> void:
	if _tracker == tracker:
		return
	if _tracker != null:
		if _tracker.ball_added.is_connected(_on_tracker_ball_added):
			_tracker.ball_added.disconnect(_on_tracker_ball_added)
		if _tracker.ball_removed.is_connected(_on_tracker_ball_removed):
			_tracker.ball_removed.disconnect(_on_tracker_ball_removed)
		if _tracker.current_ball_changed.is_connected(_on_tracker_current_ball_changed):
			_tracker.current_ball_changed.disconnect(_on_tracker_current_ball_changed)
	_tracker = tracker
	if _tracker == null:
		return
	_tracker.ball_added.connect(_on_tracker_ball_added)
	_tracker.ball_removed.connect(_on_tracker_ball_removed)
	_tracker.current_ball_changed.connect(_on_tracker_current_ball_changed)

	var existing: Ball = _tracker.get_current_ball()
	ball = existing

	# Route already-tracked balls through the handler so subclass enable-lifecycle fires.
	if existing != null:
		_on_tracker_ball_added(existing)


## The live ball is whichever the tracker treats as current; a STORED ball never becomes current.
func _on_tracker_current_ball_changed(new_current: Ball) -> void:
	ball = new_current


## Override hook for subclass enable-lifecycle; the live ball ref follows current_ball_changed.
func _on_tracker_ball_added(_new_ball: Ball) -> void:
	pass


func _on_tracker_ball_removed(_old_ball: Ball) -> void:
	pass


func _physics_process(_delta: float) -> void:
	if not _enabled or ball == null:
		return

	_maybe_resample_noise()

	if not _ball_in_play():
		_drift_to_center()
		return

	if _ball_approaching():
		_track()
	else:
		_drift_to_center()


func _ball_in_play() -> bool:
	var state: Ball.PlayState = ball.play_state
	return state == Ball.PlayState.PLAY_NORMAL or state == Ball.PlayState.PLAY_ARC


## Silent no-op when enabling with no live ball: toggle key presses must not crash or warn.
func set_enabled(value: bool) -> void:
	if value and ball == null:
		return
	_enabled = value


func is_enabled() -> bool:
	return _enabled


## Override: which ball x-direction counts as "coming toward me."
func _ball_approaching() -> bool:
	assert(false, "PaddleAIController._ball_approaching() is abstract")
	return false


## Override: the paddle's movement speed ceiling.
func _get_paddle_speed() -> float:
	assert(false, "PaddleAIController._get_paddle_speed() is abstract")
	return 0.0


func _track() -> void:
	var bound_y: float = ball.bound_y
	var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
	var predicted_y: float = PaddleAIMath.predict_intercept(
		ball.position, ball.linear_velocity, paddle.position.x, bound_y, gravity
	)
	var noisy_target: float = predicted_y + _noise_offset

	var delayed_target: float = _apply_reaction_delay(noisy_target)
	var difference: float = delayed_target - paddle.position.y
	var max_speed: float = _get_paddle_speed() * config.speed_scale

	var target_velocity: float
	if abs(difference) < config.snap_threshold:
		target_velocity = 0.0
	else:
		target_velocity = sign(difference) * max_speed

	var smoothed_velocity: float = lerpf(
		paddle.velocity.y, target_velocity, config.velocity_smoothing
	)
	paddle.drive(smoothed_velocity)


func _drift_to_center() -> void:
	var center_difference: float = -paddle.position.y
	var drift_speed: float = _get_paddle_speed() * config.speed_scale * config.center_drift_scale
	var drift_velocity: float = clampf(center_difference, -drift_speed, drift_speed)
	var smoothed_velocity: float = lerpf(
		paddle.velocity.y, drift_velocity, config.center_drift_smoothing
	)
	paddle.drive(smoothed_velocity)


func _apply_reaction_delay(target_y: float) -> float:
	var delayed: float = _position_buffer[_position_buffer_index]
	_position_buffer[_position_buffer_index] = target_y
	_position_buffer_index = ((_position_buffer_index + 1) % config.reaction_delay_frames)
	return delayed


## Noise is sampled once per ball flight (when ball changes x-direction),
## not every frame. This makes the AI commit to a slightly wrong position.
func _maybe_resample_noise() -> void:
	var current_direction_x: float = ball.linear_velocity.x
	if sign(current_direction_x) != sign(_last_ball_direction_x):
		_noise_offset = PaddleAIMath.random_offset(config.noise)
	_last_ball_direction_x = current_direction_x
