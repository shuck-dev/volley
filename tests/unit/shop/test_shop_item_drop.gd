## SH-332: ShopItemDrop polls a falling HeldBody and notifies its ShopItem on rest.
extends GutTest

const ShopItemDropScript: GDScript = preload("res://scripts/shop/shop_item_drop.gd")
const ShopDragTuningScript: GDScript = preload("res://scripts/shop/shop_drag_tuning.gd")
const HeldBodyScript: GDScript = preload("res://scripts/items/held_body.gd")
const HeldBodyScene: PackedScene = preload("res://scenes/items/held_body.tscn")


func _make_tuning() -> ShopDragTuning:
	var tuning: ShopDragTuning = ShopDragTuningScript.new()
	tuning.drag_threshold_px = 2.0
	tuning.settle_velocity_threshold = 4.0
	tuning.settle_frames_required = 6
	tuning.max_lifetime_s = 4.0
	return tuning


class _ShopItemStub:
	extends Node
	var notified: bool = false
	var settled_body: HeldBody = null
	var settled_position: Vector2 = Vector2.ZERO

	func notify_body_settled(body: HeldBody, settled_position_in: Vector2) -> void:
		notified = true
		settled_body = body
		settled_position = settled_position_in


func _make_body() -> HeldBody:
	var body: HeldBody = HeldBodyScene.instantiate()
	# Settle watcher reads linear_velocity directly; no shape needed for the test.
	add_child_autofree(body)
	return body


func test_settle_after_low_velocity_streak_notifies_shop_item() -> void:
	var body: HeldBody = _make_body()
	body.linear_velocity = Vector2.ZERO
	body.global_position = Vector2(123, 45)
	var stub := _ShopItemStub.new()
	add_child_autofree(stub)

	var watcher: Node = ShopItemDropScript.new()
	watcher.tuning = _make_tuning()
	watcher.configure(body, stub)
	body.add_child(watcher)

	# Step the watcher past the settle_frames_required threshold.
	for _i in 8:
		watcher._physics_process(0.016)

	assert_true(stub.notified, "watcher notifies the shop item once velocity stays below threshold")
	assert_eq(
		stub.settled_position, Vector2(123, 45), "settled position is the body's resting position"
	)


func test_high_velocity_resets_streak_and_does_not_settle() -> void:
	var body: HeldBody = _make_body()
	body.linear_velocity = Vector2(500, 0)
	var stub := _ShopItemStub.new()
	add_child_autofree(stub)

	var watcher: Node = ShopItemDropScript.new()
	watcher.tuning = _make_tuning()
	watcher.configure(body, stub)
	body.add_child(watcher)

	for _i in 4:
		watcher._physics_process(0.016)

	assert_false(stub.notified, "fast-moving body does not settle")


func test_max_lifetime_forces_settle_even_when_still_moving() -> void:
	var body: HeldBody = _make_body()
	body.linear_velocity = Vector2(500, 0)
	var stub := _ShopItemStub.new()
	add_child_autofree(stub)

	var tuning: ShopDragTuning = _make_tuning()
	var watcher: Node = ShopItemDropScript.new()
	watcher.tuning = tuning
	watcher.configure(body, stub)
	body.add_child(watcher)

	# One step at max_lifetime_s+epsilon triggers the lifetime-based settle.
	watcher._physics_process(tuning.max_lifetime_s + 0.1)

	assert_true(stub.notified, "lifetime cap resolves the gesture even on a runaway body")
