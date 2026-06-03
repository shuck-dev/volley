extends GutTest

# Ball speed-tier and miss-zone behaviour at base stats, off a neutral manager stub.

const BallManagerStub: GDScript = preload("res://tests/stubs/ball_manager_stub.gd")

var _ball: Ball


func before_each() -> void:
	var manager: Node = BallManagerStub.new()
	add_child_autofree(manager)

	_ball = load("res://scripts/entities/ball/ball.gd").new()
	_ball._item_manager = manager
	add_child_autofree(_ball)
	_ball.linear_velocity = Vector2(
		Stats.resolve(GameRules.base.ball_speed_min, &"ball_speed_min", manager), 0.0
	)


# --- increase_speed ---
func test_increase_speed_advances_tier_at_ceiling() -> void:
	_ball.current_tier = 0
	_ball.speed = _ball.tier_ceiling - 1.0
	_ball.increase_speed()
	assert_eq(_ball.current_tier, 1, "crossing the ceiling steps up a tier")
	assert_almost_eq(_ball.speed, _ball.tier_floor, 0.01, "speed drops to the new tier's floor")


# --- miss zone ---
func _registered_zone() -> MissZone:
	var zone := MissZone.new()
	add_child_autofree(zone)
	_ball.register_miss_zone(zone)
	return zone


func test_miss_zone_entry_emits_missed() -> void:
	var zone := _registered_zone()
	watch_signals(_ball)

	zone.body_entered.emit(_ball)

	assert_signal_emitted(_ball, "missed")


func test_miss_zone_ignores_other_bodies() -> void:
	var zone := _registered_zone()
	watch_signals(_ball)

	var other_body: Node2D = Node2D.new()
	add_child_autofree(other_body)
	zone.body_entered.emit(other_body)

	assert_signal_not_emitted(_ball, "missed")


func test_register_miss_zone_is_idempotent() -> void:
	var zone := _registered_zone()
	_ball.register_miss_zone(zone)  # second registration must not double-wire
	watch_signals(_ball)

	zone.body_entered.emit(_ball)

	assert_signal_emit_count(_ball, "missed", 1)

	assert_signal_emit_count(_ball, "missed", 1)
