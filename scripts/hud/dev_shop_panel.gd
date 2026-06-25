extends PanelContainer

const COLUMN_COUNT := 5
const HEADERS: PackedStringArray = ["key", "level", "cost", "balance", "status"]

var _content: VBoxContainer
var _grid: GridContainer
var _cells: Dictionary = {}
var _drag := DraggableBehavior.new()


func _ready() -> void:
	if not OS.is_debug_build():
		queue_free()
		return
	mouse_filter = Control.MOUSE_FILTER_PASS
	_build_shell()
	ItemManager.soul_balance_changed.connect(
		func(_a = null, _b = null, _c = null): _rebuild.call_deferred()
	)
	ItemManager.item_level_changed.connect(
		func(_a = null, _b = null, _c = null): _rebuild.call_deferred()
	)
	_rebuild.call_deferred()


func _gui_input(event: InputEvent) -> void:
	if _drag.try_start(self, event):
		accept_event()


func _input(event: InputEvent) -> void:
	if _drag.update(self, event):
		get_viewport().set_input_as_handled()


func _process(_delta: float) -> void:
	if not visible:
		return
	_refresh()


func _build_shell() -> void:
	_content = VBoxContainer.new()
	_content.add_theme_constant_override("separation", 4)
	_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_content)

	_grid = GridContainer.new()
	_grid.columns = COLUMN_COUNT
	_grid.add_theme_constant_override("h_separation", 12)
	_grid.add_theme_constant_override("v_separation", 2)
	_grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.add_child(_grid)

	for header_text in HEADERS:
		_grid.add_child(_make_cell(header_text, Color(0.7, 0.85, 1.0)))


func _rebuild() -> void:
	var stale_keys: Array = []
	for key in _cells:
		var found := false
		for item in ItemManager.items:
			if item.key == key:
				found = true
				break
		if not found:
			stale_keys.append(key)
	for key in stale_keys:
		for cell: Label in _cells[key]:
			cell.queue_free()
		_cells.erase(key)

	for item in ItemManager.items:
		if not _cells.has(item.key):
			var row_cells: Array[Label] = []
			for _column in COLUMN_COUNT:
				var cell := _make_cell("", Color(0.85, 0.85, 0.85))
				_grid.add_child(cell)
				row_cells.append(cell)
			_cells[item.key] = row_cells
	_refresh()


func _refresh() -> void:
	for item in ItemManager.items:
		if not _cells.has(item.key):
			continue
		_set_row(_cells[item.key], _row_values(item))


func _row_values(item_def: ItemDefinition) -> PackedStringArray:
	var level: int = ItemManager.get_level(item_def.key)
	var cost: int = ItemManager.calculate_cost(item_def.key)
	var balance: int = ItemManager.get_soul_balance()
	return PackedStringArray(
		[
			item_def.key,
			"%d/%d" % [level, item_def.max_level],
			str(cost),
			str(balance),
			_status_for(item_def, level, cost, balance),
		]
	)


func _set_row(row_cells: Array, values: PackedStringArray) -> void:
	for column_index in values.size():
		if column_index < row_cells.size():
			(row_cells[column_index] as Label).text = values[column_index]


func _make_cell(text: String, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _status_for(item_def: ItemDefinition, level: int, cost: int, balance: int) -> String:
	if level >= item_def.max_level:
		return "maxed"
	if balance < cost:
		return "unaffordable"
	return "available"
