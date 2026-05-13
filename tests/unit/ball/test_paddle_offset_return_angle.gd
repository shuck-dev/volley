extends GutTest

# Tests that paddle-contact offset drives the return angle: centre returns flat, edges steepen.

const PADDLE_HALF_HEIGHT := 27.0
const MAX_DEGREES := 30.0
const MIN_ANGLE_DEG := 3.0
const MAX_ANGLE_DEG := 87.0

var _ball: Ball
var _paddle: Paddle
var _manager: Node


class PaddleDouble:
	extends Paddle
	var half_height: float = PADDLE_HALF_HEIGHT

	func get_half_height() -> float:
		return half_height


func before_each() -> void:
	_paddle = PaddleDouble.new()
	add_child_autofree(_paddle)
	_paddle.global_position = Vector2(0, 0)


func _build_with_max_degrees(degrees: float) -> void:
	_build_with_stats(degrees, 0.0)


func _build_with_stats(degrees: float, english: float) -> void:
	# Builds items whose `always` triggers contribute the requested stat values, so the resolved
	# stats carry the test values the same way real items would.
	_manager = ItemFactory.create_manager(
		self, "max_angle_kit", &"paddle_return_angle_max_degrees", &"add", degrees
	)
	if english != 0.0:
		var english_item := ItemFactory.create(
			"english_kit", &"paddle_english_coefficient", &"add", english
		)
		_manager.items.append(english_item)
	_manager._progression.friendship_point_balance = 100000
	_manager.purchase("max_angle_kit")
	if english != 0.0:
		_manager.purchase("english_kit")

	_ball = load("res://scripts/entities/ball/ball.gd").new()
	_ball._item_manager = _manager
	add_child_autofree(_ball)


# --- offset-driven angle ---
func test_centre_hit_returns_within_min_angle_band() -> void:
	# Centre hit, no english: the min-angle clamp keeps the return off pure horizontal so the bounce
	# reads as directed rather than as the ball ignoring the paddle.
	_build_with_max_degrees(MAX_DEGREES)
	_ball.global_position = Vector2(0, 0)
	_ball.linear_velocity = Vector2(100, 60)
	_ball.speed = _ball.linear_velocity.length()

	_ball.effect_processor.process_hit(_paddle)

	var angle: float = atan2(absf(_ball.linear_velocity.y), absf(_ball.linear_velocity.x))
	assert_almost_eq(rad_to_deg(angle), MIN_ANGLE_DEG, 0.01)
	assert_gt(_ball.linear_velocity.x, 0.0)


func test_edge_hit_steepens_vs_centre() -> void:
	_build_with_max_degrees(MAX_DEGREES)

	# Centre hit.
	_ball.global_position = Vector2(0, 0)
	_ball.linear_velocity = Vector2(100, 0)
	_ball.speed = _ball.linear_velocity.length()
	_ball.effect_processor.process_hit(_paddle)
	var centre_slope: float = absf(_ball.linear_velocity.y / _ball.linear_velocity.x)

	# Top-edge hit (ball above paddle centre).
	_ball.global_position = Vector2(0, -PADDLE_HALF_HEIGHT)
	_ball.linear_velocity = Vector2(100, 0)
	_ball.speed = _ball.linear_velocity.length()
	_ball.effect_processor.process_hit(_paddle)
	var edge_slope: float = absf(_ball.linear_velocity.y / _ball.linear_velocity.x)

	assert_gt(edge_slope, centre_slope, "Edge contact should steepen the return angle")


func test_symmetric_edges_mirror() -> void:
	_build_with_max_degrees(MAX_DEGREES)

	_ball.global_position = Vector2(0, -PADDLE_HALF_HEIGHT)
	_ball.linear_velocity = Vector2(100, 0)
	_ball.speed = _ball.linear_velocity.length()
	_ball.effect_processor.process_hit(_paddle)
	var top_y: float = _ball.linear_velocity.y

	_ball.global_position = Vector2(0, PADDLE_HALF_HEIGHT)
	_ball.linear_velocity = Vector2(100, 0)
	_ball.speed = _ball.linear_velocity.length()
	_ball.effect_processor.process_hit(_paddle)
	var bottom_y: float = _ball.linear_velocity.y

	assert_almost_eq(top_y, -bottom_y, 0.01)


func test_preserves_speed() -> void:
	_build_with_max_degrees(MAX_DEGREES)
	_ball.global_position = Vector2(0, -PADDLE_HALF_HEIGHT)
	_ball.linear_velocity = Vector2(100, 80)
	_ball.speed = _ball.linear_velocity.length()
	var original_speed: float = _ball.speed

	_ball.effect_processor.process_hit(_paddle)

	assert_almost_eq(_ball.linear_velocity.length(), original_speed, 0.01)


func test_preserves_horizontal_direction() -> void:
	_build_with_max_degrees(MAX_DEGREES)
	_ball.global_position = Vector2(0, PADDLE_HALF_HEIGHT)
	_ball.linear_velocity = Vector2(100, -80)
	_ball.speed = _ball.linear_velocity.length()

	_ball.effect_processor.process_hit(_paddle)

	assert_gt(_ball.linear_velocity.x, 0.0, "Side-miss guard: horizontal sign survives the hit")


func test_zero_stat_is_dormant() -> void:
	_build_with_max_degrees(0.0)
	_ball.global_position = Vector2(0, -PADDLE_HALF_HEIGHT)
	_ball.linear_velocity = Vector2(100, 80)
	_ball.speed = _ball.linear_velocity.length()
	var original_velocity: Vector2 = _ball.linear_velocity

	_ball.effect_processor.process_hit(_paddle)

	assert_eq(_ball.linear_velocity, original_velocity)


func test_angle_scales_linearly_with_max_degrees() -> void:
	# Same edge offset at two non-zero max-degree settings; resulting angle should scale linearly.
	_build_with_max_degrees(20.0)
	_ball.global_position = Vector2(0, -PADDLE_HALF_HEIGHT)
	_ball.linear_velocity = Vector2(100, 0)
	_ball.speed = _ball.linear_velocity.length()
	_ball.effect_processor.process_hit(_paddle)
	var angle_20: float = atan2(absf(_ball.linear_velocity.y), absf(_ball.linear_velocity.x))

	_build_with_max_degrees(40.0)
	_ball.global_position = Vector2(0, -PADDLE_HALF_HEIGHT)
	_ball.linear_velocity = Vector2(100, 0)
	_ball.speed = _ball.linear_velocity.length()
	_ball.effect_processor.process_hit(_paddle)
	var angle_40: float = atan2(absf(_ball.linear_velocity.y), absf(_ball.linear_velocity.x))

	assert_almost_eq(rad_to_deg(angle_20), 20.0, 0.01)
	assert_almost_eq(rad_to_deg(angle_40), 40.0, 0.01)


func test_real_paddle_get_half_height_drives_return_angle() -> void:
	# Exercises Paddle.get_half_height() against the production code path (real _collision_shape).
	var real_paddle: Paddle = load("res://tests/stubs/paddle_stub.gd").new()
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(20.0, PADDLE_HALF_HEIGHT * 2.0)
	shape.shape = rect
	real_paddle.collision = shape
	real_paddle.add_child(shape)
	add_child_autofree(real_paddle)
	# Override post-_ready sizing so the half-height under test is deterministic.
	real_paddle._collision_shape.size.y = PADDLE_HALF_HEIGHT * 2.0
	real_paddle.global_position = Vector2(0, 0)

	_build_with_max_degrees(MAX_DEGREES)
	_ball.global_position = Vector2(0, -PADDLE_HALF_HEIGHT)
	_ball.linear_velocity = Vector2(100, 0)
	_ball.speed = _ball.linear_velocity.length()

	_ball.effect_processor.process_hit(real_paddle)

	var angle: float = atan2(absf(_ball.linear_velocity.y), absf(_ball.linear_velocity.x))
	assert_almost_eq(rad_to_deg(angle), MAX_DEGREES, 0.01)


# --- english (paddle vertical velocity at contact) ---
func test_paddle_velocity_biases_bounce_in_direction_of_paddle_motion() -> void:
	# Centre hit baseline gets a small min-angle nudge; paddle moving downward should bias the
	# return downward beyond that floor, more than the centre-hit baseline.
	var english := 0.001
	_build_with_stats(MAX_DEGREES, english)
	_paddle.velocity = Vector2(0.0, 400.0)
	_ball.global_position = Vector2(0, 0)
	_ball.linear_velocity = Vector2(100, 0)
	_ball.speed = _ball.linear_velocity.length()

	_ball.effect_processor.process_hit(_paddle)

	# Downward paddle motion (positive y in screen space) → bounce angle positive y.
	assert_gt(_ball.linear_velocity.y, 0.0, "Paddle moving down should bias bounce downward")
	var angle: float = atan2(_ball.linear_velocity.y, absf(_ball.linear_velocity.x))
	assert_gt(
		rad_to_deg(angle),
		MIN_ANGLE_DEG + 0.01,
		"English should push beyond the centre-hit min-angle floor"
	)


func test_max_angle_clamp_caps_extreme_english_plus_offset() -> void:
	# Edge hit with maxed-out english added on top should never return near-vertical; the
	# max-angle ceiling kicks in to keep the ball from wall-bouncing off the back wall.
	_build_with_stats(MAX_DEGREES, 0.01)
	_paddle.velocity = Vector2(0.0, 10000.0)
	_ball.global_position = Vector2(0, PADDLE_HALF_HEIGHT)
	_ball.linear_velocity = Vector2(100, 0)
	_ball.speed = _ball.linear_velocity.length()

	_ball.effect_processor.process_hit(_paddle)

	var angle: float = atan2(absf(_ball.linear_velocity.y), absf(_ball.linear_velocity.x))
	assert_almost_eq(rad_to_deg(angle), MAX_ANGLE_DEG, 0.01)
