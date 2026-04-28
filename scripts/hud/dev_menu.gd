extends PanelContainer

## Floating dev menu: checkbox per managed overlay. Debug builds only.

@export var managed_panels: Array[NodePath] = []

var _content: VBoxContainer
var _drag := DraggableBehavior.new()


func _ready() -> void:
	if not OS.is_debug_build():
		queue_free()
		return
	mouse_filter = Control.MOUSE_FILTER_PASS
	_content = VBoxContainer.new()
	_content.add_theme_constant_override("separation", 2)
	_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_content)
	var header := Label.new()
	header.text = "--- DEV ---"
	header.add_theme_color_override("font_color", Color(1.0, 1.0, 0.6))
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.add_child(header)
	for path in managed_panels:
		var panel: Control = get_node_or_null(path)
		if panel != null:
			_add_toggle(panel)


func _gui_input(event: InputEvent) -> void:
	if _drag.try_start(self, event):
		accept_event()


func _input(event: InputEvent) -> void:
	if _drag.update(self, event):
		get_viewport().set_input_as_handled()


func _add_toggle(panel: Control) -> void:
	var checkbox := CheckBox.new()
	checkbox.text = str(panel.name)
	checkbox.button_pressed = panel.visible
	checkbox.focus_mode = Control.FOCUS_NONE
	checkbox.toggled.connect(
		func(pressed: bool) -> void:
			if is_instance_valid(panel):
				panel.visible = pressed
	)
	_content.add_child(checkbox)
