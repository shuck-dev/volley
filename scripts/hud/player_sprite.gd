class_name PlayerSprite
extends VBoxContainer

## Dev panel to tune player paddle sprite dimensions live.

var _drag: DraggableBehavior = DraggableBehavior.new()
var _height_slider: HSlider
var _height_spinbox: SpinBox
var _width_slider: HSlider
var _width_spinbox: SpinBox
var _readout_label: Label
var _collider_visibility_checkbox: CheckBox

var _width_scale: float = 1.0


func _ready() -> void:
	if not OS.is_debug_build():
		queue_free()
		return

	mouse_filter = Control.MOUSE_FILTER_PASS
	add_theme_constant_override("separation", 2)
	resized.connect(queue_redraw)
	_build_ui()


func _gui_input(event: InputEvent) -> void:
	if _drag.try_start(self, event):
		accept_event()


func _input(event: InputEvent) -> void:
	if _drag.update(self, event):
		get_viewport().set_input_as_handled()


func _process(_delta: float) -> void:
	if not visible:
		return
	_refresh_readout()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.0, 0.0, 0.0, 0.6))


func _build_ui() -> void:
	_add_header()

	_add_height_controls()
	_add_width_controls()

	_add_collider_visibility_checkbox()

	_readout_label = Label.new()
	_readout_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_readout_label.add_theme_color_override("font_color", Color(0.8, 1.0, 0.8))
	add_child(_readout_label)
	_refresh_readout()


func _add_header() -> void:
	var header := Label.new()
	header.text = "--- DEBUG: Player Sprite ---"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_color_override("font_color", Color(1.0, 1.0, 0.6))
	add_child(header)


func _add_height_controls() -> void:
	var height_label := Label.new()
	height_label.text = "Height:"
	height_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	add_child(height_label)

	_height_slider = HSlider.new()
	_height_slider.min_value = GameRules.paddle.paddle_size_min
	_height_slider.max_value = GameRules.paddle.paddle_size * 3.0
	_height_slider.value = GameRules.paddle.paddle_size
	_height_slider.step = 1.0
	_height_slider.value_changed.connect(_on_height_slider_changed)
	add_child(_height_slider)

	_height_spinbox = SpinBox.new()
	_height_spinbox.min_value = GameRules.paddle.paddle_size_min
	_height_spinbox.max_value = GameRules.paddle.paddle_size * 3.0
	_height_spinbox.value = GameRules.paddle.paddle_size
	_height_spinbox.step = 1.0
	_height_spinbox.value_changed.connect(_on_height_spinbox_changed)
	add_child(_height_spinbox)


func _add_width_controls() -> void:
	var width_label := Label.new()
	width_label.text = "Width:"
	width_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	add_child(width_label)

	_width_slider = HSlider.new()
	_width_slider.min_value = 0.5
	_width_slider.max_value = 2.0
	_width_slider.value = 1.0
	_width_slider.step = 0.05
	_width_slider.value_changed.connect(_on_width_slider_changed)
	add_child(_width_slider)

	_width_spinbox = SpinBox.new()
	_width_spinbox.min_value = 0.5
	_width_spinbox.max_value = 2.0
	_width_spinbox.value = 1.0
	_width_spinbox.step = 0.05
	_width_spinbox.value_changed.connect(_on_width_spinbox_changed)
	add_child(_width_spinbox)


func _add_collider_visibility_checkbox() -> void:
	_collider_visibility_checkbox = CheckBox.new()
	_collider_visibility_checkbox.text = "Show Collider"
	_collider_visibility_checkbox.button_pressed = false
	_collider_visibility_checkbox.toggled.connect(_on_collider_visibility_toggled)
	add_child(_collider_visibility_checkbox)


func _refresh_readout() -> void:
	if _readout_label == null:
		return
	var height: float = GameRules.paddle.paddle_size
	var width_px: float = _calculate_width_px(height)
	_readout_label.text = "%.0f x %.0f px" % [width_px, height]


func _calculate_width_px(height: float) -> float:
	if height <= 0.0:
		return 0.0
	return height * _width_scale


func _on_height_slider_changed(value: float) -> void:
	if _height_spinbox != null:
		_height_spinbox.value = value
	_apply_height(value)


func _on_height_spinbox_changed(value: float) -> void:
	if _height_slider != null:
		_height_slider.value = value
	_apply_height(value)


func _on_width_slider_changed(value: float) -> void:
	if _width_spinbox != null:
		_width_spinbox.value = value
	_apply_width(value)


func _on_width_spinbox_changed(value: float) -> void:
	if _width_slider != null:
		_width_slider.value = value
	_apply_width(value)


func _on_collider_visibility_toggled(pressed: bool) -> void:
	_set_collider_visibility(pressed)


func _apply_height(value: float) -> void:
	GameRules.paddle.paddle_size = value
	_refresh_readout()
	_apply_to_paddles()


func _apply_width(value: float) -> void:
	_width_scale = value
	_refresh_readout()
	_apply_to_paddles()


func _set_collider_visibility(visible: bool) -> void:
	for paddle in get_tree().get_nodes_in_group(&"paddles"):
		if paddle.has_method("set_collider_visible"):
			paddle.set_collider_visible(visible)


func _apply_to_paddles() -> void:
	for paddle in get_tree().get_nodes_in_group(&"paddles"):
		if paddle.has_method("_refresh_from_stats"):
			paddle._refresh_from_stats()
		if paddle.has_method("set_sprite_width_scale"):
			paddle.set_sprite_width_scale(_width_scale)
