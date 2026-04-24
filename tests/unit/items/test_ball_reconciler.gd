## SH-218 reconciler keeps the live ball set aligned with on_court[&ball].
extends GutTest

const BallReconcilerScript: GDScript = preload("res://scripts/items/ball_reconciler.gd")

var _manager: Node
var _host: Node2D
var _reconciler: BallReconciler


func _stub_art() -> PackedScene:
	var scene := PackedScene.new()
	scene.pack(Node2D.new())
	return scene


func _make_ball_item(key: String) -> ItemDefinition:
	var item := ItemDefinition.new()
	item.key = key
	item.role = &"ball"
	item.base_cost = 10
	item.cost_scaling = 2.0
	item.max_level = 3
	item.effects = []
	item.art = _stub_art()
	return item


func before_each() -> void:
	_manager = ItemFactory.create_manager(self)
	var ball_alpha := _make_ball_item("ball_alpha")
	var ball_beta := _make_ball_item("ball_beta")
	var typed_items: Array[ItemDefinition] = [ball_alpha, ball_beta]
	_manager.items.assign(typed_items)
	_manager._progression.friendship_point_balance = 10000

	_host = Node2D.new()
	add_child_autofree(_host)

	_reconciler = BallReconcilerScript.new()
	_reconciler.configure(_manager, _host)
	add_child_autofree(_reconciler)


func _permanent_ball_count() -> int:
	var count := 0
	for child in _host.get_children():
		if child is Ball:
			count += 1
	return count


func test_activating_a_ball_item_spawns_a_live_ball() -> void:
	_manager.take("ball_alpha")
	assert_eq(_permanent_ball_count(), 0, "precondition: no live balls before activation")

	_manager.activate("ball_alpha")
	assert_eq(_permanent_ball_count(), 1, "activation should spawn one live ball")
	assert_not_null(
		_reconciler.get_ball_for_key("ball_alpha"), "reconciler should track the live ball by key"
	)


func test_deactivating_a_ball_item_removes_its_live_ball() -> void:
	_manager.take("ball_alpha")
	_manager.activate("ball_alpha")
	assert_eq(_permanent_ball_count(), 1)

	_manager.deactivate("ball_alpha")
	await get_tree().process_frame
	assert_eq(_permanent_ball_count(), 0, "deactivation should remove the live ball")
	assert_null(_reconciler.get_ball_for_key("ball_alpha"))


func test_second_activation_does_not_duplicate_the_live_ball() -> void:
	_manager.take("ball_alpha")
	_manager.activate("ball_alpha")
	_manager.activate("ball_alpha")
	assert_eq(_permanent_ball_count(), 1, "activating twice should not spawn a second ball")


func test_independent_ball_items_each_get_their_own_live_instance() -> void:
	_manager.take("ball_alpha")
	_manager.take("ball_beta")
	_manager.activate("ball_alpha")
	_manager.activate("ball_beta")

	assert_eq(_permanent_ball_count(), 2)
	assert_not_null(_reconciler.get_ball_for_key("ball_alpha"))
	assert_not_null(_reconciler.get_ball_for_key("ball_beta"))


func test_spawn_for_key_places_ball_at_requested_position_and_velocity() -> void:
	var ball: Ball = _reconciler.spawn_for_key("ball_alpha", Vector2(100, 50), Vector2(120, 0))
	assert_not_null(ball)
	assert_eq(ball.global_position, Vector2(100, 50))
	assert_eq(ball.linear_velocity, Vector2(120, 0))


func test_release_ball_returns_and_drops_tracking() -> void:
	_manager.take("ball_alpha")
	_manager.activate("ball_alpha")
	var live: Ball = _reconciler.get_ball_for_key("ball_alpha")
	assert_not_null(live)

	var released: Ball = _reconciler.release_ball("ball_alpha")
	assert_eq(released, live)
	assert_null(_reconciler.get_ball_for_key("ball_alpha"))


func test_removing_a_deactivated_ball_deferred_frees_it() -> void:
	_manager.take("ball_alpha")
	_manager.activate("ball_alpha")
	var live: Ball = _reconciler.get_ball_for_key("ball_alpha")
	_manager.deactivate("ball_alpha")
	await get_tree().process_frame
	assert_false(is_instance_valid(live), "deactivated ball should be freed after a frame")
