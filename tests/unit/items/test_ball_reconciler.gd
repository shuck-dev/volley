## SH-218 reconciler keeps the live ball set aligned with on_court[&ball].
extends GutTest

const BallReconcilerScript: GDScript = preload("res://scripts/items/ball_reconciler.gd")
const ItemTestHelpersScript: GDScript = preload("res://tests/helpers/item_test_helpers.gd")

var _manager: Node
var _host: Node2D
var _reconciler: BallReconciler


func before_each() -> void:
	_manager = ItemFactory.create_manager(self)
	var ball_alpha: ItemDefinition = ItemTestHelpersScript.make_ball_item("ball_alpha")
	var ball_beta: ItemDefinition = ItemTestHelpersScript.make_ball_item("ball_beta")
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


func test_duplicate_court_changed_signal_does_not_spawn_a_second_ball() -> void:
	# Drive the handler directly to bypass upstream ItemManager dedup.
	_reconciler._on_court_changed("ball_alpha", true)
	_reconciler._on_court_changed("ball_alpha", true)
	assert_eq(
		_permanent_ball_count(),
		1,
		"reconciler should guard against duplicate on_court notifications",
	)


func test_release_ball_returns_null_when_no_ball_tracked() -> void:
	assert_null(
		_reconciler.release_ball("ball_alpha"),
		"releasing an untracked key returns null without side effects",
	)


func test_get_ball_for_key_erases_stale_instances() -> void:
	var ball: Ball = _reconciler.spawn_for_key("ball_alpha", Vector2.ZERO, Vector2.ZERO)
	ball.free()
	assert_null(
		_reconciler.get_ball_for_key("ball_alpha"),
		"freed instances should be evicted from the lookup",
	)
	# A subsequent spawn must succeed cleanly, not collide with the stale slot.
	var replacement: Ball = _reconciler.spawn_for_key("ball_alpha", Vector2(5, 5), Vector2.ZERO)
	assert_not_null(replacement)
	assert_eq(replacement.global_position, Vector2(5, 5))


func test_off_event_without_tracked_ball_is_noop() -> void:
	# Drives the `ball == null` early-return branch in _on_court_changed.
	_reconciler._on_court_changed("ball_alpha", false)
	assert_eq(_permanent_ball_count(), 0, "off events for untracked keys should not spawn anything")


func test_spawn_for_existing_on_load_reconciles_from_progression() -> void:
	_manager.take("ball_alpha")
	_manager.activate("ball_alpha")
	var preloaded_host := Node2D.new()
	add_child_autofree(preloaded_host)
	var fresh: BallReconciler = BallReconcilerScript.new()
	fresh.configure(_manager, preloaded_host)
	fresh.spawn_for_existing_on_load = true
	add_child_autofree(fresh)

	var found: Ball = fresh.get_ball_for_key("ball_alpha")
	assert_not_null(found, "on-load reconcile should spawn balls for already-on-court items")


func test_default_spawn_position_falls_back_to_zero_for_non_node2d_host() -> void:
	var plain_host := Node.new()
	add_child_autofree(plain_host)
	var non_spatial: BallReconciler = BallReconcilerScript.new()
	non_spatial.configure(_manager, plain_host)
	add_child_autofree(non_spatial)
	assert_eq(
		non_spatial._default_spawn_position(),
		Vector2.ZERO,
		"non-Node2D hosts yield the zero-vector fallback",
	)


func test_spawn_for_key_moves_existing_ball_without_duplicating() -> void:
	var first: Ball = _reconciler.spawn_for_key("ball_alpha", Vector2.ZERO, Vector2.ZERO)
	var second: Ball = _reconciler.spawn_for_key("ball_alpha", Vector2(42, -7), Vector2(3, 4))
	assert_eq(first, second, "second spawn with the same key reuses the existing ball")
	assert_eq(second.global_position, Vector2(42, -7))
	assert_eq(second.linear_velocity, Vector2(3, 4))
	assert_eq(_permanent_ball_count(), 1)
