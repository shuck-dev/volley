class_name DevPaddleSizePanel
extends VBoxContainer

## Debug slider to tune paddle size and see animation frames.

var _drag: DraggableBehavior = DraggableBehavior.new()
var _slider: HSlider
var _label_value: Label
var _spinbox: SpinBox


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
	_refresh_label()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.0, 0.0, 0.0, 0.6))


func _build_ui() -> void:
	_add_header()

	_slider = HSlider.new()
	_slider.min_value = GameRules.paddle.paddle_size_min
	_slider.max_value = GameRules.paddle.paddle_size * 3.0
	_slider.value = GameRules.paddle.paddle_size
	_slider.step = 1.0
	_slider.value_changed.connect(_on_slider_changed)
	add_child(_slider)

	_label_value = Label.new()
	_label_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label_value.add_theme_color_override("font_color", Color(0.8, 1.0, 0.8))
	add_child(_label_value)
	_refresh_label()

	_spinbox = SpinBox.new()
	_spinbox.min_value = GameRules.paddle.paddle_size_min
	_spinbox.max_value = GameRules.paddle.paddle_size * 3.0
	_spinbox.value = GameRules.paddle.paddle_size
	_spinbox.step = 1.0
	_spinbox.value_changed.connect(_on_spinbox_changed)
	add_child(_spinbox)


func _add_header() -> void:
	var header := Label.new()
	header.text = "--- DEBUG: Paddle Size ---"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_color_override("font_color", Color(1.0, 1.0, 0.6))
	add_child(header)


func _refresh_label() -> void:
	if _label_value != null:
		_label_value.text = "size: %.1f px" % GameRules.paddle.paddle_size


func _on_slider_changed(value: float) -> void:
	if _spinbox != null:
		_spinbox.value = value
	_apply_size(value)


func _on_spinbox_changed(value: float) -> void:
	if _slider != null:
		_slider.value = value
	_apply_size(value)


func _apply_size(value: float) -> void:
	GameRules.paddle.paddle_size = value
	_refresh_label()
	_apply_size_to_paddles()


func _apply_size_to_paddles() -> void:
	for paddle in get_tree().get_nodes_in_group(&"paddles"):
		if paddle.has_method("_refresh_from_stats"):
			paddle._refresh_from_stats()
