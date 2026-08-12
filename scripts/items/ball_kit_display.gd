class_name BallKitDisplay
extends Control

signal slot_pressed(ball_key: String)

const KitSlotScene: PackedScene = preload("res://scenes/kit_slot.tscn")

@export var slot_container: HBoxContainer
@export var capacity: int = 3

var _ball_manager: BallManager
var _slots: Array[KitSlot] = []
var _hidden_key: String = ""


func _ready() -> void:
	if _ball_manager == null:
		_ball_manager = BallManager
	_ball_manager.ball_manager_state_changed.connect(_on_state_changed, CONNECT_DEFERRED)
	_build_slots()
	refresh()


func _on_state_changed() -> void:
	refresh()


func configure(ball_manager: Node) -> void:
	_ball_manager = ball_manager


func refresh() -> void:
	var kit_keys: Array[String] = _ball_manager.get_kit_items()

	for index in _slots.size():
		var slot: KitSlot = _slots[index]
		var ball_key: String = kit_keys[index] if index < kit_keys.size() else ""
		var definition: BallDefinition = _get_ball_definition(ball_key) if ball_key != "" else null
		slot.set_displayed_key(ball_key, definition)
		slot.set_icon_hidden(ball_key == _hidden_key and ball_key != "")


## Hides the held ball's icon so the player sees one item (the held body), not two.
func hide_slot_for(ball_key: String) -> void:
	_hidden_key = ball_key
	refresh()


func reveal_slot_for(ball_key: String) -> void:
	if _hidden_key != ball_key:
		return
	_hidden_key = ""
	refresh()


## Returns the slot at a screen space position.
func get_slot_at(screen_position: Vector2) -> KitSlot:
	for slot in _slots:
		if slot.get_global_rect().has_point(screen_position):
			return slot

	return null


## True when a Kit slot at `screen_position` would accept `ball_key`.
func can_accept(ball_key: String, screen_position: Vector2) -> bool:
	var slot: KitSlot = get_slot_at(screen_position)
	return slot != null and slot.can_accept(ball_key)


## Hit-tests `screen_position` and moves `ball_key` into an accepting slot there, if any.
func try_accept(ball_key: String, screen_position: Vector2) -> bool:
	var slot: KitSlot = get_slot_at(screen_position)
	if slot == null or not slot.can_accept(ball_key):
		return false
	slot.accept(ball_key)
	return true


func _build_slots() -> void:
	if slot_container == null:
		return

	for index in capacity:
		var slot: KitSlot = KitSlotScene.instantiate()
		slot.capacity = capacity
		slot.configure(_ball_manager)
		slot.pressed.connect(slot_pressed.emit)
		slot_container.add_child(slot)
		_slots.append(slot)


func _get_ball_definition(ball_key: String) -> BallDefinition:
	for item: BallDefinition in _ball_manager.items:
		if item.key == ball_key or BallKey.is_instance(item.key, ball_key):
			return item

	return null
