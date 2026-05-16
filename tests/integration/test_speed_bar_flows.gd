extends GutTest

## SH-288 multi-ball loop completion: with two balls tracked by the reconciler, the speed bar reads the highest live speed across them.

const ItemManagerScript: GDScript = preload("res://scripts/items/item_manager.gd")
const SpeedBarScript: GDScript = preload("res://scripts/court/speed_bar.gd")
const BallReconcilerScript: GDScript = preload("res://scripts/items/ball_reconciler.gd")
const Cadence: Resource = preload("res://resources/items/cadence.tres")


func test_bar_shows_highest_speed_across_two_tracked_balls() -> void:
	var multi_manager: Node = ItemManagerScript.new()
	multi_manager.state = ItemState.new()
	multi_manager.economy = EconomyState.new()
	multi_manager._effect_manager = EffectManager.new()
	multi_manager.items.assign([Cadence])
	add_child_autofree(multi_manager)

	var host := Node2D.new()
	add_child_autofree(host)
	var reconciler: BallReconciler = BallReconcilerScript.new()
	reconciler.configure(multi_manager)
	add_child_autofree(reconciler)

	var bar: Control = SpeedBarScript.new()
	bar.ball_system = reconciler
	bar.size = Vector2(200, 10)
	add_child_autofree(bar)

	var slow: Ball = reconciler.ensure_ball_for_key("ball_a", Vector2.ZERO, Vector2(100, 0))
	var fast: Ball = reconciler.ensure_ball_for_key("ball_b", Vector2.ZERO, Vector2(100, 0))
	slow.speed = 500.0
	fast.speed = 650.0

	# A speed_changed emit on the slower ball must not lower the bar below the fastest tracked ball.
	slow.speed_changed.emit(slow.speed, slow.min_speed, slow.max_speed)
	assert_gt(bar.current_speed, slow.speed, "bar tracks the fastest ball, not the emitter")
	assert_eq(bar.current_speed, fast.speed)
