extends GutTest


func test_goop_tres_loads() -> void:
	var item: ItemDefinition = load("res://resources/items/goop.tres")
	assert_not_null(item, "goop.tres should load as ItemDefinition")
	assert_eq(item.key, "goop", "key should be goop")
	assert_eq(item.display_name, "Goop", "display_name should be Goop")
	assert_eq(item.base_cost, 80, "base_cost should be 80")
	assert_eq(item.max_level, 3, "max_level should be 3")
	assert_eq(item.consolidations_to_l2, 5, "consolidations_to_l2 should be 5")
	assert_eq(item.consolidations_to_l3, 10, "consolidations_to_l3 should be 10")
	assert_eq(item.upgrade_cost, 50, "upgrade_cost should be 50")
	assert_true(item.purchasable, "purchasable should be true")
	assert_eq(item.role, &"ball", "role should be ball")
	assert_eq(item.effects.size(), 0, "should have no effects yet")
