extends GutTest

const ShopScript := preload("res://scripts/shop/shop.gd")
const ShopConfigScript := preload("res://scripts/shop/shop_config.gd")
const ItemManagerScript := preload("res://scripts/items/item_manager.gd")
const StandardBall: ItemDefinition = preload("res://resources/items/standard_ball.tres")

var _manager: Node
var _shop: Shop
var _config: ShopConfig


func before_each() -> void:
	_manager = _make_manager()
	_config = ShopConfigScript.new()
	_config.refresh_base_cost = 10
	_config.refresh_cost_scaling = 2.0

	_shop = ShopScript.new()
	_shop._item_manager = _manager
	_shop.config = _config
	_shop.soul_label = Label.new()
	_shop.items_anchor = Node2D.new()
	_shop.items_anchor.name = "ItemsAnchor"
	_shop.add_child(_shop.items_anchor)
	_shop.add_child(_shop.soul_label)
	add_child_autofree(_shop)


func _make_manager() -> Node:
	var manager: Node = ItemManagerScript.new()
	manager.state = ItemState.new()
	manager.economy = EconomyState.new()
	manager._effect_manager = EffectManager.new()
	manager.items.assign([StandardBall])
	add_child_autofree(manager)
	return manager


func test_first_refresh_is_free() -> void:
	_manager.economy.soul_balance = 0
	var cost: int = _shop._get_refresh_cost()
	assert_eq(cost, 0, "first refresh has zero cost")


func test_second_refresh_costs_base() -> void:
	_manager.economy.soul_balance = 100
	_shop._refresh_count = 1
	var cost: int = _shop._get_refresh_cost()
	assert_eq(cost, 10, "second refresh costs the base amount")


func test_third_refresh_costs_scaled() -> void:
	_manager.economy.soul_balance = 100
	_shop._refresh_count = 2
	var cost: int = _shop._get_refresh_cost()
	assert_eq(cost, 20, "third refresh costs base * scaling^1")


func test_fourth_refresh_costs_doubled_again() -> void:
	_manager.economy.soul_balance = 100
	_shop._refresh_count = 3
	var cost: int = _shop._get_refresh_cost()
	assert_eq(cost, 40, "fourth refresh costs base * scaling^2")


func test_refresh_deducts_soul_when_not_free() -> void:
	_manager.economy.soul_balance = 100
	_shop._refresh_count = 1
	_shop._on_refresh_pressed()
	assert_eq(_manager.economy.soul_balance, 90, "soul deducted by base cost")


func test_first_refresh_does_not_deduct_soul() -> void:
	_manager.economy.soul_balance = 50
	var balance_before: int = _manager.economy.soul_balance
	_shop._on_refresh_pressed()
	assert_eq(
		_manager.economy.soul_balance, balance_before, "soul unchanged after first free refresh"
	)


func test_refresh_increments_count() -> void:
	_manager.economy.soul_balance = 100
	_shop._on_refresh_pressed()
	assert_eq(_shop._refresh_count, 1, "count incremented after refresh")


func test_refresh_does_not_increment_when_unaffordable() -> void:
	_manager.economy.soul_balance = 5
	_shop._refresh_count = 1
	_shop._on_refresh_pressed()
	assert_eq(_shop._refresh_count, 1, "count unchanged when soul too low")


func test_refresh_replaces_existing_items() -> void:
	_manager.economy.soul_balance = 100
	assert_eq(_shop.items_anchor.get_child_count(), 1, "precondition: one item spawned on _ready")

	_shop._on_refresh_pressed()
	await get_tree().process_frame
	# Old items are queue_freed during process, new items spawned from pool.
	assert_eq(_shop.items_anchor.get_child_count(), 1, "one item after refresh")


func test_refresh_respawns_items_from_pool() -> void:
	_manager.economy.soul_balance = 100
	_shop._on_refresh_pressed()
	await get_tree().process_frame
	var count: int = _shop.items_anchor.get_child_count()
	assert_eq(count, 1, "one item spawned after refresh")


func test_refresh_ui_disables_button_when_unaffordable() -> void:
	_manager.economy.soul_balance = 5
	_shop._refresh_count = 1
	var button := Button.new()
	var label := Label.new()
	_shop.refresh_button = button
	_shop.refresh_cost_label = label
	_shop.add_child(button)
	_shop.add_child(label)
	_shop._update_refresh_ui()
	assert_true(button.disabled, "button disabled when soul too low for cost")


func test_refresh_ui_enables_button_when_affordable() -> void:
	_manager.economy.soul_balance = 100
	_shop._refresh_count = 1
	var button := Button.new()
	var label := Label.new()
	_shop.refresh_button = button
	_shop.refresh_cost_label = label
	_shop.add_child(button)
	_shop.add_child(label)
	_shop._update_refresh_ui()
	assert_false(button.disabled, "button enabled when soul covers cost")


func test_refresh_ui_label_shows_free_on_first() -> void:
	var label := Label.new()
	_shop.refresh_cost_label = label
	_shop.add_child(label)
	_shop._update_refresh_ui()
	assert_eq(label.text, "FREE", "label shows FREE for first refresh")


func test_refresh_ui_label_shows_cost_on_subsequent() -> void:
	_shop._refresh_count = 1
	var label := Label.new()
	_shop.refresh_cost_label = label
	_shop.add_child(label)
	_shop._update_refresh_ui()
	assert_eq(label.text, "10 soul", "label shows cost for second refresh")
