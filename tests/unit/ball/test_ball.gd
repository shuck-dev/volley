extends GutTest

var _ball: Ball


func before_each() -> void:
	_ball = load("res://scripts/entities/ball/ball.gd").new()
	add_child_autofree(_ball)
	_ball.linear_velocity = Vector2(800.0, 0.0)


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
