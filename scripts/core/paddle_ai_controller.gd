class_name PaddleAIController
extends Node

@export var paddle: Paddle
@export var config: PaddleAIConfig

var ball: Ball

var _enabled := false

# --- reaction delay ---
var _position_buffer: Array[float]
var _position_buffer_index := 0

# --- noise ---
var _noise_offset := 0.0
var _last_ball_direction_x := 0.0


func _ready() -> void:
	_init_position_buffer()

	BallTracker.ball_added.connect(_on_tracker_ball_added)
	BallTracker.ball_removed.connect(_on_tracker_ball_removed)


func _exit_tree() -> void:
	BallTracker.ball_added.disconnect(_on_tracker_ball_added)
	BallTracker.ball_removed.disconnect(_on_tracker_ball_removed)


func _physics_process(_delta: float) -> void:
	if not _enabled:
		return

	ball = _select_tracked_ball()

	if ball == null:
		return

	_maybe_offset_position()

	if not _ball_in_play(ball):
		_drift_to_center()
		return

	if _ball_approaches(ball):
		_track()
	else:
		_drift_to_center()


func _init_position_buffer() -> void:
	_position_buffer.resize(config.reaction_delay_frames)
	_position_buffer.fill(0.0)


func _on_tracker_ball_added(new_ball: Ball) -> void:
	ball = new_ball


## Autoplay is a player intent toggle; transient ball-replacement (grab + drop) must not flip it off.
func _on_tracker_ball_removed(_old_ball: Ball) -> void:
	var remaining: Array[Ball] = BallTracker.get_balls()
	ball = remaining.back() if not remaining.is_empty() else null


## Soonest-to-arrive in-play approaching ball; signal-bound `ball` when none qualifies.
func _select_tracked_ball() -> Ball:
	var best: Ball = BallTracker.get_closest_approaching_ball(
		paddle.position.x, -_court_side_sign()
	)
	return best if best != null else ball


func _ball_in_play(target: Ball) -> bool:
	var state: Ball.PlayState = target.play_state
	return state == Ball.PlayState.PLAY_NORMAL or state == Ball.PlayState.PLAY_ARC


## Whether the given ball is moving toward the paddle and hasn't passed it yet.
func _ball_approaches(target: Ball) -> bool:
	var direction: float = _court_side_sign()
	return (
		direction * target.linear_velocity.x > 0.0
		and direction * target.position.x < direction * paddle.position.x
	)


## Sign of the court side the paddle occupies
func _court_side_sign() -> float:
	assert(false, "PaddleAIController._court_side_sign() is abstract")
	return 0.0


## The paddle's base movement speed, before config.speed_scale is applied.
func _get_paddle_speed() -> float:
	assert(false, "PaddleAIController._get_paddle_speed() is abstract")
	return 0.0


func _track() -> void:
	var bound_y: float = ball.bound_y
	var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

	var paddle_travel_bound: float = -paddle.top_y - paddle.get_half_height()
	var predicted_y: float = (
		PaddleAIMath
		. predict_intercept(
			ball.position,
			ball.linear_velocity,
			paddle.position.x,
			bound_y,
			gravity,
			paddle_travel_bound,
		)
	)
	# Update the player's low stance from the predicted ball position
	_update_low_stance(predicted_y, bound_y)
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

## Uses the predicted ball height to switch between grounded stance and
## low stance when the incoming ball reaches the low-stance threshold.
func _update_low_stance(predicted_y: float, ball_bounce_y: float) -> void:
	if not paddle.is_grounded():
		paddle.wants_low_stance = false
		return
		
	var grounded_y: float = paddle.global_position.y
	var low_stance_threshold_y: float = (grounded_y + ball_bounce_y) * 0.25
	
	paddle.wants_low_stance = predicted_y >= low_stance_threshold_y

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
func _maybe_offset_position() -> void:
	var current_direction_x: float = ball.linear_velocity.x

	if sign(current_direction_x) != sign(_last_ball_direction_x):
		_noise_offset = PaddleAIMath.random_offset(config.noise)

	_last_ball_direction_x = current_direction_x
