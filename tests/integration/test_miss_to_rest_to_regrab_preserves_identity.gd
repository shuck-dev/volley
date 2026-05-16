## Step 5: a Ball misses, rolls to OUT_REST, gets regrabbed, and returns to play —
## one instance, one identity, registry-tracked across every transition.
extends GutTest

const BallDragControllerScript: GDScript = preload("res://scripts/items/ball_drag_controller.gd")
const BallReconcilerScript: GDScript = preload("res://scripts/items/ball_reconciler.gd")
const RackDisplayScript: GDScript = preload("res://scripts/items/rack_display.gd")
const ItemManagerScript: GDScript = preload("res://scripts/items/item_manager.gd")
const ItemTestHelpersScript: GDScript = preload("res://tests/helpers/item_test_helpers.gd")

const COURT_BOUNDS: Rect2 = Rect2(Vector2(-600, -400), Vector2(1200, 800))
const VENUE_BOUNDS: Rect2 = Rect2(Vector2(-2000, -1200), Vector2(4000, 2400))

var _manager: Node
var _host: Node2D
var _rack: RackDisplay
var _drop_target: Area2D
var _reconciler: BallReconciler
var _drag: BallDragController


func before_each() -> void:
	_manager = ItemManagerScript.new()
	_manager.state = ItemState.new()
	_manager.economy = EconomyState.new()
	_manager._effect_manager = EffectManager.new()
	var ball_alpha: ItemDefinition = ItemTestHelpersScript.make_ball_item("ball_alpha")
	var typed_items: Array[ItemDefinition] = [ball_alpha]
	_manager.items.assign(typed_items)
	_manager.economy.friendship_point_balance = 10000
	add_child_autofree(_manager)

	_host = Node2D.new()
	_host.name = "BallHost"
	add_child_autofree(_host)

	_rack = _build_rack(_manager)
	_drop_target = _build_drop_target(Vector2(-1500, 0), Vector2(300, 200))

	_reconciler = BallReconcilerScript.new()
	_reconciler.configure(_manager)
	_host.add_child(_reconciler)

	_drag = BallDragControllerScript.new()
	_drag.configure(_manager, _rack, _drop_target, _reconciler)
	_drag.court_bounds = COURT_BOUNDS
	_drag.venue_bounds = VENUE_BOUNDS
	add_child_autofree(_drag)


func _build_rack(manager: Node) -> RackDisplay:
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


func _build_drop_target(center: Vector2, size: Vector2) -> Area2D:
	var area := Area2D.new()
	area.global_position = center
	var collision := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = size
	collision.shape = rectangle
	area.add_child(collision)
	add_child_autofree(area)
	return area


func _seed_release_velocity(start: Vector2, end: Vector2) -> void:
	_drag._cursor_samples.clear()
	_drag._cursor_samples.append({"time": 0.0, "position": start})
	_drag._cursor_samples.append({"time": 0.04, "position": end})


# Three transitions on one Ball: PLAY -> OUT_REST (miss/release) -> OUT_HELD (grab) -> PLAY (release over court).
# Single instance throughout; reconciler always tracks the same node.
func test_miss_to_rest_to_regrab_preserves_identity() -> void:
	_manager.take("ball_alpha")
	_manager.activate("ball_alpha")
	var live: Ball = _reconciler.get_ball_for_key("ball_alpha")
	assert_not_null(live, "precondition: an in-play Ball exists")
	var live_id: int = live.get_instance_id()

	# 1. Player drags the live ball to the venue floor (OUT_REST). State transitions land
	# inline through the drag controller's synchronous signals; no idle yield required.
	assert_true(_drag.grab_live_ball("ball_alpha", false))
	_drag._gesture_below_threshold = false
	_seed_release_velocity(Vector2.ZERO, Vector2(10, 0))
	var venue_floor := Vector2(1500, 100)
	assert_true(_drag.attempt_release(venue_floor))

	var at_rest: Ball = _reconciler.get_ball_for_key("ball_alpha")
	assert_eq(
		at_rest.get_instance_id(), live_id, "registry still tracks the same Ball after OUT_REST"
	)
	assert_eq(at_rest.play_state, Ball.PlayState.OUT_REST)
	assert_eq(at_rest.global_position, venue_floor)

	# 2. Player picks the at-rest ball back up via grab_live_ball (the OUT_REST grab path).
	assert_true(_drag.grab_live_ball("ball_alpha", false))
	var held: Ball = _reconciler.get_ball_for_key("ball_alpha")
	assert_eq(
		held.get_instance_id(), live_id, "registry still tracks the same Ball during OUT_HELD"
	)
	assert_eq(held.play_state, Ball.PlayState.OUT_HELD)

	# 3. Player releases over the court; the same Ball returns to PLAY.
	_drag._gesture_below_threshold = false
	_seed_release_velocity(Vector2(1500, 100), Vector2(1580, 100))
	var court_point := Vector2(50, 25)
	assert_true(_drag.attempt_release(court_point))

	var played: Ball = _reconciler.get_ball_for_key("ball_alpha")
	assert_not_null(played, "Ball survives the venue → court round trip")
	assert_eq(played.get_instance_id(), live_id, "every transition kept the same Ball instance")
	assert_ne(played.play_state, Ball.PlayState.OUT_HELD)
	assert_ne(played.play_state, Ball.PlayState.OUT_REST)
