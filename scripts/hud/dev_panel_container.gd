class_name DevPanelContainer
extends PanelContainer

## Tabbed dev panel dock with pop-out and collapse.

signal panel_popped_out(panel: Control)
signal panel_docked(panel: Control)

const DISPLAY_NAMES := {
	"DevItemUI": "Items",
	"DevShopPanel": "Shop",
	"DevEquippedPanel": "Eqp",
	"DevStatPanel": "Stat",
	"DevBallStatePanel": "Ball",
	"DevBouncePanel": "Bnc",
	"PlayerSprite": "Spr",
}

const TAB_MIN_WIDTH := 40

var _drag := DraggableBehavior.new()

var _panels: Array[Control] = []
var _active_panel: Control = null
var _tab_buttons: Array[Button] = []
var _pop_out_button: Button
var _toggle_button: Button
var _tab_row: HBoxContainer
var _content_area: Control
var _collapsed: bool = false


func _ready() -> void:
	if not OS.is_debug_build():
		queue_free()
		return

	mouse_filter = Control.MOUSE_FILTER_PASS

	_tab_row = find_child("TabRow", true, false) as HBoxContainer
	_content_area = find_child("ContentArea", true, false) as Control

	if _tab_row == null or _content_area == null:
		return

	_collect_panels()
	_build_tab_row()

	if _panels.size() > 0:
		_switch_tab(0)


func _gui_input(event: InputEvent) -> void:
	if _drag.try_start(self, event):
		accept_event()


func _input(event: InputEvent) -> void:
	if _drag.update(self, event):
		get_viewport().set_input_as_handled()


func _collect_panels() -> void:
	for child in _content_area.get_children():
		if child is Control and child.name != "DevMenu":
			_panels.append(child)
			child.visible = false


func _build_tab_row() -> void:
	for child in _tab_row.get_children():
		_tab_row.remove_child(child)
		child.queue_free()

	for i in _panels.size():
		var btn := Button.new()
		btn.text = DISPLAY_NAMES.get(_panels[i].name, str(_panels[i].name))
		btn.focus_mode = Control.FOCUS_NONE
		btn.toggle_mode = true
		btn.custom_minimum_size.x = TAB_MIN_WIDTH
		btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		btn.pressed.connect(_on_tab_pressed.bind(i))
		_tab_row.add_child(btn)
		_tab_buttons.append(btn)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tab_row.add_child(spacer)

	_pop_out_button = Button.new()
	_pop_out_button.text = "\u2197"
	_pop_out_button.focus_mode = Control.FOCUS_NONE
	_pop_out_button.tooltip_text = "Pop out active panel"
	_pop_out_button.custom_minimum_size = Vector2(24, 24)
	_pop_out_button.pressed.connect(_on_pop_out_pressed)
	_tab_row.add_child(_pop_out_button)

	_toggle_button = Button.new()
	_toggle_button.text = "\u2630"
	_toggle_button.focus_mode = Control.FOCUS_NONE
	_toggle_button.tooltip_text = "Collapse / expand panel container"
	_toggle_button.custom_minimum_size = Vector2(24, 24)
	_toggle_button.toggle_mode = true
	_toggle_button.pressed.connect(_on_toggle_pressed)
	_tab_row.add_child(_toggle_button)


func _on_tab_pressed(index: int) -> void:
	_switch_tab(index)


func _switch_tab(index: int) -> void:
	if index < 0 or index >= _panels.size():
		return

	for i in _tab_buttons.size():
		_tab_buttons[i].button_pressed = (i == index)

	_active_panel = _panels[index]

	for p in _panels:
		if p.get_parent() == _content_area:
			p.visible = (p == _active_panel)

	if not _collapsed:
		_fit_to_content()


func _on_pop_out_pressed() -> void:
	if _active_panel == null:
		return

	if _active_panel.get_parent() != _content_area:
		return

	var dev_hud := get_parent()
	if dev_hud == null:
		return

	_detach_panel(_active_panel, dev_hud)
	panel_popped_out.emit(_active_panel)


func _detach_panel(panel: Control, dev_hud: Node) -> void:
	_content_area.remove_child(panel)
	dev_hud.add_child(panel)

	var bg = ColorRect.new()
	bg.name = "_pop_bg"
	bg.color = Color(0.0, 0.0, 0.0, 0.7)
	bg.size = panel.size
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(bg)
	panel.move_child(bg, 0)

	var bar = HBoxContainer.new()
	bar.name = "_pop_bar"
	bar.mouse_filter = Control.MOUSE_FILTER_PASS
	bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	bar.custom_minimum_size.y = 22

	var label = Label.new()
	label.text = DISPLAY_NAMES.get(panel.name, str(panel.name))
	label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.6))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(label)

	var btn = Button.new()
	btn.name = "DockButton"
	btn.text = "\u2B07"
	btn.focus_mode = Control.FOCUS_NONE
	btn.tooltip_text = "Dock"
	btn.custom_minimum_size = Vector2(22, 22)
	btn.pressed.connect(_on_dock_pressed.bind(panel))
	bar.add_child(btn)

	panel.add_child(bar)
	panel.move_child(bar, 1)

	panel.position = Vector2(position.x - panel.size.x - 10, position.y)
	panel.anchors_preset = Control.PRESET_TOP_LEFT
	panel.visible = true


func _on_dock_pressed(panel: Control) -> void:
	if panel.get_parent() == _content_area:
		return

	_remove_dock_button(panel)
	_reattach_panel(panel)
	panel_docked.emit(panel)


func _remove_dock_button(panel: Control) -> void:
	var btn := panel.get_node_or_null("DockButton")
	if btn != null:
		btn.queue_free()


func _remove_pop_decorations(panel: Control) -> void:
	for child_name in ["_pop_bg", "_pop_bar", "DockButton"]:
		var child := panel.get_node_or_null(child_name)
		if child != null:
			child.queue_free()


func _reattach_panel(panel: Control) -> void:
	_remove_pop_decorations(panel)

	var old_parent := panel.get_parent()
	if old_parent != null:
		old_parent.remove_child(panel)
	_content_area.add_child(panel)
	panel.visible = false
	panel.position = Vector2.ZERO
	panel.anchors_preset = Control.PRESET_TOP_LEFT


func _on_toggle_pressed() -> void:
	_collapsed = _toggle_button.button_pressed

	if _collapsed:
		_collapse_container()
	else:
		_expand_container()


func _collapse_container() -> void:
	for child in _tab_row.get_children():
		if child != _toggle_button:
			child.visible = false
	_tab_row.alignment = BoxContainer.ALIGNMENT_END
	_content_area.visible = false
	custom_minimum_size.y = _toggle_button.size.y + 4


func _expand_container() -> void:
	for child in _tab_row.get_children():
		child.visible = true
	_tab_row.alignment = BoxContainer.ALIGNMENT_BEGIN
	_content_area.visible = true
	_fit_to_content()


func _fit_to_content() -> void:
	if _active_panel != null and _active_panel.get_parent() == _content_area:
		offset_bottom = offset_top + _tab_row.size.y + _active_panel.size.y + 8


func get_active_panel() -> Control:
	return _active_panel


func get_panel_by_name(name_str: String) -> Control:
	for panel in _panels:
		if panel.name == name_str:
			return panel
	return null


func switch_tab_by_name(name_str: String) -> void:
	for i in _panels.size():
		if _panels[i].name == name_str:
			_switch_tab(i)
			return
