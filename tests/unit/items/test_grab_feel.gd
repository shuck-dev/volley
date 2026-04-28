## SH-297 grab feel: ease-to-cursor tween and cursor state machine.
extends GutTest

const BallDragControllerScript: GDScript = preload("res://scripts/items/ball_drag_controller.gd")
const BallReconcilerScript: GDScript = preload("res://scripts/items/ball_reconciler.gd")
const RackDisplayScript: GDScript = preload("res://scripts/items/rack_display.gd")
const ItemTestHelpersScript: GDScript = preload("res://tests/helpers/item_test_helpers.gd")
const CursorStateScript: GDScript = preload("res://scripts/items/cursor_state.gd")
const CursorOverlayScript: GDScript = preload("res://scripts/hud/cursor_overlay.gd")

var _manager: Node
var _host: Node2D
var _rack: RackDisplay
var _drop_target: Area2D
var _reconciler: BallReconciler
var _drag: BallDragController
var _overlay: CursorOverlay


func _make_rack(manager: Node) -> RackDisplay:
	var rack: RackDisplay = RackDisplayScript.new()
	rack.role = &"ball"
	var slot_container := Node2D.new()
	slot_container.name = "SlotContainer"
	rack.add_child(slot_container)
	for index in 4:
		var marker := Node2D.new()
		marker.name = "SlotMarker%d" % index
		marker.position = Vector2(index * 32, 0)
		slot_container.add_child(marker)
	rack.slot_container = slot_container
	rack.configure(manager)
	add_child_autofree(rack)
	return rack


func _make_drop_target(position: Vector2, size: Vector2) -> Area2D:
	var area := Area2D.new()
	area.global_position = position
	var collision := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = size
	collision.shape = rectangle
	area.add_child(collision)
	add_child_autofree(area)
	return area


func before_each() -> void:
	_manager = ItemFactory.create_manager(self)
	var ball_alpha: ItemDefinition = ItemTestHelpersScript.make_ball_item("ball_alpha")
	var typed_items: Array[ItemDefinition] = [ball_alpha]
	_manager.items.assign(typed_items)
	_manager._progression.friendship_point_balance = 10000

	_host = Node2D.new()
	add_child_autofree(_host)

	_rack = _make_rack(_manager)
	_drop_target = _make_drop_target(Vector2(-1000, 0), Vector2(300, 200))

	_reconciler = BallReconcilerScript.new()
	_reconciler.configure(_manager, _host)
	add_child_autofree(_reconciler)

	_drag = BallDragControllerScript.new()
	_drag.configure(_manager, _rack, _drop_target, _reconciler)
	_drag.court_bounds = Rect2(Vector2(-600, -400), Vector2(1200, 800))
	_drag.venue_bounds = Rect2(Vector2(-2000, -1200), Vector2(4000, 2400))
	_overlay = CursorOverlayScript.new()
	_drag.add_child(_overlay)
	_drag.cursor_overlay = _overlay
	add_child_autofree(_drag)


func test_held_token_starts_at_grab_origin_not_at_cursor() -> void:
	# AC: ~80 ms ease-to-cursor on grab. The held token spawns at the grab origin and
	# eases to the cursor; it must not teleport-and-snap.
	_manager.take("ball_alpha")
	var press_origin := Vector2(123, 45)

	_drag.grab_from_rack("ball_alpha", press_origin)

	var token: Node2D = _drag.get_held_token()
	assert_not_null(token)
	assert_eq(
		token.global_position, press_origin, "lift starts at the press origin, not the cursor"
	)


func test_held_token_modulation_starts_transparent_and_eases_in() -> void:
	# AC: position, scale, and modulation all read continuously through the lift.
	_manager.take("ball_alpha")
	_drag.grab_from_rack("ball_alpha", Vector2(0, 0))
	var token: Node2D = _drag.get_held_token()
	assert_eq(token.modulate.a, 0.0, "modulation alpha is 0 at lift start; eases up to 1")


func test_cursor_state_default_when_no_gesture() -> void:
	assert_eq(_drag.get_cursor_state(), CursorStateScript.State.DEFAULT)


func test_cursor_state_can_drop_over_rack_for_role() -> void:
	# AC: cursor flips to CAN_DROP when a target accepts at the held position.
	_manager.take("ball_alpha")
	_drag.grab_from_rack("ball_alpha")
	var rack_position: Vector2 = _drop_target.global_position

	var state: int = _drag._derive_cursor_state(rack_position)

	assert_eq(state, CursorStateScript.State.CAN_DROP)


func test_cursor_state_dragging_in_empty_court_neighbourhood() -> void:
	# Mid-venue but not over a target: cursor reads DRAGGING.
	_manager.take("ball_alpha")
	_drag.grab_from_rack("ball_alpha")
	# A point well outside court bounds (-420..420) but inside venue bounds.
	var venue_only := Vector2(800, 0)

	var state: int = _drag._derive_cursor_state(venue_only)

	# venue_only is outside court rect AND not over the rack drop target.
	assert_eq(state, CursorStateScript.State.DRAGGING)


func test_cursor_state_emits_change_signal_on_transition() -> void:
	# Listeners (overlay, future cursor textures) get a single transition per change.
	_manager.take("ball_alpha")
	watch_signals(_drag)
	_drag.grab_from_rack("ball_alpha")
	# Force a cursor state update via the public derivation path.
	_drag._set_cursor_state(CursorStateScript.State.CAN_DROP, Vector2.ZERO)
	_drag._set_cursor_state(CursorStateScript.State.CAN_DROP, Vector2.ZERO)  # debounced
	_drag._set_cursor_state(CursorStateScript.State.DRAGGING, Vector2.ZERO)

	# Two transitions expected: -> CAN_DROP, -> DRAGGING. The repeat is deduped.
	assert_signal_emit_count(_drag, "cursor_state_changed", 2)


func test_cursor_overlay_visibility_follows_state() -> void:
	# Default state hides the overlay so the OS cursor reads cleanly without a gesture.
	_overlay.set_state(CursorStateScript.State.DEFAULT, Vector2.ZERO)
	assert_false(_overlay.visible)
	_overlay.set_state(CursorStateScript.State.DRAGGING, Vector2.ZERO)
	assert_true(_overlay.visible)
	_overlay.set_state(CursorStateScript.State.CAN_DROP, Vector2(50, 50))
	assert_eq(_overlay.global_position, Vector2(50, 50))
