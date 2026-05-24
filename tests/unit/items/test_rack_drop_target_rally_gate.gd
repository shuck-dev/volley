## #692: equipment-role rack drop target refuses drops while a rally is in progress.
extends GutTest

const RackDropTargetScript: GDScript = preload(
	"res://scripts/items/drop_targets/rack_drop_target.gd"
)
const TimeoutControllerScript: GDScript = preload("res://scripts/core/timeout_controller.gd")
const BallReconcilerScript: GDScript = preload("res://scripts/items/ball_reconciler.gd")
const BallScene: PackedScene = preload("res://scenes/ball.tscn")

const STAT_KEY: StringName = &"paddle_speed"

var _target: RackDropTarget
var _drop_area: Area2D
var _timeout_controller: TimeoutController
var _reconciler: BallReconciler
var _item_manager: Node
var _item: ItemDefinition


func before_each() -> void:
	_item_manager = ItemFactory.create_manager(self, "grip_gate_test", STAT_KEY, &"add", 1.0)
	_item = _item_manager.items[0]
	_item_manager.state.item_levels[_item.key] = 1
	_item_manager.equip(_item.key)

	_drop_area = Area2D.new()
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(200, 200)
	collision.shape = shape
	_drop_area.add_child(collision)
	_drop_area.position = Vector2.ZERO
	add_child_autofree(_drop_area)

	_timeout_controller = TimeoutControllerScript.new()
	add_child_autofree(_timeout_controller)

	_reconciler = BallReconcilerScript.new()
	_reconciler.configure(_item_manager)
	add_child_autofree(_reconciler)

	_target = RackDropTargetScript.new()
	_target.configure(_item_manager, _drop_area, &"equipment", _timeout_controller, _reconciler)


func _spawn_ball_in_play() -> Ball:
	var ball: Ball = BallScene.instantiate()
	add_child_autofree(ball)
	ball.set_play_state(Ball.PlayState.PLAY_NORMAL)
	_reconciler._balls_by_key[_item.key] = ball
	return ball


func test_accepts_when_timeout_idle_and_no_ball_in_play() -> void:
	assert_true(
		_target.can_accept(_item.key, Vector2.ZERO),
		"equipment rack accepts during initial setup (idle, no ball in play)",
	)


func test_rejects_when_rally_in_progress() -> void:
	_spawn_ball_in_play()
	assert_false(
		_target.can_accept(_item.key, Vector2.ZERO),
		"equipment rack refuses during an active rally",
	)


func test_accepts_during_timeout_even_with_a_ball_in_play() -> void:
	_spawn_ball_in_play()
	# Skip the walk; force AT_EQUIP_POSE so is_active() returns true.
	_timeout_controller._state = TimeoutController.State.AT_EQUIP_POSE
	assert_true(
		_target.can_accept(_item.key, Vector2.ZERO),
		"equipment rack accepts during timeout regardless of ball state",
	)
