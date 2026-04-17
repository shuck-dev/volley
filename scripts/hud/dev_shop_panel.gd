extends PanelContainer

## Debug overlay: live per-ShopItem state rendered as a proper grid table.
## Draggable; visible only in debug builds.

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
		hide()
		return
	_items_anchor = get_node_or_null(items_anchor_path)
	mouse_filter = Control.MOUSE_FILTER_PASS
	_build_shell()
	_rebuild_rows.call_deferred()


func _gui_input(event: InputEvent) -> void:
	if _drag.process(self, event):
		accept_event()


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
	if shop_item.is_taken():
		return "taken"
	if shop_item.can_be_taken():
		return "dragable"
	var definition: ItemDefinition = shop_item.item_definition
	if definition != null and ItemManager.get_level(definition.key) >= definition.max_level:
		return "maxed"
	if ItemManager.get_friendship_point_balance() < ItemManager.calculate_cost(definition.key):
		return "unaffordable"
	return "locked"
