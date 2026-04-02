extends GutTest

# Verifies friendship point tracking: FP is a currency that
# increments on each hit and persists across misses (shop mechanics will decrease it).

var _game: Node2D
var _ball_stub: RigidBody2D
var _paddle_stub: Node
var _upgrade_manager: Node
var _last_friendship_point_balance := -1


func before_each() -> void:
	_ball_stub = load("res://tests/stubs/ball_stub.gd").new()
	_paddle_stub = load("res://tests/stubs/paddle_stub.gd").new()

	var mock_storage: SaveStorage = double(SaveStorage).new()
	stub(mock_storage.write).to_return(true)
	stub(mock_storage.read).to_return("")

	_upgrade_manager = load("res://scripts/progression/upgrade_manager.gd").new()
	_upgrade_manager._progression = ProgressionData.new(mock_storage)
	add_child_autofree(_upgrade_manager)

	var autoplay_controller_stub: Node = load("res://tests/stubs/autoplay_controller_stub.gd").new()
	add_child_autofree(autoplay_controller_stub)

	_game = load("res://scripts/core/game.gd").new()
	_game.ball = _ball_stub
	_game.paddle = _paddle_stub
	_game.autoplay_controller = autoplay_controller_stub
	_game._progression = ProgressionData.new(mock_storage)
	_game._upgrade_manager = _upgrade_manager
	add_child_autofree(_ball_stub)
	add_child_autofree(_paddle_stub)
	add_child_autofree(_game)
	_upgrade_manager.friendship_point_balance_changed.connect(
		func(total: int) -> void: _last_friendship_point_balance = total
	)
	_ball_stub.gravity_scale = 0.0


func _hit() -> void:
	_paddle_stub.paddle_hit.emit()


func test_fp_increments_on_each_hit() -> void:
	_hit()
	assert_eq(_last_friendship_point_balance, 1)
	_hit()
	assert_eq(_last_friendship_point_balance, 2)
	_hit()
	assert_eq(_last_friendship_point_balance, 3)


func test_fp_persists_after_miss() -> void:
	_hit()
	_hit()
	_hit()
	_ball_stub.missed.emit()
	assert_eq(_last_friendship_point_balance, 3)


func test_fp_accumulates_across_multiple_rallies() -> void:
	_hit()
	_hit()
	_ball_stub.missed.emit()
	_hit()
	_hit()
	_hit()
	_ball_stub.missed.emit()
	assert_eq(_last_friendship_point_balance, 5)


# --- auto-play FP rate ---
func test_fp_earns_at_half_rate_during_autoplay() -> void:
	_game._is_autoplay_active = true
	_hit()
	_hit()
	assert_eq(_last_friendship_point_balance, 1)


func test_fp_fractional_remainder_carries_over_between_autoplay_hits() -> void:
	_game._is_autoplay_active = true
	_hit()
	_hit()
	_hit()
	_hit()
	assert_eq(_last_friendship_point_balance, 2)


func test_fp_accumulator_carries_over_when_autoplay_ends() -> void:
	_game._is_autoplay_active = true
	_hit()
	_game._is_autoplay_active = false
	_hit()
	assert_eq(_last_friendship_point_balance, 1)


# --- auto_play_changed signal ---
func test_auto_play_changed_emits_true_when_autoplay_enabled() -> void:
	watch_signals(_game)
	_game._on_auto_play_changed(true)
	assert_signal_emitted_with_parameters(_game, "auto_play_changed", [true])


func test_auto_play_changed_emits_false_when_autoplay_disabled() -> void:
	_game._on_auto_play_changed(true)
	watch_signals(_game)
	_game._on_auto_play_changed(false)
	assert_signal_emitted_with_parameters(_game, "auto_play_changed", [false])
