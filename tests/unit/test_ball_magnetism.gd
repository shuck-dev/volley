extends GutTest

# Tests that ball_magnetism bends the ball's trajectory toward the paddle.

const DOUBLE_KNOT := preload("res://resources/items/double_knot.tres")

var _ball: Ball
var _paddle: Node2D
var _manager: Node


func before_each() -> void:
	_manager = ItemFactory.create_manager(self, DOUBLE_KNOT.key)
	_manager.items.assign([DOUBLE_KNOT])

	_ball = load("res://scripts/entities/ball.gd").new()
	_ball._item_manager = _manager
	add_child_autofree(_ball)

	_paddle = Node2D.new()
	add_child_autofree(_paddle)
	_ball.effect_processor.paddles = [_paddle]


# --- magnetism ---
func test_no_magnetism_before_purchase() -> void:
	var test_speed: float = _manager.get_stat(&"ball_speed_min")
	_ball.global_position = Vector2(0, 0)
	_paddle.global_position = Vector2(0, 100)
	_ball.linear_velocity = Vector2(test_speed, 0)
	_ball.speed = test_speed

	_ball._physics_process(0.1)

	assert_almost_eq(_ball.linear_velocity.y, 0.0, 0.01)


func test_magnetism_bends_toward_paddle() -> void:
	_manager._progression.friendship_point_balance = 100000
	_manager.purchase("double_knot")

	var test_speed: float = _manager.get_stat(&"ball_speed_min")
	_ball.global_position = Vector2(0, 0)
	_paddle.global_position = Vector2(0, 100)
	_ball.linear_velocity = Vector2(test_speed, 0)
	_ball.speed = test_speed

	_ball._physics_process(0.1)

	assert_gt(_ball.linear_velocity.y, 0.0, "Ball should bend toward paddle")


func test_magnetism_preserves_speed() -> void:
	_manager._progression.friendship_point_balance = 100000
	_manager.purchase("double_knot")

	var test_speed: float = _manager.get_stat(&"ball_speed_min")
	_ball.global_position = Vector2(0, 0)
	_paddle.global_position = Vector2(0, 100)
	_ball.linear_velocity = Vector2(test_speed, 0)
	_ball.speed = test_speed

	_ball._physics_process(0.1)

	assert_almost_eq(_ball.linear_velocity.length(), test_speed, 0.01)
