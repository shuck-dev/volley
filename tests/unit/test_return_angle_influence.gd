extends GutTest

# Tests that return_angle_influence biases return angle toward horizontal.

const DOUBLE_KNOT := preload("res://resources/items/double_knot.tres")

var _ball: Ball
var _manager: Node


func before_each() -> void:
	_manager = ItemFactory.create_manager(self, DOUBLE_KNOT.key)
	_manager.items.assign([DOUBLE_KNOT])

	_ball = load("res://scripts/entities/ball.gd").new()
	_ball._item_manager = _manager
	add_child_autofree(_ball)


# --- return angle ---
func test_no_influence_before_level_two() -> void:
	_manager._progression.friendship_point_balance = 100000
	_manager.purchase("double_knot")

	_ball.linear_velocity = Vector2(100, 80)
	_ball.speed = _ball.linear_velocity.length()

	_ball._effect_processor.process_hit()

	assert_almost_eq(_ball.linear_velocity.y, 80.0, 0.01)


func test_influence_reduces_vertical_component() -> void:
	_manager._progression.friendship_point_balance = 100000
	_manager.purchase("double_knot")
	_manager.purchase("double_knot")

	_ball.linear_velocity = Vector2(100, 80)
	_ball.speed = _ball.linear_velocity.length()
	var original_y: float = _ball.linear_velocity.y

	_ball._effect_processor.process_hit()

	assert_lt(
		absf(_ball.linear_velocity.y),
		absf(original_y),
		"Vertical component should decrease toward horizontal",
	)


func test_influence_preserves_speed() -> void:
	_manager._progression.friendship_point_balance = 100000
	_manager.purchase("double_knot")
	_manager.purchase("double_knot")

	_ball.linear_velocity = Vector2(100, 80)
	_ball.speed = _ball.linear_velocity.length()
	var original_speed: float = _ball.speed

	_ball._effect_processor.process_hit()

	assert_almost_eq(_ball.linear_velocity.length(), original_speed, 0.01)


func test_influence_preserves_horizontal_direction() -> void:
	_manager._progression.friendship_point_balance = 100000
	_manager.purchase("double_knot")
	_manager.purchase("double_knot")

	_ball.linear_velocity = Vector2(100, 80)
	_ball.speed = _ball.linear_velocity.length()

	_ball._effect_processor.process_hit()

	assert_gt(
		_ball.linear_velocity.x,
		0.0,
		"Should keep moving in same x direction",
	)
