class_name BallKit
extends Control

const KitSlotScene: PackedScene = preload("res://scenes/kit_slot.tscn")

@export var slot_container: HBoxContainer
@export var capacity: int = 3

var _ball_manager: BallManager
var _slots: Array[KitSlot] = []
var _hidden_key: String = ""


func _ready() -> void:
	if _ball_manager == null:
		_ball_manager = BallManager
	_ball_manager.state_changed.connect(_on_state_changed, CONNECT_DEFERRED)
	_build_slots()
	_refresh()


## Venue wires this: the controller is in another scene, so no editor connection can reach it.
func connect_drag_controller(controller: ItemDragController) -> void:
	controller.pickup_started.connect(_on_pickup_started)
	controller.drop_completed.connect(_on_drop_completed)
	for slot: KitSlot in _slots:
		slot.pressed.connect(controller.grab_token)


func configure(ball_manager: Node) -> void:
	_ball_manager = ball_manager


func _on_pickup_started(ball_key: String) -> void:
	_hide_slot_ball(ball_key)


func _on_drop_completed(ball_key: String, _release_position: Vector2, _over_court: bool) -> void:
	# Loose-in-venue items have no home slot to show again.
	if _ball_manager.is_loose_in_venue(ball_key):
		return
	_show_slot_ball(ball_key)


func _on_state_changed() -> void:
	_refresh()


func _refresh() -> void:
	for index in _slots.size():
		var slot: KitSlot = _slots[index]
		var ball_key: String = _ball_manager.get_ball_in_kit_slot(index)
		slot.set_displayed_key(ball_key)
		slot.set_icon_hidden(ball_key == _hidden_key and ball_key != "")


## Hides the held ball's icon so the player sees one item (the held body), not two.
func _hide_slot_ball(ball_key: String) -> void:
	_hidden_key = ball_key
	_refresh()


func _show_slot_ball(ball_key: String) -> void:
	if _hidden_key != ball_key:
		return
	_hidden_key = ""
	_refresh()


func _build_slots() -> void:
	if slot_container == null:
		return

	for index in capacity:
		var slot: KitSlot = KitSlotScene.instantiate()
		slot.slot_index = index
		slot.configure(_ball_manager)
		slot_container.add_child(slot)
		_slots.append(slot)
