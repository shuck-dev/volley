class_name RackDisplay
extends Node2D

## Reactive display for inactive items in a given role.
## Renders one slot per owned-but-unplaced item, using `ItemDefinition.art`.
## Declares a drop-target Area2D child for future drag-and-drop wiring (SH-97/SH-98).
## No gameplay effect while items sit here: effects are driven by placement (SH-96).

## Which role this rack displays. `&"ball"` or `&"equipment"`.
@export var role: StringName = &"ball"

## Parent node for item slots; rebuilt from scratch on every change.
@export var slot_container: Node2D

## Visible bounds the rack covers, used to size the drop-target Area2D.
@export var bounds: Rect2 = Rect2(0, 0, 300, 200)

## Per-slot spacing. Items flow left-to-right then wrap to the next row.
@export var slot_size: Vector2 = Vector2(72, 72)
@export var slot_padding: Vector2 = Vector2(16, 16)

var _item_manager: Node
var _slots: Array[Node2D] = []


func _ready() -> void:
	if _item_manager == null:
		_item_manager = ItemManager
	_item_manager.item_level_changed.connect(_on_item_level_changed)
	_item_manager.item_placement_changed.connect(_on_item_placement_changed)
	refresh()


## Injects a non-autoload ItemManager for tests. Must be called before adding to tree.
func configure(item_manager: Node) -> void:
	_item_manager = item_manager


## Rebuilds the slot children from the current inactive set. Idempotent.
func refresh() -> void:
	_clear_slots()
	var inactive_keys := _collect_inactive_keys()
	for index in inactive_keys.size():
		var item_key := inactive_keys[index]
		var definition := _get_item_definition(item_key)
		if definition == null or definition.art == null:
			continue
		var slot := _build_slot(definition, index)
		slot_container.add_child(slot)
		_slots.append(slot)


## Returns the inactive, role-matching item keys currently rendered.
## Exposed for tests and for future drop-target logic.
func get_displayed_keys() -> Array[String]:
	var keys: Array[String] = []
	for slot in _slots:
		if slot == null:
			continue
		var key: String = slot.get_meta(&"item_key", "")
		if key != "":
			keys.append(key)
	return keys


func _collect_inactive_keys() -> Array[String]:
	var keys: Array[String] = []
	for item in _item_manager.items:
		if item.role != role:
			continue
		if _item_manager.get_level(item.key) <= 0:
			continue
		# is_on_court returns true for any non-STORED placement (EQUIPPED or ON_COURT).
		if _item_manager.is_on_court(item.key):
			continue
		keys.append(item.key)
	return keys


func _build_slot(definition: ItemDefinition, index: int) -> Node2D:
	var slot := Node2D.new()
	slot.name = "Slot_%s" % definition.key
	slot.position = _slot_position(index)
	slot.set_meta(&"item_key", definition.key)
	var art_instance: Node = definition.art.instantiate()
	slot.add_child(art_instance)
	return slot


func _slot_position(index: int) -> Vector2:
	var stride := slot_size + slot_padding
	var columns: int = max(1, int(floor((bounds.size.x - slot_padding.x) / stride.x)))
	var column := index % columns
	var row := index / columns
	var origin := bounds.position + slot_padding + slot_size * 0.5
	return origin + Vector2(column * stride.x, row * stride.y)


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
