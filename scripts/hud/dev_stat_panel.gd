@tool
extends VBoxContainer

var _labels: Dictionary = {}
var _speed_label: Label
var _speed_bar: Control
var _drag := DraggableBehavior.new()


func _ready() -> void:
	_apply_background()

	if Engine.is_editor_hint():
		_build_placeholder_labels()
		return

	if not OS.is_debug_build():
		queue_free()
		return

	mouse_filter = Control.MOUSE_FILTER_PASS
	_speed_bar = get_parent().get_node_or_null("SpeedBar")
	_build_live_labels()
	_add_version_label()
	_refresh()


func _gui_input(event: InputEvent) -> void:
	if _drag.try_start(self, event):
		accept_event()


func _input(event: InputEvent) -> void:
	if _drag.update(self, event):
		get_viewport().set_input_as_handled()


func _process(_delta: float) -> void:
	if Engine.is_editor_hint() or not visible:
		return
	_refresh()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.0, 0.0, 0.0, 0.6))


func _apply_background() -> void:
	alignment = BoxContainer.ALIGNMENT_CENTER
	add_theme_constant_override("separation", 2)
	resized.connect(queue_redraw)


func _build_placeholder_labels() -> void:
	for child in get_children():
		child.queue_free()

	_add_header()
	for stat_key: StringName in GameRules.base_stats:
		var label := _make_stat_label()
		label.text = "%s: %.1f" % [stat_key, GameRules.base_stats[stat_key]]
		add_child(label)


func _build_live_labels() -> void:
	_add_header()
	_speed_label = _make_stat_label()
	_speed_label.add_theme_color_override("font_color", Color(0.6, 0.8, 1.0))
	add_child(_speed_label)
	for stat_key: StringName in GameRules.base_stats:
		var label := _make_stat_label()
		add_child(label)
		_labels[stat_key] = label


func _add_version_label() -> void:
	var label := _make_stat_label()
	label.text = _read_version()
	label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	add_child(label)


func _read_version() -> String:
	if FileAccess.file_exists("res://version.txt"):
		var file := FileAccess.open("res://version.txt", FileAccess.READ)
		if file != null:
			return file.get_as_text().strip_edges()
	if OS.has_feature("editor"):
		var output: Array = []
		if (
			OS.execute("git", ["describe", "--always", "--dirty"], output) == OK
			and output.size() > 0
		):
			return output[0].strip_edges()
	return "unknown"


func _add_header() -> void:
	var header := Label.new()
	header.text = "--- DEBUG: Stats ---"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_color_override("font_color", Color(1.0, 1.0, 0.6))
	add_child(header)


func _make_stat_label() -> Label:
	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	return label


func _refresh() -> void:
	_refresh_speed_label()
	for stat_key: StringName in _labels:
		_refresh_stat_label(stat_key)


func _refresh_speed_label() -> void:
	if _speed_label != null and _speed_bar != null:
		_speed_label.text = "ball_speed: %.1f" % _speed_bar.current_speed


func _refresh_stat_label(stat_key: StringName) -> void:
	var current_value: float = ItemManager.get_stat(stat_key)
	var base_value: float = GameRules.base_stats[stat_key]
	var label: Label = _labels[stat_key]
	if is_equal_approx(current_value, base_value):
		label.text = "%s: %.1f" % [stat_key, current_value]
		label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
		return

	var diff: float = current_value - base_value
	var sign_prefix: String = "+" if diff > 0 else ""
	label.text = _format_modified_stat(stat_key, current_value, sign_prefix, diff)
	var color := Color(1.0, 0.5, 0.5) if diff < 0 else Color(0.6, 1.0, 0.6)
	label.add_theme_color_override("font_color", color)


func _format_modified_stat(
	stat_key: StringName, current_value: float, sign_prefix: String, diff: float
) -> String:
	var text := "%s: %.1f (%s%.1f)" % [stat_key, current_value, sign_prefix, diff]
	var percentage_offset: float = ItemManager.get_percentage_offset(stat_key)
	if not is_zero_approx(percentage_offset):
		var pct_prefix: String = "+" if percentage_offset > 0 else ""
		text += " [%s%.0f%%]" % [pct_prefix, percentage_offset * 100]
	return text
