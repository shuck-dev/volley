extends PanelContainer

## Debug overlay: live per-ShopItem state as a grid table. Debug builds only.

const COLUMN_COUNT := 5
const HEADERS: PackedStringArray = ["key", "level", "cost", "balance", "status"]

@export var items_anchor_path: NodePath

var _items_anchor: Node2D
var _content: VBoxContainer
var _grid: GridContainer
var _cells: Dictionary[StringName, Array] = {}
var _drag := DraggableBehavior.new()


func _ready() -> void:
	if not OS.is_debug_build():
		queue_free()
		return
	_items_anchor = get_node_or_null(items_anchor_path)
	mouse_filter = Control.MOUSE_FILTER_PASS
	_build_shell()
	_rebuild_rows.call_deferred()


func _gui_input(event: InputEvent) -> void:
	if _drag.try_start(self, event):
		accept_event()


## Warns when a click lands on a ShopItem AABB but physics picking never fires on it.
func _input(event: InputEvent) -> void:
	if _drag.update(self, event):
		get_viewport().set_input_as_handled()
		return
	if not visible:
		return
	if not (event is InputEventMouseButton):
		return
	var mouse_button: InputEventMouseButton = event
	if mouse_button.button_index != MOUSE_BUTTON_LEFT or not mouse_button.pressed:
		return
	if _items_anchor == null:
		return
	var world: Vector2 = _items_anchor.get_global_mouse_position()
	var overlapped: ShopItem = _find_item_under(world)
	if overlapped == null:
		return
	var before: int = overlapped.get_last_input_frame()
	await get_tree().physics_frame
	await get_tree().physics_frame
	if overlapped.get_last_input_frame() == before:
		var message := (
			"[shop] click over %s at %s did not reach the body; input pipeline may be blocked"
			% [overlapped.name, world]
		)
		print(message)
		push_warning(message)


func _find_item_under(world: Vector2) -> ShopItem:
	for child in _items_anchor.get_children():
		if not child is ShopItem:
			continue
		var shop_item: ShopItem = child
		var pickup_area: Area2D = shop_item.pickup_area
		if pickup_area == null:
			continue
		var collision_shape: CollisionShape2D = null
		for area_child in pickup_area.get_children():
			if area_child is CollisionShape2D:
				collision_shape = area_child
				break
		if collision_shape == null or collision_shape.shape == null:
			continue
		var rectangle := collision_shape.shape as RectangleShape2D
		if rectangle == null:
			continue
		var half: Vector2 = rectangle.size * 0.5
		var xform: Transform2D = collision_shape.global_transform
		var corners := [
			xform * Vector2(-half.x, -half.y),
			xform * Vector2(half.x, -half.y),
			xform * Vector2(half.x, half.y),
			xform * Vector2(-half.x, half.y),
		]
		var min_corner: Vector2 = corners[0]
		var max_corner: Vector2 = corners[0]
		for corner: Vector2 in corners:
			min_corner = min_corner.min(corner)
			max_corner = max_corner.max(corner)
		if Rect2(min_corner, max_corner - min_corner).has_point(world):
			return shop_item
	return null


func _process(_delta: float) -> void:
	if not visible:
		return
	_refresh()


func _build_shell() -> void:
	_content = VBoxContainer.new()
	_content.add_theme_constant_override("separation", 4)
	_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_content)

	var title := Label.new()
	title.text = "--- SHOP ---"
	title.add_theme_color_override("font_color", Color(1.0, 1.0, 0.6))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.add_child(title)

	_grid = GridContainer.new()
	_grid.columns = COLUMN_COUNT
	_grid.add_theme_constant_override("h_separation", 12)
	_grid.add_theme_constant_override("v_separation", 2)
	_grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.add_child(_grid)

	for header_text in HEADERS:
		_grid.add_child(_make_cell(header_text, Color(0.7, 0.85, 1.0)))


func _rebuild_rows() -> void:
	if _items_anchor == null or not is_instance_valid(_items_anchor):
		return
	for shop_item in _items_anchor.get_children():
		if not shop_item is ShopItem:
			continue
		var key: StringName = shop_item.name
		if _cells.has(key):
			continue
		var row_cells: Array[Label] = []
		for column_index in COLUMN_COUNT:
			var cell := _make_cell("", Color(0.85, 0.85, 0.85))
			_grid.add_child(cell)
			row_cells.append(cell)
		_cells[key] = row_cells


func _refresh() -> void:
	if _cells.is_empty():
		_rebuild_rows()
	for key in _cells:
		var shop_item: ShopItem = _items_anchor.get_node_or_null(String(key))
		var row_cells: Array = _cells[key]
		if shop_item == null:
			_set_row(row_cells, [str(key), "-", "-", "-", "GONE"])
			continue
		_set_row(row_cells, _row_values(shop_item))


func _row_values(shop_item: ShopItem) -> PackedStringArray:
	var definition: ItemDefinition = shop_item.item_definition
	if definition == null or ItemManager == null:
		return PackedStringArray([str(shop_item.name), "-", "-", "-", "INIT"])
	var level: int = ItemManager.get_level(definition.key)
	var cost: int = ItemManager.calculate_cost(definition.key)
	var balance: int = ItemManager.get_friendship_point_balance()
	return PackedStringArray(
		[
			definition.key,
			"%d/%d" % [level, definition.max_level],
			str(cost),
			str(balance),
			_status_for(shop_item),
		]
	)


func _set_row(row_cells: Array, values: PackedStringArray) -> void:
	for column_index in values.size():
		(row_cells[column_index] as Label).text = values[column_index]


func _make_cell(text: String, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _status_for(shop_item: ShopItem) -> String:
	if shop_item.is_owned():
		return "owned"
	if shop_item.can_be_owned():
		return "draggable"
	var definition: ItemDefinition = shop_item.item_definition
	if definition != null and ItemManager.get_level(definition.key) >= definition.max_level:
		return "maxed"
	if ItemManager.get_friendship_point_balance() < ItemManager.calculate_cost(definition.key):
		return "unaffordable"
	return "locked"
