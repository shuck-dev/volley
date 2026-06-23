class_name RackDisplay
extends Node2D

signal slot_pressed(item_key: String, press_position: Vector2)

const SLOT_HIT_SIZE: Vector2 = Vector2(36, 36)

@export var role: StringName = &"ball"
@export var slot_container: Node2D
## Optional. When set, the rack can source slot art from STORED Balls in the registry (step 7.1+).
@export var reconciler: BallReconciler

var _item_manager: Node
var _slots: Array[Node2D] = []
var _slot_markers: Array[Node2D] = []
var _hidden_key: String = ""


func _ready() -> void:
	if _item_manager == null:
		_item_manager = ItemManager
	_cache_slot_markers()
	_item_manager.item_manager_state_changed.connect(refresh)
	_item_manager.item_level_changed.connect(_on_item_level_changed)
	_item_manager.item_placement_changed.connect(_on_item_placement_changed)
	if not _item_manager.rack_slots_changed.is_connected(_on_rack_slots_changed):
		# Deferred: a slot mutation can fire from inside a slot's own input_event handler, and a
		# synchronous refresh would free that Area2D mid-emission. Defer to the idle frame.
		_item_manager.rack_slots_changed.connect(_on_rack_slots_changed, CONNECT_DEFERRED)
	if reconciler != null:
		reconciler.ball_spawned.connect(_on_ball_spawned)
		reconciler.ball_removed.connect(_on_ball_removed)
	refresh()


## Injects a non-autoload ItemManager for tests. Must be called before adding to tree.
func configure(item_manager: Node) -> void:
	_item_manager = item_manager


## Injects a reconciler so the rack can source STORED-ball art from the registry. Test seam.
func configure_reconciler(p_reconciler: BallReconciler) -> void:
	reconciler = p_reconciler


func refresh() -> void:
	# A stale _hidden_key (set on a grab whose reveal never fired) would rebuild this slot
	# invisible, and a hidden CanvasItem gets no Area2D input picking, so the slot is
	# unclickable. Drop the hide for any key that is not the live drag target before rebuilding.
	if _hidden_key != "" and not _is_key_being_dragged(_hidden_key):
		_hidden_key = ""
	_clear_slots()
	if _slot_markers.is_empty():
		_cache_slot_markers()
	var marker_count: int = _slot_markers.size()
	if marker_count == 0:
		return
	var kit_keys: Array[String] = _item_manager.get_kit_items(role)
	for item_key in kit_keys:
		var slot_index: int = _item_manager.get_rack_slot_index(item_key)
		if slot_index < 0:
			# Slot freed while the ball is held; it leaves the rack until restore re-claims a slot.
			continue
		if slot_index >= marker_count:
			push_error("RackDisplay.refresh: no marker for %s (slot %d)" % [item_key, slot_index])
			continue
		var definition: ItemDefinition = _get_item_definition(item_key)
		if definition == null or definition.art == null:
			continue
		var slot: Node2D = _build_slot(definition, _slot_markers[slot_index].position)
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
	# Scale the art via a holder so it matches the standard token size (SH-261).
	var art_holder: Node2D = Node2D.new()
	art_holder.name = "ArtHolder"
	art_holder.scale = definition.token_scale
	_populate_art_holder(art_holder, definition)
	slot.add_child(art_holder)
	_attach_slot_input(slot, definition.key)
	return slot


## Slot stays empty when the registry owns a Ball for this key; the Ball renders the art itself.
func _populate_art_holder(art_holder: Node2D, definition: ItemDefinition) -> void:
	if _registered_ball_for(definition.key) != null:
		art_holder.set_meta(&"source", &"ball")
		return
	art_holder.set_meta(&"source", &"definition")
	art_holder.add_child(definition.art.instantiate())


func _registered_ball_for(item_key: String) -> Ball:
	if reconciler == null:
		return null
	# A second stored ball can be left untracked by the reconciler's one-shot kit reconcile;
	# back-fill it here so every rendered stored ball-role slot is backed by a live, grabbable ball.
	if role == &"ball" and reconciler.has_method("ensure_stored_ball_for_key"):
		return reconciler.ensure_stored_ball_for_key(item_key)
	return reconciler.get_ball_for_key(item_key)


## World position of the slot for `item_key` under the rack's current ordering. Returns Vector2.ZERO if unknown.
func get_slot_position_for(item_key: String) -> Vector2:
	if slot_container == null:
		return Vector2.ZERO
	if _slot_markers.is_empty():
		_cache_slot_markers()

	var slot_index: int = _item_manager.get_rack_slot_index(item_key)
	if slot_index < 0 or slot_index >= _slot_markers.size():
		return Vector2.ZERO
	return _slot_markers[slot_index].global_position


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


## True when a drag controller currently holds `item_key` as its live drag target.
func _is_key_being_dragged(item_key: String) -> bool:
	if get_tree() == null:
		return false
	for controller: Node in get_tree().get_nodes_in_group(&"drag_controller"):
		if not (controller.has_method("is_dragging") and controller.has_method("get_held_key")):
			continue
		if controller.is_dragging() and controller.get_held_key() == item_key:
			return true
	return false


func _clear_slots() -> void:
	# free, not queue_free: remove_child already detached, so the idle-frame gap orphans the slot.
	for slot in _slots:
		if slot != null and is_instance_valid(slot):
			slot_container.remove_child(slot)
			slot.free()
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


func _on_rack_slots_changed() -> void:
	refresh()


func _on_ball_spawned(_item_key: String, _ball: Ball) -> void:
	refresh()


func _on_ball_removed(_ball: Ball) -> void:
	refresh()
