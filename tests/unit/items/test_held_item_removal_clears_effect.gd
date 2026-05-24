## #691: removing a held equipment item must deactivate its effect; covers the venue-loose-drop
## leak where placement stayed EQUIPPED while the held body was rehomed onto the floor.
extends GutTest

const BallDragControllerScript: GDScript = preload("res://scripts/items/ball_drag_controller.gd")
const HeldBodyScene: PackedScene = preload("res://scenes/items/held_body.tscn")
const STAT_KEY: StringName = &"paddle_speed"
const EFFECT_VALUE: float = 50.0

var _controller: BallDragController
var _item_manager: Node
var _item: ItemDefinition


func before_each() -> void:
	_item_manager = ItemFactory.create_manager(self, "grip_test", STAT_KEY, &"add", EFFECT_VALUE)
	_item = _item_manager.items[0]
	_item_manager.state.item_levels[_item.key] = 1
	_item_manager.equip(_item.key)
	_controller = BallDragControllerScript.new()
	_controller.configure(_item_manager, null, null, null)
	add_child_autofree(_controller)


func test_release_held_body_as_loose_unequips_equipped_item() -> void:
	# Set up the held state without driving the full grab gesture; tests the seam directly.
	var body: HeldBody = HeldBodyScene.instantiate()
	body.item_key = _item.key
	add_child_autofree(body)
	_controller._held_body = body
	_controller._held_key = _item.key

	var base_speed: float = GameRules.paddle.paddle_speed
	assert_eq(
		Stats.resolve(GameRules.paddle.paddle_speed, STAT_KEY, _item_manager),
		base_speed + EFFECT_VALUE,
		"equipped item's effect is active before release",
	)

	_controller._release_held_body_as_loose(Vector2(100, 100))

	assert_eq(
		Stats.resolve(GameRules.paddle.paddle_speed, STAT_KEY, _item_manager),
		base_speed,
		"venue-loose drop of an equipped item deactivates effects within a frame",
	)
	assert_false(
		_item_manager.state.item_placements.has(_item.key),
		"persisted placement funnels through STORED so effects stay unregistered",
	)
