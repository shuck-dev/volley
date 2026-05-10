extends GutTest

# Apex return: gravity engages above the friendship-bound, disengages below.
# The per-frame speed-lock turns gravity into directional curvature, not energy gain.

var _ball: Ball
var _manager: Node
var _mock_storage: SaveStorage


func before_each() -> void:
	_mock_storage = double(SaveStorage).new()
	stub(_mock_storage.write).to_return(true)
	stub(_mock_storage.read).to_return("")

	_manager = load("res://scripts/items/item_manager.gd").new()
	_manager._progression = ProgressionData.new(_mock_storage)
	_manager._effect_manager = EffectManager.new()
	(
		_manager
		. items
		. assign(
			[
				preload("res://resources/items/training_ball.tres"),
				preload("res://resources/items/court_lines.tres"),
			]
		)
	)
	add_child_autofree(_manager)

	_ball = load("res://scripts/entities/ball.gd").new()
	_ball._item_manager = _manager
	_ball.apex_bound_y = -100.0
	_ball.apex_gravity_scale = 1.5
	add_child_autofree(_ball)
	_ball.linear_velocity = Vector2(_manager.get_stat(&"ball_speed_min"), 0.0)


func test_gravity_off_below_bound() -> void:
	_ball.position = Vector2(0.0, 0.0)
	_ball._physics_process(0.016)
	assert_almost_eq(_ball.gravity_scale, 0.0, 0.001)


func test_gravity_on_above_bound() -> void:
	_ball.position = Vector2(0.0, -200.0)
	_ball._physics_process(0.016)
	assert_almost_eq(_ball.gravity_scale, _ball.apex_gravity_scale, 0.001)


func test_gravity_off_when_frozen_even_above_bound() -> void:
	_ball.position = Vector2(0.0, -200.0)
	_ball.freeze = true
	_ball._physics_process(0.016)
	assert_almost_eq(_ball.gravity_scale, 0.0, 0.001)


func test_gravity_toggles_on_crossing() -> void:
	_ball.position = Vector2(0.0, -200.0)
	_ball._physics_process(0.016)
	assert_gt(_ball.gravity_scale, 0.0)
	_ball.position = Vector2(0.0, 50.0)
	_ball._physics_process(0.016)
	assert_almost_eq(_ball.gravity_scale, 0.0, 0.001)
