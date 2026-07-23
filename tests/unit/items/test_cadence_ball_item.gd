extends GutTest


func test_cadence_ball_tres_loads() -> void:
	var ball: ItemDefinition = load("res://resources/items/cadence_ball.tres")
	assert_eq(ball.key, "cadence", "key should be cadence")
	assert_eq(ball.role, &"ball", "role should be ball")
	assert_eq(ball.display_name, "Cadence", "display_name should be Cadence")
	assert_eq(ball.base_cost, 100, "base_cost should be 100")
	assert_true(ball.purchasable, "purchasable should be true")
	assert_not_null(ball.art, "art should be set")
	assert_eq(ball.effects.size(), 1, "cadence should carry exactly one effect")
