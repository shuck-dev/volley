extends GutTest

const ItemDragControllerScript: GDScript = preload("res://scripts/items/item_drag_controller.gd")
const BallReconcilerScript: GDScript = preload("res://scripts/items/ball_reconciler.gd")
const ShopDropTargetScript: GDScript = preload(
	"res://scripts/items/drop_targets/shop_drop_target.gd"
)

const SHOP_PRIORITY: int = 10

var _manager: Node
var _rack: RackDisplay
var _drop_target: Area2D
var _reconciler: BallReconciler
var _drag: ItemDragController


func before_each() -> void:
	_manager = ItemFactory.create_manager(self)
	var ball_alpha: ItemDefinition = ItemTestHelpers.make_ball_item("ball_alpha")
	_manager.items.assign([ball_alpha] as Array[ItemDefinition])
	_manager.economy.soul_balance = 10000

	_rack = ItemTestHelpers.make_rack(_manager, self)
	_drop_target = ItemTestHelpers.make_drop_area(Vector2(-1000, 0), Vector2(300, 200), self)

	_reconciler = BallReconcilerScript.new()
	_reconciler.configure(_manager)
	add_child_autofree(_reconciler)

	_drag = ItemDragControllerScript.new()
	_drag.configure(_manager, _rack, _drop_target, _reconciler)
	add_child_autofree(_drag)

	ItemTestHelpers.make_drop_targets(_manager, _reconciler, _drop_target.position, self)

	var shop_target: ShopDropTarget = ShopDropTargetScript.new()
	shop_target.priority = SHOP_PRIORITY
	shop_target.add_child(ItemTestHelpers.attach_rect_shape(Vector2(4000, 2400)))
	add_child_autofree(shop_target)


func test_rack_drag_released_over_shop_area_still_lands_on_court() -> void:
	_manager.take("ball_alpha")
	_drag.grab_from_rack("ball_alpha")

	var court_point := Vector2(100, 50)
	assert_true(_drag.attempt_release(court_point))

	assert_true(_manager.is_on_court("ball_alpha"))
	var ball: Ball = _reconciler.get_ball_for_key("ball_alpha")
	assert_not_null(ball)
	assert_eq(ball.global_position, court_point)
