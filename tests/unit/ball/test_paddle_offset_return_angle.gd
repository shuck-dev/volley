extends GutTest

# Tests that paddle-contact offset drives the return angle: centre returns flat, edges steepen.

const PADDLE_HALF_HEIGHT := 27.0
const MAX_DEGREES := 30.0

var _ball: Ball
var _paddle: Paddle
var _manager: Node
var _min_angle_deg: float


func _live_min_angle_deg() -> float:
	return GameRules.paddle.paddle_bounce_min_angle_degrees


class PaddleDouble:
	extends Paddle
	var half_height: float = PADDLE_HALF_HEIGHT

	func get_half_height() -> float:
		return half_height


func before_each() -> void:
	_paddle = PaddleDouble.new()
	add_child_autofree(_paddle)
	_paddle.global_position = Vector2(0, 0)
	_min_angle_deg = _live_min_angle_deg()


func _build_with_max_degrees(degrees: float) -> void:
	_build_with_stats(degrees, 0.0)


func _build_with_stats(degrees: float, english: float) -> void:
	_build_with_stats_and_min_angle(degrees, english, 0.0)


func _build_with_stats_and_min_angle(
	degrees: float, english: float, min_angle_bonus: float
) -> void:
	# Builds items whose `always` triggers contribute the requested stat values like real items would.
	_manager = ItemFactory.create_manager(
		self, "max_angle_kit", &"paddle_return_angle_max_degrees", &"add", degrees
	)

	if english != 0.0:
		var english_item := ItemFactory.create(
			"english_kit", &"paddle_english_coefficient", &"add", english
		)
		_manager.items.append(english_item)
	if min_angle_bonus != 0.0:
		var min_item := ItemFactory.create(
			"min_angle_kit", &"paddle_bounce_min_angle_degrees", &"add", min_angle_bonus
		)
		_manager.items.append(min_item)
	_manager._progression.friendship_point_balance = 100000
	_manager.purchase("max_angle_kit")
	if english != 0.0:
		_manager.purchase("english_kit")
	if min_angle_bonus != 0.0:
		_manager.purchase("min_angle_kit")

	_ball = load("res://scripts/entities/ball/ball.gd").new()
	_ball._item_manager = _manager
	add_child_autofree(_ball)


# --- offset-driven angle ---
func test_centre_hit_returns_within_min_angle_band() -> void:
	# Centre hit: the min-angle clamp keeps the bounce off pure horizontal.
	_build_with_max_degrees(MAX_DEGREES)
	_ball.global_position = Vector2(0, 0)
	_ball.linear_velocity = Vector2(100, 60)
	_ball.speed = _ball.linear_velocity.length()

	_ball.effect_processor.process_hit(_paddle)

	var angle: float = atan2(absf(_ball.linear_velocity.y), absf(_ball.linear_velocity.x))
	assert_almost_eq(rad_to_deg(angle), _min_angle_deg, 0.01)
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


# --- english (paddle vertical velocity at contact) ---
func test_paddle_velocity_biases_bounce_in_direction_of_paddle_motion() -> void:
	# Paddle moving down should bias bounce past the centre-hit min-angle floor.
	var english := 0.001
	_build_with_stats(MAX_DEGREES, english)
	_paddle.velocity = Vector2(0.0, 400.0)
	_ball.global_position = Vector2(0, 0)
	_ball.linear_velocity = Vector2(100, 0)
	_ball.speed = _ball.linear_velocity.length()

	_ball.effect_processor.process_hit(_paddle)

	# Moving paddle forces hemisphere by motion direction: downward paddle → positive y bounce.
	assert_gt(_ball.linear_velocity.y, 0.0, "Paddle moving down should bias bounce downward")
	var angle: float = atan2(_ball.linear_velocity.y, absf(_ball.linear_velocity.x))
	assert_gt(
		rad_to_deg(angle),
		_min_angle_deg + 0.01,
		"English should push beyond the centre-hit min-angle floor"
	)


func test_paddle_up_with_bottom_edge_hit_bounces_up() -> void:
	# Regression: paddle motion direction wins; offset's hemisphere does not cancel english.
	var english := 0.001
	_build_with_stats(MAX_DEGREES, english)
	_paddle.velocity = Vector2(0.0, -400.0)
	_ball.global_position = Vector2(0, PADDLE_HALF_HEIGHT)
	_ball.linear_velocity = Vector2(100, 0)
	_ball.speed = _ball.linear_velocity.length()

	_ball.effect_processor.process_hit(_paddle)

	assert_lt(_ball.linear_velocity.y, 0.0, "Upward paddle motion forces bounce upward")


func test_paddle_down_with_top_edge_hit_bounces_down() -> void:
	# Regression mirror: paddle moving down + top-edge contact bounces downward.
	var english := 0.001
	_build_with_stats(MAX_DEGREES, english)
	_paddle.velocity = Vector2(0.0, 400.0)
	_ball.global_position = Vector2(0, -PADDLE_HALF_HEIGHT)
	_ball.linear_velocity = Vector2(100, 0)
	_ball.speed = _ball.linear_velocity.length()

	_ball.effect_processor.process_hit(_paddle)

	assert_gt(_ball.linear_velocity.y, 0.0, "Downward paddle motion forces bounce downward")


# --- centre-hit tiebreaker: incoming y-direction carries through ---
func test_descending_ball_centre_hit_returns_downward() -> void:
	# Dead-centre on a still paddle: incoming descending y should keep the bounce descending.
	_build_with_stats(MAX_DEGREES, 0.0)
	_paddle.velocity = Vector2.ZERO
	_ball.global_position = Vector2(0, 0)
	_ball.linear_velocity = Vector2(100, 60)
	_ball.speed = _ball.linear_velocity.length()

	_ball.effect_processor.process_hit(_paddle)

	assert_gt(_ball.linear_velocity.y, 0.0, "Descending centre hit should leave descending")
	var angle: float = atan2(_ball.linear_velocity.y, absf(_ball.linear_velocity.x))
	assert_almost_eq(rad_to_deg(angle), _min_angle_deg, 0.01)


func test_ascending_ball_centre_hit_returns_upward() -> void:
	_build_with_stats(MAX_DEGREES, 0.0)
	_paddle.velocity = Vector2.ZERO
	_ball.global_position = Vector2(0, 0)
	_ball.linear_velocity = Vector2(100, -60)
	_ball.speed = _ball.linear_velocity.length()

	_ball.effect_processor.process_hit(_paddle)

	assert_lt(_ball.linear_velocity.y, 0.0, "Ascending centre hit should leave ascending")
	var angle: float = atan2(-_ball.linear_velocity.y, absf(_ball.linear_velocity.x))
	assert_almost_eq(rad_to_deg(angle), _min_angle_deg, 0.01)


# --- min-angle dead zone is tunable ---
func test_raising_min_angle_floor_steepens_centre_hit() -> void:
	# Centre hit at default 3 deg floor.
	_build_with_stats(MAX_DEGREES, 0.0)
	_ball.global_position = Vector2(0, 0)
	_ball.linear_velocity = Vector2(100, 0)
	_ball.speed = _ball.linear_velocity.length()
	_ball.effect_processor.process_hit(_paddle)
	var baseline_y: float = absf(_ball.linear_velocity.y)

	# Same centre hit with the floor raised by an item modifier.
	_build_with_stats_and_min_angle(MAX_DEGREES, 0.0, 17.0)
	_ball.global_position = Vector2(0, 0)
	_ball.linear_velocity = Vector2(100, 0)
	_ball.speed = _ball.linear_velocity.length()
	_ball.effect_processor.process_hit(_paddle)
	var raised_y: float = absf(_ball.linear_velocity.y)

	assert_gt(
		raised_y, baseline_y, "Raising paddle_bounce_min_angle_degrees should steepen a centre hit"
	)


func test_horizontal_incoming_centre_hit_defaults_downward() -> void:
	# Degenerate case: both target angle and incoming y are zero; default to +_min_angle_deg.
	_build_with_stats(MAX_DEGREES, 0.0)
	_paddle.velocity = Vector2.ZERO
	_ball.global_position = Vector2(0, 0)
	_ball.linear_velocity = Vector2(100, 0)
	_ball.speed = _ball.linear_velocity.length()

	_ball.effect_processor.process_hit(_paddle)

	assert_gt(
		_ball.linear_velocity.y, 0.0, "Default tiebreaker should send bounce below horizontal"
	)
	var angle: float = atan2(_ball.linear_velocity.y, absf(_ball.linear_velocity.x))
	assert_almost_eq(rad_to_deg(angle), _min_angle_deg, 0.01)


# --- early-return gate: max=0 silences english too ---
func test_zero_max_degrees_with_english_and_paddle_motion_leaves_velocity_untouched() -> void:
	# Early-return on max_degrees=0 keeps english dormant even with paddle vertical velocity.
	_build_with_stats(0.0, 0.001)
	_paddle.velocity = Vector2(0.0, 400.0)
	_ball.global_position = Vector2(0, 0)
	var incoming := Vector2(100, 0)
	_ball.linear_velocity = incoming
	_ball.speed = _ball.linear_velocity.length()

	_ball.effect_processor.process_hit(_paddle)

	assert_eq(_ball.linear_velocity, incoming, "max_degrees=0 short-circuits english entirely")
