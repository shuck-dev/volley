## SH-218 reconciler keeps the live ball set aligned with on_court[&ball].
extends GutTest

const BallReconcilerScript: GDScript = preload("res://scripts/items/ball_reconciler.gd")
const ItemManagerScript: GDScript = preload("res://scripts/items/item_manager.gd")
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


func test_ensure_ball_for_key_places_ball_at_requested_position_and_velocity() -> void:
	var ball: Ball = _reconciler.ensure_ball_for_key(
		"ball_alpha", Vector2(100, 50), Vector2(120, 0)
	)
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
	var ball: Ball = _reconciler.ensure_ball_for_key("ball_alpha", Vector2.ZERO, Vector2.ZERO)
	ball.free()
	assert_null(
		_reconciler.get_ball_for_key("ball_alpha"),
		"freed instances should be evicted from the lookup",
	)
	# A subsequent spawn must succeed cleanly, not collide with the stale slot.
	var replacement: Ball = _reconciler.ensure_ball_for_key(
		"ball_alpha", Vector2(5, 5), Vector2.ZERO
	)
	assert_not_null(replacement)
	assert_eq(replacement.global_position, Vector2(5, 5))


func test_off_event_without_tracked_ball_is_noop() -> void:
	# Drives the `ball == null` early-return branch in _on_court_changed.
	_reconciler._on_court_changed("ball_alpha", false)
	assert_eq(_permanent_ball_count(), 0, "off events for untracked keys should not spawn anything")


func test_reload_reconciles_on_court_items_without_authored_ball_node() -> void:
	# Simulates a session reload where training_ball is ON_COURT in the save but
	# has no authored Ball child in the scene (SH-289 GONE-on-buy regression).
	_manager.take("ball_alpha")
	_manager.activate("ball_alpha")
	var preloaded_host := Node2D.new()
	add_child_autofree(preloaded_host)
	var fresh: BallReconciler = BallReconcilerScript.new()
	fresh.configure(_manager, preloaded_host)
	add_child_autofree(fresh)
	# Flush deferred calls (adopt_pre_existing_balls + _reconcile_initial_state).
	await get_tree().process_frame

	var found: Ball = fresh.get_ball_for_key("ball_alpha")
	assert_not_null(
		found, "reload reconcile should spawn balls for on-court items with no authored node"
	)


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


func test_bring_into_play_propagates_preserved_speed_for_spawn_and_existing_ball() -> void:
	# SH-288: friendship energy carries through bring_into_play onto both newly spawned and
	# already-tracked balls; both branches must re-magnitude linear_velocity along its direction.
	_manager.take("ball_alpha")
	var spawned: Ball = _reconciler.bring_into_play(
		"ball_alpha", Vector2(10, 20), Vector2(120, 0), 600.0
	)
	assert_not_null(spawned)
	assert_eq(spawned.speed, 600.0, "preserved_speed should set the spawned ball's speed")
	assert_almost_eq(
		spawned.linear_velocity.length(),
		600.0,
		0.001,
		"spawned ball's velocity is re-magnituded to the preserved speed",
	)

	# Existing-ball branch: ensure_ball_for_key reuses the tracked ball and still re-magnitudes.
	var existing: Ball = _reconciler.bring_into_play(
		"ball_alpha", Vector2(0, 0), Vector2(100, 0), 450.0
	)
	assert_eq(existing, spawned, "existing tracked ball is reused, not duplicated")
	assert_eq(existing.speed, 450.0)
	assert_almost_eq(existing.linear_velocity.length(), 450.0, 0.001)


func test_ball_added_and_removed_signals_fire_per_lifecycle_event() -> void:
	# SH-288: spawn, release, and deactivate each emit the matching lifecycle signal exactly once
	# with the matching Ball argument; downstream wiring relies on per-event single emissions.
	watch_signals(_reconciler)
	_manager.take("ball_alpha")
	_manager.activate("ball_alpha")
	var live: Ball = _reconciler.get_ball_for_key("ball_alpha")
	assert_eq(
		get_signal_emit_count(_reconciler, "ball_added"),
		1,
		"spawn emits ball_added once",
	)
	assert_signal_emitted_with_parameters(_reconciler, "ball_added", [live])

	var released: Ball = _reconciler.release_ball("ball_alpha")
	assert_eq(released, live)
	assert_eq(
		get_signal_emit_count(_reconciler, "ball_removed"),
		1,
		"release emits ball_removed once",
	)
	assert_signal_emitted_with_parameters(_reconciler, "ball_removed", [live])

	# Spawn a second ball under a different key and drive the deactivate removal path.
	_manager.take("ball_beta")
	_manager.activate("ball_beta")
	var beta_live: Ball = _reconciler.get_ball_for_key("ball_beta")
	_manager.deactivate("ball_beta")
	assert_eq(
		get_signal_emit_count(_reconciler, "ball_removed"),
		2,
		"deactivate emits a second ball_removed",
	)
	assert_signal_emitted_with_parameters(_reconciler, "ball_removed", [beta_live])
	await get_tree().process_frame


## SH-289: when base_ball is authored and training_ball is ON_COURT in the save,
## the initial reconcile must spawn training_ball even though adopt_pre_existing_balls
## fires court_changed for base_ball first.
func test_reconcile_spawns_saved_on_court_ball_when_authored_sibling_triggers_court_changed(
) -> void:
	# Fresh manager with both ball items; no friendship points needed — we set placements directly.
	var saved_manager: Node = ItemManagerScript.new()
	var mock_storage: SaveStorage = double(SaveStorage).new()
	stub(mock_storage.write).to_return(true)
	stub(mock_storage.read).to_return("")
	saved_manager._progression = ProgressionData.new(mock_storage)
	saved_manager._effect_manager = EffectManager.new()
	var base_ball_item: ItemDefinition = ItemTestHelpersScript.make_ball_item("base_ball")
	var training_ball_item: ItemDefinition = ItemTestHelpersScript.make_ball_item("training_ball")
	var typed_items: Array[ItemDefinition] = [base_ball_item, training_ball_item]
	saved_manager.items.assign(typed_items)
	add_child_autofree(saved_manager)

	# Simulate saved state: training_ball ON_COURT, base_ball level set so adopt_authored works.
	saved_manager._progression.item_levels["base_ball"] = 1
	saved_manager._progression.item_levels["training_ball"] = 1
	saved_manager._progression.item_placements["training_ball"] = Placement.ON_COURT

	# Host has one authored Ball child for base_ball (the always-present authored scene child).
	var fresh_host := Node2D.new()
	add_child_autofree(fresh_host)
	var authored_ball: Ball = preload("res://scenes/ball.tscn").instantiate()
	authored_ball.item_key = "base_ball"
	fresh_host.add_child(authored_ball)

	var fresh_reconciler: BallReconciler = BallReconcilerScript.new()
	fresh_reconciler.configure(saved_manager, fresh_host)
	add_child_autofree(fresh_reconciler)

	# Flush both deferred calls: adopt_pre_existing_balls then _reconcile_initial_state.
	await get_tree().process_frame

	assert_not_null(
		fresh_reconciler.get_ball_for_key("training_ball"),
		"reconcile must spawn training_ball even when base_ball adopt triggers court_changed first",
	)


func test_ensure_ball_for_key_moves_existing_ball_without_duplicating() -> void:
	var first: Ball = _reconciler.ensure_ball_for_key("ball_alpha", Vector2.ZERO, Vector2.ZERO)
	var second: Ball = _reconciler.ensure_ball_for_key("ball_alpha", Vector2(42, -7), Vector2(3, 4))
	assert_eq(first, second, "second spawn with the same key reuses the existing ball")
	assert_eq(second.global_position, Vector2(42, -7))
	assert_eq(second.linear_velocity, Vector2(3, 4))
	assert_eq(_permanent_ball_count(), 1)
