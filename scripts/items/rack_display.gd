class_name RackDisplay
extends Node2D

@export var displayed_role: StringName = &"ball"
@export var slot_container: Node2D

var _item_manager: Node
var _item_slot_nodes: Array[Node2D] = []
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
	_clear_item_slot_nodes()
	if _slot_markers.is_empty():
		_cache_slot_markers()
	var inactive_item_keys: Array[String] = _item_manager.get_kit_items(displayed_role)
	var marker_count := _slot_markers.size()
	for index in inactive_item_keys.size():
		var item_key: String = inactive_item_keys[index]
		var item_definition := _get_item_definition(item_key)
		if item_definition == null or item_definition.art == null:
			continue
		if marker_count == 0:
			continue
		var marker_index: int = min(index, marker_count - 1)
		var slot_node := _build_item_slot_node(
			item_definition, _slot_markers[marker_index].position
		)
		slot_container.add_child(slot_node)
		_item_slot_nodes.append(slot_node)


func get_displayed_keys() -> Array[String]:
	var keys: Array[String] = []
	for slot_node in _item_slot_nodes:
		if slot_node == null:
			continue
		var item_key: String = slot_node.get_meta(&"item_key", "")
		if item_key != "":
			keys.append(item_key)
	return keys


func _cache_slot_markers() -> void:
	_slot_markers.clear()
	if slot_container == null:
		return
	for marker_candidate in slot_container.get_children():
		if marker_candidate is Node2D and String(marker_candidate.name).begins_with("SlotMarker"):
			_slot_markers.append(marker_candidate)


func _build_item_slot_node(item_definition: ItemDefinition, slot_position: Vector2) -> Node2D:
	var slot_node := Node2D.new()
	slot_node.name = "Slot_%s" % item_definition.key
	slot_node.position = slot_position
	slot_node.set_meta(&"item_key", item_definition.key)
	var item_art_instance: Node = item_definition.art.instantiate()
	slot_node.add_child(item_art_instance)
	return slot_node


func _clear_item_slot_nodes() -> void:
	for slot_node in _item_slot_nodes:
		if slot_node != null and is_instance_valid(slot_node):
			slot_node.queue_free()
	_item_slot_nodes.clear()


func _get_item_definition(item_key: String) -> ItemDefinition:
	for item: ItemDefinition in _item_manager.items:
		if item.key == item_key:
			return item
	return null


func _on_item_level_changed(_item_key: String) -> void:
	refresh()


func _on_item_placement_changed(_item_key: String, _placement: int) -> void:
	refresh()
