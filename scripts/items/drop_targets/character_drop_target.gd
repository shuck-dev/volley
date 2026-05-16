class_name CharacterDropTarget
extends DropTarget

## Accepts equipment-role items dropped on the main character during the equip pose; capacity gate lives in ItemManager.equip.

signal equipped_art_pressed(item_key: String)

const _EQUIPPED_ART_GROUP_PREFIX: String = "equipped_art:"
const PlacementScript: GDScript = preload("res://scripts/items/placement.gd")

var _item_manager: Node
var _drop_area: Area2D
var _timeout_controller: TimeoutController


func configure(
	item_manager: Node, drop_area: Area2D, timeout_controller: TimeoutController
) -> void:
	_item_manager = item_manager
	_drop_area = drop_area
	_timeout_controller = timeout_controller
	# Live placement transitions drive mount/unmount so rack-side teardown stays symmetric with equip.
	if (
		_item_manager != null
		and not _item_manager.item_placement_changed.is_connected(_on_item_placement_changed)
	):
		_item_manager.item_placement_changed.connect(_on_item_placement_changed)
	_hydrate_equipped_visuals()


func can_accept(item_key: String, position: Vector2, _scale_factor: float = 1.0) -> bool:
	if _drop_area == null or _item_manager == null:
		return false
	if not _is_equipment_role(item_key):
		return false
	if _item_manager.get_kit_remaining() < 1:
		return false
	if _timeout_controller == null:
		return false
	if _timeout_controller.get_state() != TimeoutController.State.AT_EQUIP_POSE:
		return false
	return _position_inside_area(position)


func accept(item_key: String, _position: Vector2, _gesture_velocity: Vector2) -> void:
	if _item_manager == null:
		return
	# equip emits equip_refused on capacity races; no-op on failure so the held token stays put.
	if not _item_manager.equip(item_key):
		return
	# Mount happens via item_placement_changed → EQUIPPED, keeping equip and unequip symmetric.


# Group lookup keeps the visual discoverable by RackDropTarget without state on either target.
static func equipped_art_group(item_key: String) -> StringName:
	return StringName(_EQUIPPED_ART_GROUP_PREFIX + item_key)


# Restores visuals for items already EQUIPPED at configure time (post-load), so save / reload re-renders gear.
func _hydrate_equipped_visuals() -> void:
	if _item_manager == null:
		return
	for key: String in _item_manager.state.item_placements.keys():
		if int(_item_manager.state.item_placements[key]) == PlacementScript.EQUIPPED:
			_mount_equipped_visual(key)


func _on_item_placement_changed(item_key: String, placement: int) -> void:
	if placement == PlacementScript.EQUIPPED:
		_mount_equipped_visual(item_key)
	else:
		_free_equipped_visual(item_key)


func _mount_equipped_visual(item_key: String) -> void:
	if not _is_equipment_role(item_key):
		return
	var definition: ItemDefinition = DropTarget.get_definition(_item_manager, item_key)
	if definition == null or definition.art == null:
		return
	if _drop_area == null or not _drop_area.is_inside_tree():
		return
	# Idempotency guard: hydrate + signal can both fire for the same item; second call must no-op.
	if not _drop_area.get_tree().get_nodes_in_group(equipped_art_group(item_key)).is_empty():
		return
	var paddle: Node = _drop_area.get_parent()
	if paddle == null:
		return
	var anchor: Node = paddle
	if not definition.anchor_node_path.is_empty():
		var resolved: Node = paddle.get_node_or_null(definition.anchor_node_path)
		if resolved != null:
			anchor = resolved
	var visual: Node = definition.art.instantiate()
	visual.add_to_group(equipped_art_group(item_key))
	anchor.add_child(visual)
	_attach_press_area(visual, definition, item_key)


# Sub-Area2D that emits equipped_art_pressed on left-click; layers off so it can't drive physics.
func _attach_press_area(visual: Node, definition: ItemDefinition, item_key: String) -> void:
	if definition.at_rest_shape == null:
		return
	if not visual is Node2D:
		return
	var press: Area2D = Area2D.new()
	press.name = "EquippedPressArea"
	# Defaults give broadphase presence + collision_layer 1, which input picking needs; mask 0 and monitoring off keep it from driving physics.
	press.collision_mask = 0
	press.monitoring = false
	press.input_pickable = true
	var collision: CollisionShape2D = CollisionShape2D.new()
	collision.shape = definition.at_rest_shape.duplicate()
	press.add_child(collision)
	visual.add_child(press)
	press.input_event.connect(_on_equipped_press_input.bind(item_key))


func _on_equipped_press_input(
	_viewport: Node, event: InputEvent, _shape_idx: int, item_key: String
) -> void:
	if not (event is InputEventMouseButton):
		return
	var mouse_button: InputEventMouseButton = event
	if mouse_button.button_index != MOUSE_BUTTON_LEFT or not mouse_button.pressed:
		return
	equipped_art_pressed.emit(item_key)


## Toggles visibility of the mounted art; used during a drag-from-character gesture so the player sees one body, not two.
func set_equipped_visual_visibility(item_key: String, visible_state: bool) -> void:
	if _drop_area == null or not _drop_area.is_inside_tree():
		return
	for visual: Node in _drop_area.get_tree().get_nodes_in_group(equipped_art_group(item_key)):
		if visual is CanvasItem:
			(visual as CanvasItem).visible = visible_state


func _free_equipped_visual(item_key: String) -> void:
	if _drop_area == null or not _drop_area.is_inside_tree():
		return
	for visual: Node in _drop_area.get_tree().get_nodes_in_group(equipped_art_group(item_key)):
		visual.queue_free()


func _is_equipment_role(item_key: String) -> bool:
	var definition: ItemDefinition = DropTarget.get_definition(_item_manager, item_key)
	if definition == null:
		return false
	return definition.role == &"equipment"


func _position_inside_area(world_position: Vector2) -> bool:
	return DropTarget.area_world_rect(_drop_area).has_point(world_position)
