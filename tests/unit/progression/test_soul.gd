extends GutTest

# Verifies soul tracking: soul is a currency that
# increments on each hit and persists across misses (shop mechanics will decrease it).

var _game: Node2D
var _ball_stub: Ball
var _paddle_stub: Paddle
var _autoplay_controller_stub: AutoplayController
var _item_manager: Node
var _last_soul_balance := -1


func before_each() -> void:
	_ball_stub = load("res://tests/stubs/ball_stub.gd").new()
	_paddle_stub = load("res://tests/stubs/paddle_stub.gd").new()

	_item_manager = load("res://scripts/items/item_manager.gd").new()
	_item_manager.state = ItemState.new()
	_item_manager.economy = EconomyState.new()
	_item_manager._effect_manager = EffectManager.new()
	add_child_autofree(_item_manager)

	_autoplay_controller_stub = load("res://tests/stubs/autoplay_controller_stub.gd").new()
	add_child_autofree(_autoplay_controller_stub)

	var progression_config: ProgressionConfig = ProgressionConfig.new()
	progression_config.autoplay_soul_rate = 0.5

	_game = load("res://scripts/core/court.gd").new()
	_game.ball = _ball_stub
	_game.player_paddle = _paddle_stub
	_game.autoplay_controller = _autoplay_controller_stub
	_game._records = RecordsState.new()
	_game._partners = PartnersState.new()
	_game._progression_config = progression_config
	_game._item_manager = _item_manager
	add_child_autofree(_ball_stub)
	add_child_autofree(_paddle_stub)
	add_child_autofree(_game)
	_item_manager.soul_balance_changed.connect(func(total: int) -> void: _last_soul_balance = total)
	_ball_stub.gravity_scale = 0.0


func _hit() -> void:
	_paddle_stub.paddle_hit.emit(null)


func test_soul_increments_on_each_hit() -> void:
	_hit()
	assert_eq(_last_soul_balance, 1)
	_hit()
	assert_eq(_last_soul_balance, 2)
	_hit()
	assert_eq(_last_soul_balance, 3)


func test_soul_persists_after_miss() -> void:
	_hit()
	_hit()
	_hit()
	_ball_stub.missed.emit(_ball_stub)
	assert_eq(_last_soul_balance, 3)


func test_soul_accumulates_across_multiple_rallies() -> void:
	_hit()
	_hit()
	_ball_stub.missed.emit(_ball_stub)
	_hit()
	_hit()
	_hit()
	_ball_stub.missed.emit(_ball_stub)
	assert_eq(_last_soul_balance, 5)


# --- auto-play soul rate ---
func test_soul_earns_at_half_rate_during_autoplay() -> void:
	_autoplay_controller_stub.autoplay_toggled.emit(true)
	_hit()
	_hit()
	assert_eq(_last_soul_balance, 1)


func test_soul_fractional_remainder_carries_over_between_autoplay_hits() -> void:
	_autoplay_controller_stub.autoplay_toggled.emit(true)
	_hit()
	_hit()
	_hit()
	_hit()
	assert_eq(_last_soul_balance, 2)


func test_soul_accumulator_carries_over_when_autoplay_ends() -> void:
	_autoplay_controller_stub.autoplay_toggled.emit(true)
	_hit()
	_autoplay_controller_stub.autoplay_toggled.emit(false)
	_hit()
	assert_eq(_last_soul_balance, 1)


func test_soul_accumulator_resets_on_miss() -> void:
	_autoplay_controller_stub.autoplay_toggled.emit(true)
	_hit()
	_ball_stub.missed.emit(_ball_stub)
	_autoplay_controller_stub.autoplay_toggled.emit(false)
	_hit()
	assert_eq(_last_soul_balance, 1)


# --- soul_per_hit stat ---
func test_soul_per_hit_uses_effect_system_stat() -> void:
	var item := ItemFactory.create("fp_doubler", &"soul_per_hit", &"percentage", 1.0)
	_item_manager.items.assign([item])
	_item_manager.add_soul(item.base_cost)
	_item_manager.purchase(item.key)
	_item_manager.activate(item.key)

	_hit()
	_hit()

	assert_eq(_last_soul_balance, 4)


func test_soul_per_hit_with_quarter_bonus() -> void:
	var item := ItemFactory.create("fp_quarter", &"soul_per_hit", &"percentage", 0.25)
	_item_manager.items.assign([item])
	_item_manager.add_soul(item.base_cost)
	_item_manager.purchase(item.key)
	_item_manager.activate(item.key)

	_hit()
	_hit()
	_hit()
	_hit()

	assert_eq(_last_soul_balance, 5)


# --- auto_play_changed signal ---
func test_auto_play_changed_emits_true_when_autoplay_enabled() -> void:
	watch_signals(_game)
	_autoplay_controller_stub.autoplay_toggled.emit(true)
	assert_signal_emitted_with_parameters(_game, "auto_play_changed", [true, 0.5])


func test_auto_play_changed_emits_false_when_autoplay_disabled() -> void:
	_autoplay_controller_stub.autoplay_toggled.emit(true)
	watch_signals(_game)
	_autoplay_controller_stub.autoplay_toggled.emit(false)
	assert_signal_emitted_with_parameters(_game, "auto_play_changed", [false, 0.5])
