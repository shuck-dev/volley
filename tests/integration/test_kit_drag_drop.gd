## SH-569 Ball Kit: verifies ItemDragController's screen-space Kit path alongside the existing
## world-space drop_targets pipeline (rack/court/venue), which stays unaffected.
extends GutTest

const ItemDragControllerScript: GDScript = preload("res://scripts/items/item_drag_controller.gd")
const BallReconcilerScript: GDScript = preload("res://scripts/items/ball_reconciler.gd")

var _manager: Node
var _rack: RackDisplay
var _drop_target: Area2D
var _reconciler: BallReconciler
var _drag: ItemDragController
var _kit: BallKit


func before_each() -> void:
	_manager = BallFactory.create_manager(self)
	_manager.items.assign([BallTestHelpers.make_ball_item("ball_alpha")] as Array[BallDefinition])
	_manager.economy.soul_balance = 10000

	_rack = BallTestHelpers.make_rack(_manager, self)
	_drop_target = BallTestHelpers.make_drop_area(Vector2(-1500, 0), Vector2(300, 200), self)

	_reconciler = BallReconcilerScript.new()
	_reconciler.configure(_manager)
	_reconciler.ball_rack = _rack
	add_child_autofree(_reconciler)

	_kit = BallTestHelpers.make_kit(_manager, self, 1)
	await get_tree().process_frame

	_drag = ItemDragControllerScript.new()
	_drag.configure(_manager, _rack, _drop_target, _reconciler)
	_drag.kit = _kit
	_drag.connect_kit()
	add_child_autofree(_drag)

	BallTestHelpers.make_drop_targets(_manager, _reconciler, _drop_target.position, self)


func after_each() -> void:
	await get_tree().process_frame


func _kit_slot_screen_position() -> Vector2:
	var slot: KitSlot = _kit.slot_container.get_child(0)
	return slot.get_global_rect().get_center()


func test_releasing_over_a_kit_slot_moves_the_ball_into_the_kit() -> void:
	_manager.take("ball_alpha")
	assert_true(_drag.grab_from_rack("ball_alpha_1"))
	_drag._gesture_below_threshold = false

	var accepted: bool = _drag.attempt_release(Vector2(9999, 9999), _kit_slot_screen_position())

	assert_true(accepted, "a release over a Kit slot should be accepted")
	assert_eq(_manager.get_placement("ball_alpha_1"), Placement.IN_KIT)


func test_kit_slot_hit_takes_priority_over_an_overlapping_world_drop_target() -> void:
	_manager.take("ball_alpha")
	assert_true(_drag.grab_from_rack("ball_alpha_1"))
	_drag._gesture_below_threshold = false

	# The rack's own DropTarget accepts here too; the screen-space Kit hit must win.
	var accepted: bool = _drag.attempt_release(_drop_target.position, _kit_slot_screen_position())

	assert_true(accepted)
	assert_eq(_manager.get_placement("ball_alpha_1"), Placement.IN_KIT)


func test_release_falls_through_to_world_targets_when_no_kit_slot_is_hit() -> void:
	_manager.take("ball_alpha")
	assert_true(_drag.grab_from_rack("ball_alpha_1"))
	_drag._gesture_below_threshold = false

	var accepted: bool = _drag.attempt_release(_drop_target.position, Vector2(-99999, -99999))

	assert_true(accepted, "the world-space rack target should still accept when Kit is not hit")
	assert_eq(_manager.get_placement("ball_alpha_1"), Placement.STORED)


func test_full_kit_rejects_a_different_ball_and_falls_through() -> void:
	var alpha: BallDefinition = BallTestHelpers.make_ball_item("ball_alpha")
	var beta: BallDefinition = BallTestHelpers.make_ball_item("ball_beta")
	_manager.items.assign([alpha, beta] as Array[BallDefinition])
	_manager.take("ball_alpha")
	_manager.take("ball_beta")
	_manager.add_to_kit("ball_alpha_1")
	assert_eq(_manager.get_kit_items().size(), 1, "precondition: the single Kit slot is full")

	assert_true(_drag.grab_from_rack("ball_beta_1"))
	_drag._gesture_below_threshold = false

	var accepted: bool = _drag.attempt_release(_drop_target.position, _kit_slot_screen_position())

	assert_true(accepted, "the gesture still resolves via the world-space rack target")
	assert_eq(
		_manager.get_placement("ball_beta_1"),
		Placement.STORED,
		"a full Kit slot must reject a different ball rather than swap it in",
	)
