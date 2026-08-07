class_name BallKitDisplay
extends Control

## Screen-anchored staging area holding a curated subset of owned balls, separate from the rack.

const KitSlotScene: PackedScene = preload("res://scenes/kit_slot.tscn")

@export var slot_container: HBoxContainer
@export var capacity: int = 3

var _ball_manager: BallManager
var _slots: Array[KitSlot] = []


func _ready() -> void:
	if _ball_manager == null:
		_ball_manager = BallManager
	_ball_manager.ball_manager_state_changed.connect(_on_state_changed, CONNECT_DEFERRED)
	_build_slots()
	refresh()


func _on_state_changed() -> void:
	refresh()


## Injects a non-autoload BallManager for tests. Must be called before adding to tree.
func configure(ball_manager: Node) -> void:
	_ball_manager = ball_manager


func refresh() -> void:
	var kit_keys: Array[String] = _ball_manager.get_kit_items()

	for index in _slots.size():
		var slot: KitSlot = _slots[index]
		var ball_key: String = kit_keys[index] if index < kit_keys.size() else ""
		var definition: BallDefinition = _get_ball_definition(ball_key) if ball_key != "" else null
		slot.set_displayed_key(ball_key, definition)


## Returns the slot whose screen-space rect contains `screen_position`, or null.
func get_slot_at(screen_position: Vector2) -> KitSlot:
	for slot in _slots:
		if slot.get_global_rect().has_point(screen_position):
			return slot
	return null


func _build_slots() -> void:
	if slot_container == null:
		return

	for index in capacity:
		var slot: KitSlot = KitSlotScene.instantiate()
		slot.capacity = capacity
		slot.configure(_ball_manager)
		slot_container.add_child(slot)
		_slots.append(slot)


func _get_ball_definition(ball_key: String) -> BallDefinition:
	for item: BallDefinition in _ball_manager.items:
		if item.key == ball_key or BallKey.is_instance(item.key, ball_key):
			return item
	return null
