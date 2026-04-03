extends VBoxContainer

var _buttons: Dictionary = {}


func _ready() -> void:
	if not OS.is_debug_build():
		hide()
		return
	for item in ItemManager.items:
		var row := HBoxContainer.new()
		add_child(row)

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
	_refresh_buttons()
	_setup_friendship_point_controls()

	ItemManager.item_level_changed.connect(_refresh_buttons.unbind(1))
	ItemManager.friendship_point_balance_changed.connect(_refresh_buttons.unbind(1))


func _on_item_pressed(item_key: String) -> void:
	ItemManager.purchase(item_key)


func _on_remove_level_pressed(item_key: String) -> void:
	ItemManager.remove_level(item_key)


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


func _on_friendship_point_balance_booster_pressed(input: SpinBox) -> void:
	ItemManager.add_friendship_points(int(input.value))


func _on_remove_friendship_point_pressed(input: SpinBox) -> void:
	ItemManager.subtract_friendship_points(int(input.value))
