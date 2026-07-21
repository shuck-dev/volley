extends GutTest


func test_cadence_ball_tres_loads() -> void:
	var ball: ItemDefinition = load("res://resources/items/cadence_ball.tres")
	assert_eq(ball.key, "cadence", "key should be cadence")
	assert_eq(ball.role, &"ball", "role should be ball")
	assert_eq(ball.display_name, "Cadence", "display_name should be Cadence")
	assert_eq(ball.base_cost, 100, "base_cost should be 100")
	assert_eq(ball.max_level, 3, "max_level should be 3")
	assert_eq(ball.consolidations_to_l2, 5, "consolidations_to_l2 should be 5")
	assert_eq(ball.consolidations_to_l3, 10, "consolidations_to_l3 should be 10")
	assert_eq(ball.upgrade_cost, 50, "upgrade_cost should be 50")
	assert_true(ball.purchasable, "purchasable should be true")
	assert_not_null(ball.art, "art should be set")
