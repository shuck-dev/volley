## SH-218 a ball marked as dragging ignores paddle body_entered so a grab-edge contact
## does not register as a hit during the handoff.
extends GutTest

var _ball: Ball
var _manager: Node


class StubPaddle:
	extends Node2D
	var hit_count: int = 0

	func on_ball_hit() -> void:
		hit_count += 1


func before_each() -> void:
	var mock_storage: SaveStorage = double(SaveStorage).new()
	stub(mock_storage.write).to_return(true)
	stub(mock_storage.read).to_return("")

	_manager = load("res://scripts/items/item_manager.gd").new()
	_manager._progression = ProgressionData.new(mock_storage)
	_manager._effect_manager = EffectManager.new()
	var items: Array[ItemDefinition] = [preload("res://resources/items/training_ball.tres")]
	_manager.items.assign(items)
	add_child_autofree(_manager)

	_ball = load("res://scripts/entities/ball.gd").new()
	_ball._item_manager = _manager
	add_child_autofree(_ball)


func test_body_entered_ignored_while_dragging() -> void:
	var paddle := StubPaddle.new()
	add_child_autofree(paddle)

	_ball.set_dragging(true)
	_ball._on_body_entered(paddle)
	assert_eq(paddle.hit_count, 0, "dragging ball must ignore paddle contacts")


func test_body_entered_registers_after_drag_ends() -> void:
	var paddle := StubPaddle.new()
	add_child_autofree(paddle)

	_ball.set_dragging(true)
	_ball.set_dragging(false)
	_ball._on_body_entered(paddle)
	assert_eq(paddle.hit_count, 1, "contacts register once dragging clears")
