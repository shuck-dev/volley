extends GutTest

# Tests that paddle-contact offset drives the return angle: centre returns flat, edges steepen.

const PADDLE_HALF_HEIGHT := 27.0
const MAX_DEGREES := 30.0

var _ball: Ball
var _paddle: Node2D
var _manager: Node


class PaddleDouble:
	extends Node2D
	var half_height: float = PADDLE_HALF_HEIGHT

	func get_half_height() -> float:
		return half_height


func before_each() -> void:
	_paddle = PaddleDouble.new()
	add_child_autofree(_paddle)
	_paddle.global_position = Vector2(0, 0)


func _build_with_max_degrees(degrees: float) -> void:
	# Builds an item whose `always` trigger contributes the requested max-degrees value,
	# so the resolved stat carries the test value the same way a real item would.
	_manager = ItemFactory.create_manager(
		self, "max_angle_kit", &"paddle_return_angle_max_degrees", &"add", degrees
	)
	_manager._progression.friendship_point_balance = 100000
	_manager.purchase("max_angle_kit")

	_ball = load("res://scripts/entities/ball/ball.gd").new()
	_ball._item_manager = _manager
	add_child_autofree(_ball)


# --- offset-driven angle ---
func test_centre_hit_keeps_incoming_direction() -> void:
	_build_with_max_degrees(MAX_DEGREES)
	_ball.global_position = Vector2(0, 0)
	_ball.linear_velocity = Vector2(100, 60)
	_ball.speed = _ball.linear_velocity.length()

	_ball.effect_processor.process_hit(_paddle)

	# Centre offset = 0 ⇒ target angle = 0 ⇒ pure horizontal at the same speed.
	assert_almost_eq(_ball.linear_velocity.y, 0.0, 0.01)
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


func test_null_paddle_is_dormant() -> void:
	_build_with_max_degrees(MAX_DEGREES)
	_ball.linear_velocity = Vector2(100, 80)
	_ball.speed = _ball.linear_velocity.length()
	var original_velocity: Vector2 = _ball.linear_velocity

	_ball.effect_processor.process_hit(null)

	assert_eq(_ball.linear_velocity, original_velocity)
