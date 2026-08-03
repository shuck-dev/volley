extends GutTest

const BallReconcilerScript: GDScript = preload("res://scripts/items/ball_reconciler.gd")
const BallManagerScript: GDScript = preload("res://scripts/items/ball_manager.gd")
const ItemTestHelpersScript: GDScript = preload("res://tests/helpers/ball_test_helpers.gd")

var _manager: Node
var _reconciler: BallReconciler


func before_each() -> void:
	_manager = BallManagerScript.new()
	_manager.state = BallState.new()
	_manager.economy = EconomyState.new()
	_manager.economy.soul_balance = 10000
	add_child_autofree(_manager)

	_reconciler = BallReconcilerScript.new()
	_reconciler.configure(_manager)
	add_child_autofree(_reconciler)


func _spawn_ball(ball_key: String) -> Ball:
	_manager.take(ball_key)
	_manager.activate(ball_key)
	return _reconciler.get_ball_for_key(ball_key)


func _make_cheater_ball_item(key: String) -> BallDefinition:
	var item: BallDefinition = ItemTestHelpersScript.make_ball_item(key)
	item.scene = load("res://scenes/balls/cheater_ball.tscn")
	return item


func _spawn_cheater_ball(key: String) -> CheaterBall:
	var cheater_item: BallDefinition = _make_cheater_ball_item(key)
	var typed_items: Array[BallDefinition] = [cheater_item]
	_manager.items.assign(typed_items)
	return _spawn_ball(key) as CheaterBall


func test_wobble_preserves_speed() -> void:
	var ball: CheaterBall = _spawn_cheater_ball("ball_cheater")
	ball.linear_velocity = Vector2(ball.scaled_speed, 0.0)

	# A delta past max_interval_seconds guarantees the wobble fires within this single tick.
	ball._physics_process(ball.max_interval_seconds + 0.1)

	assert_almost_eq(ball.linear_velocity.length(), ball.scaled_speed, 0.01)


func test_wobble_rotates_velocity_direction() -> void:
	var ball: CheaterBall = _spawn_cheater_ball("ball_cheater")
	var original_direction: Vector2 = Vector2(ball.scaled_speed, 0.0)
	ball.linear_velocity = original_direction

	ball._physics_process(ball.max_interval_seconds + 0.1)

	assert_ne(
		ball.linear_velocity.angle(),
		original_direction.angle(),
		"wobble should rotate the velocity, not leave it unchanged",
	)
