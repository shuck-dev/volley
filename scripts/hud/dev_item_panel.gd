@tool
extends VBoxContainer

var _buttons: Dictionary = {}
var _drag := DraggableBehavior.new()


func _ready() -> void:
	if Engine.is_editor_hint():
		_build_placeholder()
		return

	if not OS.is_debug_build():
		hide()
		return
	mouse_filter = Control.MOUSE_FILTER_PASS
	_add_header()
	for item in ItemManager.items:
		var container := VBoxContainer.new()
		add_child(container)

		var row := HBoxContainer.new()
		container.add_child(row)

		var buy_button := Button.new()
		buy_button.pressed.connect(_on_item_pressed.bind(item.key))
		buy_button.focus_mode = Control.FOCUS_NONE
		buy_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(buy_button)
		_buttons[item.key] = buy_button

		var remove_button := Button.new()
		remove_button.text = "-"
		remove_button.pressed.connect(_on_remove_level_pressed.bind(item.key))
		remove_button.focus_mode = Control.FOCUS_NONE
		row.add_child(remove_button)

		var effect_lines := _build_effect_lines(item)
		if effect_lines.size() > 0:
			var details := VBoxContainer.new()
			details.visible = false
			container.add_child(details)

			var toggle := Button.new()
			toggle.text = "+"
			toggle.focus_mode = Control.FOCUS_NONE
			toggle.custom_minimum_size.x = 20
			toggle.pressed.connect(_on_toggle_details.bind(toggle, details))
			row.add_child(toggle)

			for line in effect_lines:
				var label := Label.new()
				label.text = line
				label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
				details.add_child(label)

	_refresh_buttons()
	_setup_friendship_point_controls()
	_setup_clear_save_control()

	ItemManager.item_level_changed.connect(_refresh_buttons.unbind(1))
	ItemManager.friendship_point_balance_changed.connect(_refresh_buttons.unbind(1))


func _gui_input(event: InputEvent) -> void:
	if _drag.process(self, event):
		accept_event()


func _on_item_pressed(item_key: String) -> void:
	ItemManager.purchase(item_key)


func _on_remove_level_pressed(item_key: String) -> void:
	ItemManager.remove_level(item_key)


func _on_toggle_details(toggle: Button, details: VBoxContainer) -> void:
	details.visible = not details.visible
	toggle.text = "-" if details.visible else "+"


func _refresh_buttons() -> void:
	for item in ItemManager.items:
		var button: Button = _buttons[item.key]
		var level := ItemManager.get_level(item.key)
		var cost := ItemManager.calculate_cost(item.key)
		button.text = "%s Lv%d [%d FP]" % [item.display_name, level, cost]
		button.disabled = not ItemManager.can_purchase(item.key)


func _setup_friendship_point_controls() -> void:
	var row := HBoxContainer.new()
	add_child(row)

	var friendship_point_input := SpinBox.new()
	friendship_point_input.value = 100
	friendship_point_input.min_value = 1
	friendship_point_input.max_value = 10000
	friendship_point_input.step = 10
	friendship_point_input.focus_mode = Control.FOCUS_NONE
	friendship_point_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(friendship_point_input)

	var friendship_point_button := Button.new()
	friendship_point_button.text = "Add FP"
	friendship_point_button.focus_mode = Control.FOCUS_NONE
	friendship_point_button.pressed.connect(
		_on_friendship_point_balance_booster_pressed.bind(friendship_point_input)
	)
	row.add_child(friendship_point_button)

	var remove_friendship_point_button := Button.new()
	remove_friendship_point_button.text = "Remove FP"
	remove_friendship_point_button.focus_mode = Control.FOCUS_NONE
	remove_friendship_point_button.pressed.connect(
		_on_remove_friendship_point_pressed.bind(friendship_point_input)
	)
	row.add_child(remove_friendship_point_button)


func _build_effect_lines(item: ItemDefinition) -> Array[String]:
	var lines: Array[String] = []
	for effect: Effect in item.effects:
		var level_range := ""
		if effect.min_active_level > 1 or effect.max_active_level != null:
			var effective_max: Variant = effect.max_active_level
			var max_level: int = effective_max if effective_max != null else item.max_level
			level_range = " (Lv%d-%d)" % [effect.min_active_level, max_level]
		for outcome: Outcome in effect.outcomes:
			var line := "%s %s" % [effect.trigger.type, outcome.describe()]
			if not level_range.is_empty():
				line += level_range
			lines.append(line)
	return lines


func _on_friendship_point_balance_booster_pressed(input: SpinBox) -> void:
	ItemManager.add_friendship_points(int(input.value))


func _on_remove_friendship_point_pressed(input: SpinBox) -> void:
	ItemManager.subtract_friendship_points(int(input.value))


func _setup_clear_save_control() -> void:
	var clear_save_button := Button.new()
	clear_save_button.text = "Clear Save"
	clear_save_button.focus_mode = Control.FOCUS_NONE
	clear_save_button.pressed.connect(_on_clear_save_pressed)
	add_child(clear_save_button)


func _on_clear_save_pressed() -> void:
	print("[dev] clear save button pressed")
	SaveManager.clear_save()
	ItemManager.reload_from_progression()
	get_tree().reload_current_scene()
	SaveManager.unblock_writes.call_deferred()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.0, 0.0, 0.0, 0.6))


func _add_header() -> void:
	var header := Label.new()
	header.text = "--- DEBUG: Items ---"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_color_override("font_color", Color(1.0, 1.0, 0.6))
	add_child(header)


func _build_placeholder() -> void:
	for child in get_children():
		child.queue_free()
	resized.connect(queue_redraw)
	_add_header()

	for path in _find_item_resources():
		var item: ItemDefinition = load(path)
		if item == null:
			continue
		var label := Label.new()
		label.text = "%s Lv0 [%d FP]" % [item.display_name, item.base_cost]
		label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
		add_child(label)

	var footer := Label.new()
	footer.text = "Add/Remove FP"
	footer.add_theme_color_override("font_color", Color(0.6, 0.8, 1.0))
	add_child(footer)


func _find_item_resources() -> Array[String]:
	var paths: Array[String] = []
	var directory := DirAccess.open("res://resources/items")
	if directory == null:
		return paths
	for file_name in directory.get_files():
		if file_name.ends_with(".tres"):
			paths.append("res://resources/items/%s" % file_name)
	return paths
