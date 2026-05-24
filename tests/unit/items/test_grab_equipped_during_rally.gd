## Pressing an equipped item mid-rally must not start a gesture; the gate refuses at the entry.
extends GutTest

const BallDragControllerScript: GDScript = preload("res://scripts/items/ball_drag_controller.gd")
const STAT_KEY: StringName = &"paddle_speed"

var _controller: BallDragController
var _item_manager: Node
var _timeout: TimeoutController
var _reconciler: BallReconciler
var _item: ItemDefinition


func before_each() -> void:
	_item_manager = ItemFactory.create_manager(self, "grip_grab_test", STAT_KEY, &"add", 1.0)
	_item = _item_manager.items[0]
	_item_manager.state.item_levels[_item.key] = 1
	_item_manager.equip(_item.key)

	_timeout = load("res://scripts/core/timeout_controller.gd").new()
	add_child_autofree(_timeout)

	_reconciler = load("res://scripts/items/ball_reconciler.gd").new()
	_reconciler.configure(_item_manager)
	add_child_autofree(_reconciler)

	_controller = BallDragControllerScript.new()
	_controller.configure(_item_manager, null, null, _reconciler)
	_controller.timeout_controller = _timeout
	add_child_autofree(_controller)


func test_press_on_equipped_art_is_refused_mid_rally() -> void:
	var ball: Ball = _reconciler.adopt_stored(_item.key, Vector2.ZERO)
	ball.set_play_state(Ball.PlayState.PLAY_NORMAL)

	var started: bool = _controller.grab_equipped_from_character(_item.key)

	assert_false(started, "grab refuses while a ball is in play and timeout is idle")
