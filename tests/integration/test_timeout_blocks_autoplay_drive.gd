extends GutTest

## SH-405: autoplay must not fight the timeout walk pose. The paddle's `_drive_blocked` flag
## makes `drive()` a no-op while the timeout is in flight; this exercises the wired-up path.

const LANE_X: float = -500.0
const LANE_Y: float = 0.0
const FLOOR_Y: float = 200.0
const VIRTUAL_DELTA: float = 0.6
const MAX_STEPS: int = 32

var _paddle: Paddle
var _controller: TimeoutController
var _autoplay: AutoplayController
var _floor: StaticBody2D


func before_each() -> void:
	_paddle = load("res://scripts/entities/paddle.gd").new()
	var sound := AudioStreamPlayer.new()
	_paddle.add_child(sound)
	_paddle.hit_sound = sound

	var tracker: HitTracker = load("res://scripts/core/hit_tracker.gd").new()
	_paddle.tracker = tracker
	_paddle.add_child(tracker)

	var paddle_collision := CollisionShape2D.new()
	var paddle_shape := RectangleShape2D.new()
	paddle_shape.size = Vector2(20.0, 54.0)
	paddle_collision.shape = paddle_shape
	_paddle.add_child(paddle_collision)
	_paddle.collision = paddle_collision

	_paddle.position = Vector2(LANE_X, LANE_Y)
	add_child_autofree(_paddle)

	_floor = StaticBody2D.new()
	_floor.position = Vector2(0.0, FLOOR_Y + 50.0)
	var floor_collision := CollisionShape2D.new()
	var floor_shape := RectangleShape2D.new()
	floor_shape.size = Vector2(4000.0, 100.0)
	floor_collision.shape = floor_shape
	_floor.add_child(floor_collision)
	add_child_autofree(_floor)

	var config: TimeoutConfig = TimeoutConfig.new()
	config.walk_duration_seconds = 0.5
	config.equip_pose_offset_x = -200.0
	config.descent_speed = 1200.0
	_controller = load("res://scripts/core/timeout_controller.gd").new()
	_controller.config = config
	_controller.configure(_paddle)
	add_child_autofree(_controller)

	_autoplay = load("res://scripts/core/autoplay_controller.gd").new()
	_autoplay.paddle = _paddle
	var ai_config: PaddleAIConfig = PaddleAIConfig.new()
	ai_config.reaction_delay_frames = 1
	_autoplay.config = ai_config
	add_child_autofree(_autoplay)

	await get_tree().physics_frame


func test_autoplay_drive_during_timeout_does_not_move_paddle() -> void:
	_controller.call_timeout()
	# Simulate autoplay attempting to fight the walk by directly calling drive().
	var start_position: Vector2 = _paddle.position
	_paddle.drive(800.0)
	assert_eq(
		_paddle.position,
		start_position,
		"autoplay's drive() must be ignored while the timeout is in flight",
	)


func test_paddle_reaches_equip_pose_under_autoplay_pressure() -> void:
	_controller.call_timeout()
	var equip_pose_x: float = LANE_X + _controller.config.equip_pose_offset_x
	for _i in range(MAX_STEPS):
		if _controller.get_state() == TimeoutController.State.AT_EQUIP_POSE:
			break
		# Each tick, autoplay would try to drive the paddle back to the lane.
		_paddle.drive(800.0)
		_controller._physics_process(VIRTUAL_DELTA)
	assert_eq(_controller.get_state(), TimeoutController.State.AT_EQUIP_POSE)
	assert_almost_eq(
		_paddle.position.x,
		equip_pose_x,
		0.5,
		"paddle must reach the equip pose even with autoplay drive() pressure each tick",
	)


func test_paddle_does_not_mask_balls_during_walk() -> void:
	# Balls live on layer 2 so the paddle's timeout mask-out drops them from collision.
	_controller.call_timeout()
	var ball_layer: int = (
		(preload("res://resources/ball/states/play_active.tres") as BallStateConfig).collision_layer
	)
	assert_eq(
		ball_layer,
		2,
		"play_active config must keep balls on layer 2 so the walk passes through them"
	)
	assert_false(
		_paddle.get_collision_mask_value(ball_layer),
		"paddle must mask off the ball layer during the timeout walk",
	)
