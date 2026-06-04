## Grab feel: ease-to-cursor tween and cursor state machine.
extends GutTest

const ItemDragControllerScript: GDScript = preload("res://scripts/items/item_drag_controller.gd")
const BallReconcilerScript: GDScript = preload("res://scripts/items/ball_reconciler.gd")
const RackDisplayScript: GDScript = preload("res://scripts/items/rack_display.gd")
const ItemTestHelpersScript: GDScript = preload("res://tests/helpers/item_test_helpers.gd")

var _manager: Node
var _host: Node2D
var _rack: RackDisplay
var _drop_target: Area2D
var _reconciler: BallReconciler
var _drag: ItemDragController


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
	_manager.economy.soul_balance = 10000

	_host = Node2D.new()
	add_child_autofree(_host)

	_rack = _make_rack(_manager)
	_drop_target = _make_drop_target(Vector2(-1000, 0), Vector2(300, 200))

	_reconciler = BallReconcilerScript.new()
	_reconciler.configure(_manager)
	add_child_autofree(_reconciler)

	_drag = ItemDragControllerScript.new()
	_drag.configure(_manager, _rack, _drop_target, _reconciler)
	_drag.court_bounds = Rect2(Vector2(-600, -400), Vector2(1200, 800))
	_drag.venue_bounds = Rect2(Vector2(-2000, -1200), Vector2(4000, 2400))
	add_child_autofree(_drag)


func test_held_body_starts_at_grab_origin_not_at_cursor() -> void:
	_manager.take("ball_alpha")
	var press_origin := Vector2(123, 45)

	_drag.grab_from_rack("ball_alpha", press_origin)

	var body: HeldBody = _drag.get_held_body()
	assert_not_null(body)
	assert_eq(body.global_position, press_origin, "lift starts at the press origin, not the cursor")


func test_held_body_modulation_starts_transparent_and_eases_in() -> void:
	_manager.take("ball_alpha")
	_drag.grab_from_rack("ball_alpha", Vector2(0, 0))
	var body: HeldBody = _drag.get_held_body()
	assert_eq(body.modulate.a, 0.0, "modulation alpha is 0 at lift start; eases up to 1")


func test_held_body_settles_on_cursor_without_teleporting() -> void:
	_manager.take("ball_alpha")
	var origin := Vector2(100, 0)
	var cursor_target := Vector2(500, 200)
	_drag.grab_from_rack("ball_alpha", origin)
	var body: HeldBody = _drag.get_held_body()
	var ease_window: float = _drag.grab_ease_duration_s
	var tick_count: int = 16
	var tick_dt: float = ease_window / float(tick_count)
	var max_step: float = 0.0
	var previous: Vector2 = body.global_position
	var total_distance: float = origin.distance_to(cursor_target)

	for i in tick_count:
		_drag._grab_ease_elapsed = minf(_drag._grab_ease_elapsed + tick_dt, ease_window)
		_drag._apply_grab_ease(_drag._grab_ease_progress(), cursor_target)
		var step: float = previous.distance_to(body.global_position)
		max_step = maxf(max_step, step)
		previous = body.global_position

	assert_almost_eq(body.global_position.x, cursor_target.x, 0.5)
	assert_almost_eq(body.global_position.y, cursor_target.y, 0.5)
	assert_almost_eq(body.modulate.a, 1.0, 0.001)
	# Half the trip in one tick would be a snap; cap step well below that.
	assert_lt(max_step, total_distance * 0.5, "no mid-window teleport")


func test_release_on_no_target_keeps_item_held() -> void:
	_manager.take("ball_alpha")
	_drag.grab_from_rack("ball_alpha")
	_drag._mouse_button_down = false
	var nowhere := Vector2(0, 99999)

	var accepted: bool = _drag.attempt_release(nowhere)

	assert_false(accepted, "no accepting target means release returns false and item stays held")
	assert_true(_drag.is_dragging(), "gesture is still live after a rejected release")
