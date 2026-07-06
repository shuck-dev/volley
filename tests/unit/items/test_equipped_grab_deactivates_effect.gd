## SH-412: grabbing an equipped item off the character ends its effect at removal, not at drop;
## a cancel snap-back re-equips through the capacity gate so a now-full kit refuses the return.
extends GutTest

const ItemDragControllerScript: GDScript = preload("res://scripts/items/item_drag_controller.gd")
const BallReconcilerScript: GDScript = preload("res://scripts/items/ball_reconciler.gd")
const RackDisplayScript: GDScript = preload("res://scripts/items/rack_display.gd")
const ItemTestHelpersScript: GDScript = preload("res://tests/helpers/item_test_helpers.gd")
const TimeoutControllerScript: GDScript = preload("res://scripts/core/timeout_controller.gd")

const STAT_KEY := &"paddle_speed"
const EFFECT_VALUE := 50.0

var _manager: Node
var _drag: ItemDragController
var _base_speed: float


func _make_equipment(key: String) -> ItemDefinition:
	var outcome := StatOutcome.new()
	outcome.stat_key = STAT_KEY
	outcome.operation = &"add"
	outcome.value = EFFECT_VALUE

	var trigger := Trigger.new()
	trigger.type = &"always"

	var effect := Effect.new()
	effect.trigger = trigger
	effect.outcomes = [outcome]
	effect.min_active_level = 1

	var item := ItemDefinition.new()
	item.key = key
	item.role = &"equipment"
	item.base_cost = 100
	item.cost_scaling = 2.0
	item.max_level = 3
	item.effects = [effect]
	item.art = ItemTestHelpersScript.stub_art()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(16, 16)
	item.at_rest_shape = shape
	return item


func _resolved_speed() -> float:
	return Stats.resolve(GameRules.paddle.paddle_speed, STAT_KEY, _manager)


func before_each() -> void:
	_manager = ItemFactory.create_manager(self)
	var typed_items: Array[ItemDefinition] = [
		_make_equipment("equip_a"),
		_make_equipment("equip_b"),
		_make_equipment("equip_c"),
		_make_equipment("equip_d"),
	]
	_manager.items.assign(typed_items)

	var rack: RackDisplay = RackDisplayScript.new()
	rack.role = &"equipment"
	add_child_autofree(rack)

	var reconciler: BallReconciler = BallReconcilerScript.new()
	reconciler.configure(_manager)
	add_child_autofree(reconciler)

	var drop_area := Area2D.new()
	add_child_autofree(drop_area)

	_drag = ItemDragControllerScript.new()
	_drag.configure(_manager, rack, drop_area, reconciler)
	_drag.court_bounds = Rect2(Vector2(-600, -400), Vector2(1200, 800))
	_drag.venue_bounds = Rect2(Vector2(-2000, -1200), Vector2(4000, 2400))
	var timeout: TimeoutController = TimeoutControllerScript.new()
	timeout._state = TimeoutController.State.AT_EQUIP_POSE
	add_child_autofree(timeout)
	_drag.timeout_controller = timeout
	add_child_autofree(_drag)

	_base_speed = GameRules.paddle.paddle_speed


func after_each() -> void:
	await get_tree().process_frame


func test_grab_off_character_deactivates_effect_immediately() -> void:
	ItemFactory.give(_manager, "equip_a")
	_manager.equip("equip_a")
	assert_eq(
		_resolved_speed(), _base_speed + EFFECT_VALUE, "precondition: equipped item raises the stat"
	)

	_drag.grab_equipped_from_character("equip_a", Vector2.ZERO)

	assert_eq(
		_resolved_speed(),
		_base_speed,
		"the stat returns to base the instant the item leaves the character",
	)
