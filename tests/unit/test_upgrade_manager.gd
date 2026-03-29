extends GutTest

# Tests for UpgradeManager: get_level, get_value, calculate_cost, can_purchase, purchase.
# Uses a manually constructed UpgradeManager (not the autoload) with a test upgrade injected.

const SPEED_KEY := "test_speed"

var _manager: Node
var _upgrade: Upgrade
var _mock_storage: SaveStorage


func before_each() -> void:
	_upgrade = Upgrade.new()
	_upgrade.key = SPEED_KEY
	_upgrade.base_value = 200.0
	_upgrade.effect_per_level = 20.0
	_upgrade.max_level = 3
	_upgrade.base_cost = 100
	_upgrade.cost_scaling = 2.0

	_mock_storage = double(SaveStorage).new()
	stub(_mock_storage.write).to_return(true)
	stub(_mock_storage.read).to_return("")

	_manager = load("res://scripts/progression/upgrade_manager.gd").new()
	_manager._progression = ProgressionData.new(_mock_storage)
	add_child_autofree(_manager)
	_manager.upgrades.assign([_upgrade])


# --- get_level ---
func test_get_level_returns_zero_before_any_purchase() -> void:
	assert_eq(_manager.get_level(SPEED_KEY), 0)


# --- get_base_value ---
func test_get_base_value_returns_base_value() -> void:
	assert_eq(_manager.get_base_value(SPEED_KEY), 200.0)


func test_get_base_value_unchanged_after_purchase() -> void:
	_manager._progression.friendship_point_balance = 1000
	_manager.purchase(SPEED_KEY)
	assert_eq(_manager.get_base_value(SPEED_KEY), 200.0)


# --- get_value ---
func test_get_value_returns_base_value_at_level_zero() -> void:
	assert_eq(_manager.get_value(SPEED_KEY), 200.0)


func test_get_value_increases_by_effect_per_level_after_purchase() -> void:
	_manager._progression.friendship_point_balance = 1000
	_manager.purchase(SPEED_KEY)
	assert_eq(_manager.get_value(SPEED_KEY), 220.0)


# --- calculate_cost ---
func test_calculate_cost_returns_base_cost_at_level_zero() -> void:
	assert_eq(_manager.calculate_cost(SPEED_KEY), 100)


func test_calculate_cost_scales_after_first_purchase() -> void:
	_manager._progression.friendship_point_balance = 1000
	_manager.purchase(SPEED_KEY)
	# cost = int(100 * pow(2.0, 1)) = 200
	assert_eq(_manager.calculate_cost(SPEED_KEY), 200)


# --- can_purchase ---
func test_can_purchase_false_when_balance_too_low() -> void:
	_manager._progression.friendship_point_balance = 0
	assert_false(_manager.can_purchase(SPEED_KEY))


func test_can_purchase_true_when_balance_sufficient() -> void:
	_manager._progression.friendship_point_balance = 100
	assert_true(_manager.can_purchase(SPEED_KEY))


func test_can_purchase_false_when_at_max_level() -> void:
	_manager._progression.friendship_point_balance = 10000
	_manager.purchase(SPEED_KEY)
	_manager.purchase(SPEED_KEY)
	_manager.purchase(SPEED_KEY)
	assert_false(_manager.can_purchase(SPEED_KEY))


# --- purchase ---
func test_purchase_returns_false_when_balance_too_low() -> void:
	_manager._progression.friendship_point_balance = 0
	assert_false(_manager.purchase(SPEED_KEY))


func test_purchase_returns_true_when_affordable() -> void:
	_manager._progression.friendship_point_balance = 100
	assert_true(_manager.purchase(SPEED_KEY))


func test_purchase_increments_level() -> void:
	_manager._progression.friendship_point_balance = 1000
	_manager.purchase(SPEED_KEY)
	assert_eq(_manager.get_level(SPEED_KEY), 1)


func test_purchase_deducts_cost_from_balance() -> void:
	_manager._progression.friendship_point_balance = 300
	_manager.purchase(SPEED_KEY)
	# cost at level 0 = 100, remaining = 200
	assert_eq(_manager.get_friendship_point_balance(), 200)


func test_purchase_returns_false_at_max_level() -> void:
	_manager._progression.friendship_point_balance = 10000
	_manager.purchase(SPEED_KEY)
	_manager.purchase(SPEED_KEY)
	_manager.purchase(SPEED_KEY)
	assert_false(_manager.purchase(SPEED_KEY))


# --- remove_level ---
func test_remove_level_decrements_level() -> void:
	_manager._progression.friendship_point_balance = 1000
	_manager.purchase(SPEED_KEY)
	_manager.remove_level(SPEED_KEY)
	assert_eq(_manager.get_level(SPEED_KEY), 0)


func test_remove_level_does_nothing_at_zero() -> void:
	_manager.remove_level(SPEED_KEY)
	assert_eq(_manager.get_level(SPEED_KEY), 0)


func test_remove_level_allows_repurchase_after_max() -> void:
	_manager._progression.friendship_point_balance = 10000
	_manager.purchase(SPEED_KEY)
	_manager.purchase(SPEED_KEY)
	_manager.purchase(SPEED_KEY)
	assert_false(_manager.can_purchase(SPEED_KEY))
	_manager.remove_level(SPEED_KEY)
	assert_true(_manager.can_purchase(SPEED_KEY))
