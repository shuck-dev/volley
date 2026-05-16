extends VBoxContainer

## Dev-only readout of the kit: items currently EQUIPPED and how many slots remain.

var _list: VBoxContainer
var _cap_label: Label
var _drag := DraggableBehavior.new()


func _ready() -> void:
	if not OS.is_debug_build():
		queue_free()
		return

	mouse_filter = Control.MOUSE_FILTER_PASS
	_add_header()
	_cap_label = _make_label()
	add_child(_cap_label)
	_list = VBoxContainer.new()
	add_child(_list)
	ItemManager.item_placement_changed.connect(_refresh.unbind(2))
	ItemManager.item_level_changed.connect(_refresh.unbind(1))
	_refresh()


func _gui_input(event: InputEvent) -> void:
	if _drag.try_start(self, event):
		accept_event()


func _input(event: InputEvent) -> void:
	if _drag.update(self, event):
		get_viewport().set_input_as_handled()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.0, 0.0, 0.0, 0.6))


func _add_header() -> void:
	var header := Label.new()
	header.text = "--- DEBUG: Equipped ---"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_color_override("font_color", Color(1.0, 1.0, 0.6))
	add_child(header)
	resized.connect(queue_redraw)


func _make_label() -> Label:
	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	return label


func _refresh() -> void:
	if _list == null or _cap_label == null:
		return
	for child in _list.get_children():
		child.queue_free()

	var equipped: Array[String] = []
	for item_key: String in ItemManager.state.item_placements:
		if ItemManager.state.item_placements[item_key] == Placement.EQUIPPED:
			equipped.append(item_key)
	equipped.sort()

	var remaining: int = ItemManager.get_kit_remaining()
	var used: int = equipped.size()
	var cap: int = used + remaining
	_cap_label.text = "kit: %d / %d" % [used, cap]

	if equipped.is_empty():
		var label := _make_label()
		label.text = "(empty)"
		_list.add_child(label)
		return
	for item_key in equipped:
		var label := _make_label()
		var level: int = ItemManager.get_level(item_key)
		label.text = "%s (lv %d)" % [item_key, level]
		_list.add_child(label)
