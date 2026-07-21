extends GutTest


func test_comeback_tres_loads_with_correct_base_cost() -> void:
	var ball: ItemDefinition = load("res://resources/items/comeback.tres")
	assert_eq(ball.key, "comeback", "key should be 'comeback'")
	assert_eq(ball.base_cost, 100, "base_cost should be 100")
	assert_eq(ball.max_level, 3, "max_level should be 3")
	assert_true(ball.purchasable, "purchasable should be true")
