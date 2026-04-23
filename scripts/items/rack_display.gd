class_name RackDisplay
extends Node2D

@export var role: StringName = &"ball"
@export var slot_container: Node2D
@export var bounds: Rect2 = Rect2(0, 0, 300, 200)

var _item_manager: Node
var _slots: Array[Node2D] = []
var _slot_markers: Array[Node2D] = []


func _ready() -> void:
	if _item_manager == null:
		_item_manager = ItemManager
	_cache_slot_markers()
	_item_manager.item_level_changed.connect(_on_item_level_changed)
	_item_manager.item_placement_changed.connect(_on_item_placement_changed)
	refresh()


## Injects a non-autoload ItemManager for tests. Must be called before adding to tree.
func configure(item_manager: Node) -> void:
	_item_manager = item_manager


func refresh() -> void:
	_clear_slots()
	if _slot_markers.is_empty():
		_cache_slot_markers()
	var kit_keys: Array[String] = _item_manager.get_kit_items(role)
	var marker_count := _slot_markers.size()
	for index in kit_keys.size():
		var item_key: String = kit_keys[index]
		var definition := _get_item_definition(item_key)
		if definition == null or definition.art == null:
			continue
		if marker_count == 0:
			continue
		var marker_index: int = min(index, marker_count - 1)
		var slot := _build_slot(definition, _slot_markers[marker_index].position)
		slot_container.add_child(slot)
		_slots.append(slot)


func get_displayed_keys() -> Array[String]:
	var keys: Array[String] = []
	for slot in _slots:
		if slot == null:
			continue
		var key: String = slot.get_meta(&"item_key", "")
		if key != "":
			keys.append(key)
	return keys


func _cache_slot_markers() -> void:
	_slot_markers.clear()
	if slot_container == null:
		return
	for child in slot_container.get_children():
		if child is Node2D and String(child.name).begins_with("SlotMarker"):
			_slot_markers.append(child)


func _build_slot(definition: ItemDefinition, slot_position: Vector2) -> Node2D:
	var slot := Node2D.new()
	slot.name = "Slot_%s" % definition.key
	slot.position = slot_position
	slot.set_meta(&"item_key", definition.key)
	var art_instance: Node = definition.art.instantiate()
	slot.add_child(art_instance)
	return slot


func _clear_slots() -> void:
	for slot in _slots:
		if slot != null and is_instance_valid(slot):
			slot.queue_free()
	_slots.clear()


func _get_item_definition(item_key: String) -> ItemDefinition:
	for item: ItemDefinition in _item_manager.items:
		if item.key == item_key:
			return item
	return null


func _on_item_level_changed(_item_key: String) -> void:
	refresh()


func _on_item_placement_changed(_item_key: String, _placement: int) -> void:
	refresh()
