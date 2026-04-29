class_name RackDisplay
extends Node2D

signal slot_pressed(item_key: String, press_position: Vector2)

const SLOT_HIT_SIZE: Vector2 = Vector2(36, 36)

@export var role: StringName = &"ball"
@export var slot_container: Node2D

var _item_manager: Node
var _slots: Array[Node2D] = []
var _slot_markers: Array[Node2D] = []
var _hidden_key: String = ""


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
	var marker_count: int = _slot_markers.size()
	for index in kit_keys.size():
		var item_key: String = kit_keys[index]
		var definition: ItemDefinition = _get_item_definition(item_key)
		if definition == null or definition.art == null:
			continue
		if marker_count == 0:
			continue
		var marker_index: int = min(index, marker_count - 1)
		var slot: Node2D = _build_slot(definition, _slot_markers[marker_index].position)
		slot_container.add_child(slot)
		_slots.append(slot)
	_apply_slot_visibility()


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
	var slot: Node2D = Node2D.new()
	slot.name = "Slot_%s" % definition.key
	slot.position = slot_position
	slot.set_meta(&"item_key", definition.key)
	# Scale the art via a holder so it matches the canonical token size (SH-261).
	var art_holder: Node2D = Node2D.new()
	art_holder.name = "ArtHolder"
	art_holder.scale = definition.token_scale
	var art_instance: Node = definition.art.instantiate()
	art_holder.add_child(art_instance)
	slot.add_child(art_holder)
	_attach_slot_input(slot, definition.key)
	return slot


func _attach_slot_input(slot: Node2D, item_key: String) -> void:
	var area: Area2D = _build_slot_click_area()
	area.input_event.connect(_on_slot_input_event.bind(item_key))
	slot.add_child(area)


func _build_slot_click_area() -> Area2D:
	var area: Area2D = Area2D.new()
	area.name = "ClickArea"
	area.input_pickable = true

	var rectangle: RectangleShape2D = RectangleShape2D.new()
	rectangle.size = SLOT_HIT_SIZE

	var collision: CollisionShape2D = CollisionShape2D.new()
	collision.shape = rectangle
	area.add_child(collision)

	return area


func _on_slot_input_event(
	_viewport: Node, event: InputEvent, _shape_idx: int, item_key: String
) -> void:
	if not (event is InputEventMouseButton):
		return
	var mouse_button: InputEventMouseButton = event
	if mouse_button.button_index != MOUSE_BUTTON_LEFT:
		return
	if not mouse_button.pressed:
		return
	# The Area2D input_event reports the press position in world coordinates already.
	var canvas_transform: Transform2D = get_canvas_transform()
	var press_position: Vector2 = canvas_transform.affine_inverse() * mouse_button.position
	slot_pressed.emit(item_key, press_position)


## Test seam / production fallback: emits the slot_pressed signal at the supplied position.
func press_slot(item_key: String, press_position: Vector2 = Vector2.ZERO) -> void:
	slot_pressed.emit(item_key, press_position)


## Hides the slot so the player sees one item (the held body), not two; mirrors ShopItem.visible=false on grab.
func hide_slot_for(item_key: String) -> void:
	_hidden_key = item_key
	_apply_slot_visibility()


func reveal_slot_for(item_key: String) -> void:
	if _hidden_key != item_key:
		return
	_hidden_key = ""
	_apply_slot_visibility()


func _apply_slot_visibility() -> void:
	for slot in _slots:
		if slot == null or not is_instance_valid(slot):
			continue
		var key: String = slot.get_meta(&"item_key", "")
		slot.visible = key != _hidden_key


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
