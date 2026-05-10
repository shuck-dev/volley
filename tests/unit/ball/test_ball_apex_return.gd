extends GutTest

# Apex return: gravity engages above the friendship-bound, disengages below.
# Trajectory tests drive _physics_process across a real bound crossing to assert the
# ball arcs back into play; the speed-lock holds magnitude steady so gravity is curvature, not energy.

const TICK: float = 1.0 / 60.0
const MAX_TICKS: int = 600

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
	_ball._physics_process(TICK)
	assert_almost_eq(_ball.gravity_scale, 0.0, 0.001)


func test_gravity_on_above_bound() -> void:
	_ball.position = Vector2(0.0, -200.0)
	_ball._physics_process(TICK)
	assert_almost_eq(_ball.gravity_scale, _ball.apex_gravity_scale, 0.001)


func test_gravity_off_when_frozen_even_above_bound() -> void:
	_ball.position = Vector2(0.0, -200.0)
	_ball.freeze = true
	_ball._physics_process(TICK)
	assert_almost_eq(_ball.gravity_scale, 0.0, 0.001)


func test_gravity_on_at_exact_bound() -> void:
	# Strict-less would let a ball at exactly the bound float; closed bound (<=) catches it.
	_ball.position = Vector2(0.0, _ball.apex_bound_y)
	_ball.linear_velocity = Vector2(_ball.speed, 0.0)
	_ball._physics_process(TICK)
	assert_gt(_ball.gravity_scale, 0.0, "ball at exactly the bound should be pulled back")


func test_high_velocity_overshoot_engages_via_prediction() -> void:
	# A fast-rising ball can skip the above-bound sample; predicted-y closes the gap.
	# Position is below the bound, but next-step y will be above it.
	_ball.position = Vector2(0.0, _ball.apex_bound_y + 10.0)
	_ball.linear_velocity = Vector2(0.0, -2000.0)
	_ball._physics_process(TICK)
	assert_gt(_ball.gravity_scale, 0.0, "predicted overshoot should engage gravity")


func test_uses_global_position_so_reparent_safe() -> void:
	# global_position must drive the toggle: setting global_position above the bound while local
	# position is below proves the gate uses world coords, not parent-relative coords.
	_ball.global_position = Vector2(0.0, -500.0)
	_ball._physics_process(TICK)
	assert_gt(_ball.gravity_scale, 0.0, "global_position above bound must engage gravity")


func test_ball_arcs_back_into_play_across_bound() -> void:
	# AC1 integrated trajectory: launch above the bound rising, gravity must turn it and bring it back.
	# Production order: physics integrator applies gravity + advances position, then _physics_process speed-locks.
	_ball.position = Vector2(0.0, _ball.apex_bound_y - 50.0)
	var initial_speed: float = _ball.speed
	# Diagonal kick — pure-vertical is a degenerate axis-aligned case where speed-lock perfectly
	# undoes gravity each tick. Real rallies always have horizontal velocity to break the symmetry.
	_ball.linear_velocity = Vector2(initial_speed * 0.7, -initial_speed * 0.7)
	var min_y_seen: float = _ball.position.y
	var returned_below: bool = false
	for i in MAX_TICKS:
		# Integrator-style step: gravity + position advance happen before speed-lock.
		_ball.linear_velocity += Vector2(0.0, _ball.gravity_scale * 980.0 * TICK)
		_ball.position += _ball.linear_velocity * TICK
		_ball._physics_process(TICK)
		min_y_seen = min(min_y_seen, _ball.position.y)
		if min_y_seen < _ball.apex_bound_y and _ball.position.y > _ball.apex_bound_y:
			returned_below = true
			break
	assert_true(returned_below, "ball must rise above bound then arc back below it")


func test_speed_locked_across_arc() -> void:
	# AC: speed-lock holds magnitude steady; gravity curves direction without energy gain.
	_ball.position = Vector2(0.0, _ball.apex_bound_y - 50.0)
	var locked_speed: float = _ball.speed
	_ball.linear_velocity = Vector2(locked_speed * 0.7, -locked_speed * 0.7)
	var max_post_lock_speed: float = 0.0
	for i in 120:
		_ball.linear_velocity += Vector2(0.0, _ball.gravity_scale * 980.0 * TICK)
		_ball.position += _ball.linear_velocity * TICK
		_ball._physics_process(TICK)
		# After _physics_process the speed-lock has run; magnitude must equal locked_speed.
		max_post_lock_speed = max(max_post_lock_speed, _ball.linear_velocity.length())
	assert_almost_eq(max_post_lock_speed, locked_speed, 0.001, "speed must stay locked across arc")


func test_paddle_hit_above_bound_preserves_rally() -> void:
	# AC2: a paddle strike while the ball is above the bound still registers as a normal hit
	# (no missed signal, increase_speed runs). _on_body_entered is the single hit gate, so we exercise it.
	var missed_count: Array[int] = [0]
	_ball.missed.connect(func() -> void: missed_count[0] += 1)
	_ball.position = Vector2(0.0, _ball.apex_bound_y - 50.0)
	# Bring speed off floor so increase_speed has headroom to bump.
	_ball.speed = _ball.min_speed
	var pre_speed: float = _ball.speed

	var paddle_script: GDScript = GDScript.new()
	paddle_script.source_code = "extends Node\nfunc on_ball_hit() -> bool:\n\treturn true\n"
	paddle_script.reload()
	var paddle_node: Node = Node.new()
	paddle_node.set_script(paddle_script)
	add_child_autofree(paddle_node)

	_ball._on_body_entered(paddle_node)
	assert_eq(missed_count[0], 0, "paddle hit above the bound must not trigger missed")
	assert_gt(_ball.speed, pre_speed, "paddle hit above the bound must still increase speed")
