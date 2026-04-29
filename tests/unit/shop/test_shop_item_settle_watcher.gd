## SH-332: settle watcher polls a falling HeldBody and notifies its ShopItem on rest.
extends GutTest

const SettleWatcherScript: GDScript = preload("res://scripts/shop/shop_item_settle_watcher.gd")
const HeldBodyScript: GDScript = preload("res://scripts/items/held_body.gd")
const HeldBodyScene: PackedScene = preload("res://scenes/items/held_body.tscn")


class _ShopItemStub:
	extends Node
	var notified: bool = false
	var settled_body: HeldBody = null
	var settled_position: Vector2 = Vector2.ZERO

	func notify_body_settled(body: HeldBody, position: Vector2) -> void:
		notified = true
		settled_body = body
		settled_position = position


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

	var watcher: Node = SettleWatcherScript.new()
	watcher.configure(body, stub)
	body.add_child(watcher)

	# Step the watcher past the SETTLE_FRAMES_REQUIRED threshold.
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

	var watcher: Node = SettleWatcherScript.new()
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

	var watcher: Node = SettleWatcherScript.new()
	watcher.configure(body, stub)
	body.add_child(watcher)

	# One step at MAX_LIFETIME_S+epsilon triggers the lifetime-based settle.
	watcher._physics_process(SettleWatcherScript.MAX_LIFETIME_S + 0.1)

	assert_true(stub.notified, "lifetime cap resolves the gesture even on a runaway body")


func test_freed_body_self_terminates_without_notifying() -> void:
	var body: HeldBody = _make_body()
	var stub := _ShopItemStub.new()
	add_child_autofree(stub)

	# Park the watcher beside the body so it survives the body's free for the assertion below.
	var watcher: Node = SettleWatcherScript.new()
	watcher.configure(body, stub)
	add_child_autofree(watcher)
	body.queue_free()
	await get_tree().process_frame

	watcher._physics_process(0.016)
	assert_false(stub.notified, "freed body skips the settle notification")
