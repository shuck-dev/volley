extends VBoxContainer

var _buttons: Dictionary = {}
var _drag := DraggableBehavior.new()


func _ready() -> void:
	if not OS.is_debug_build():
		queue_free()
		return
	mouse_filter = Control.MOUSE_FILTER_PASS
	_add_header()
	for item in BallManager.items:
		var container := VBoxContainer.new()
		add_child(container)

		var row := HBoxContainer.new()
		container.add_child(row)

		var item_info := Button.new()
		item_info.focus_mode = Control.FOCUS_NONE
		item_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(item_info)
		_buttons[item.key] = item_info

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
	_setup_soul_controls()

	BallManager.item_level_changed.connect(_refresh_buttons.unbind(1))
	BallManager.soul_balance_changed.connect(_refresh_buttons.unbind(1))


func _gui_input(event: InputEvent) -> void:
	if _drag.try_start(self, event):
		accept_event()


func _input(event: InputEvent) -> void:
	if _drag.update(self, event):
		get_viewport().set_input_as_handled()


func _on_remove_level_pressed(ball_key: String) -> void:
	BallManager.remove_level(ball_key)


func _on_toggle_details(toggle: Button, details: VBoxContainer) -> void:
	details.visible = not details.visible
	toggle.text = "-" if details.visible else "+"


func _refresh_buttons() -> void:
	for item in BallManager.items:
		if not _buttons.has(item.key):
			continue
		var button: Button = _buttons[item.key]
		var level := BallManager.get_level(item.key)
		var cost := BallManager.calculate_cost(item.key)
		button.text = "%s Lv%d [%d Soul]" % [item.display_name, level, cost]


func _setup_soul_controls() -> void:
	var row := HBoxContainer.new()
	add_child(row)

	var soul_input := SpinBox.new()
	soul_input.value = 100
	soul_input.min_value = 1
	soul_input.max_value = 10000
	soul_input.step = 10
	soul_input.focus_mode = Control.FOCUS_NONE
	soul_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(soul_input)

	var add_soul_button := Button.new()
	add_soul_button.text = "Add Soul"
	add_soul_button.focus_mode = Control.FOCUS_NONE
	add_soul_button.pressed.connect(_on_add_soul_pressed.bind(soul_input))
	row.add_child(add_soul_button)

	var remove_soul_button := Button.new()
	remove_soul_button.text = "Remove Soul"
	remove_soul_button.focus_mode = Control.FOCUS_NONE
	remove_soul_button.pressed.connect(_on_remove_soul_pressed.bind(soul_input))
	row.add_child(remove_soul_button)


func _build_effect_lines(item: BallDefinition) -> Array[String]:
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


func _on_add_soul_pressed(input: SpinBox) -> void:
	BallManager.add_soul(int(input.value))


func _on_remove_soul_pressed(input: SpinBox) -> void:
	BallManager.subtract_soul(int(input.value))


func _draw() -> void:
	pass


func _add_header() -> void:
	return
