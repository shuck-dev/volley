class_name PlayerSprite
extends VBoxContainer

## Dev panel to tune player paddle sprite dimensions live.

## Spinbox ceiling, high enough to be no practical limit on typed values; sliders keep a coarse range.
const MAX_TUNE := 100000.0

var _drag: DraggableBehavior = DraggableBehavior.new()
var _height_slider: HSlider
var _height_spinbox: SpinBox
var _width_slider: HSlider
var _width_spinbox: SpinBox
var _readout_label: Label
var _collider_visibility_checkbox: CheckBox
var _racket_pos_slider: HSlider
var _racket_pos_spinbox: SpinBox
var _racket_height_slider: HSlider
var _racket_height_spinbox: SpinBox

var _sprite_height_scale: float = 1.0
var _sprite_width_scale: float = 1.0
var _racket_position_y: float = -10.0
var _racket_height: float = 20.0


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
	_add_racket_controls()

	_add_collider_visibility_checkbox()

	_readout_label = Label.new()
	_readout_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_readout_label.add_theme_color_override("font_color", Color(0.8, 1.0, 0.8))
	add_child(_readout_label)
	_refresh_readout()


func _add_header() -> void:
	var header := Label.new()
	header.text = "--- DEBUG: Sprite Sizing ---"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_color_override("font_color", Color(1.0, 1.0, 0.6))
	add_child(header)


func _add_height_controls() -> void:
	var height_label := Label.new()
	height_label.text = "Height Scale:"
	height_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	add_child(height_label)

	_height_slider = HSlider.new()
	_height_slider.min_value = 0.1
	_height_slider.max_value = 5.0
	_height_slider.value = 1.0
	_height_slider.step = 0.05
	_height_slider.value_changed.connect(_on_height_slider_changed)
	add_child(_height_slider)

	_height_spinbox = SpinBox.new()
	_height_spinbox.min_value = 0.1
	_height_spinbox.max_value = MAX_TUNE
	_height_spinbox.value = 1.0
	_height_spinbox.step = 0.05
	_height_spinbox.value_changed.connect(_on_height_spinbox_changed)
	add_child(_height_spinbox)


func _add_width_controls() -> void:
	var width_label := Label.new()
	width_label.text = "Width Scale:"
	width_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	add_child(width_label)

	_width_slider = HSlider.new()
	_width_slider.min_value = 0.1
	_width_slider.max_value = 5.0
	_width_slider.value = 1.0
	_width_slider.step = 0.05
	_width_slider.value_changed.connect(_on_width_slider_changed)
	add_child(_width_slider)

	_width_spinbox = SpinBox.new()
	_width_spinbox.min_value = 0.1
	_width_spinbox.max_value = MAX_TUNE
	_width_spinbox.value = 1.0
	_width_spinbox.step = 0.05
	_width_spinbox.value_changed.connect(_on_width_spinbox_changed)
	add_child(_width_spinbox)


func _add_racket_controls() -> void:
	var pos_label := Label.new()
	pos_label.text = "Racket Y:"
	pos_label.add_theme_color_override("font_color", Color(1.0, 0.7, 0.6))
	add_child(pos_label)

	_racket_pos_slider = HSlider.new()
	_racket_pos_slider.min_value = -100.0
	_racket_pos_slider.max_value = 100.0
	_racket_pos_slider.value = _racket_position_y
	_racket_pos_slider.step = 1.0
	_racket_pos_slider.value_changed.connect(_on_racket_pos_slider_changed)
	add_child(_racket_pos_slider)

	_racket_pos_spinbox = SpinBox.new()
	_racket_pos_spinbox.min_value = -MAX_TUNE
	_racket_pos_spinbox.max_value = MAX_TUNE
	_racket_pos_spinbox.value = _racket_position_y
	_racket_pos_spinbox.step = 1.0
	_racket_pos_spinbox.value_changed.connect(_on_racket_pos_spinbox_changed)
	add_child(_racket_pos_spinbox)

	var size_label := Label.new()
	size_label.text = "Racket Height:"
	size_label.add_theme_color_override("font_color", Color(1.0, 0.7, 0.6))
	add_child(size_label)

	_racket_height_slider = HSlider.new()
	_racket_height_slider.min_value = 2.0
	_racket_height_slider.max_value = 120.0
	_racket_height_slider.value = _racket_height
	_racket_height_slider.step = 1.0
	_racket_height_slider.value_changed.connect(_on_racket_height_slider_changed)
	add_child(_racket_height_slider)

	_racket_height_spinbox = SpinBox.new()
	_racket_height_spinbox.min_value = 2.0
	_racket_height_spinbox.max_value = MAX_TUNE
	_racket_height_spinbox.value = _racket_height
	_racket_height_spinbox.step = 1.0
	_racket_height_spinbox.value_changed.connect(_on_racket_height_spinbox_changed)
	add_child(_racket_height_spinbox)


func _add_collider_visibility_checkbox() -> void:
	_collider_visibility_checkbox = CheckBox.new()
	_collider_visibility_checkbox.text = "Show Collider"
	_collider_visibility_checkbox.button_pressed = false
	_collider_visibility_checkbox.toggled.connect(_on_collider_visibility_toggled)
	add_child(_collider_visibility_checkbox)


func _refresh_readout() -> void:
	if _readout_label == null:
		return

	var width: float = _get_sprite_width()
	var height: float = _get_sprite_height()
	_readout_label.text = "%.0f x %.0f px" % [width, height]


func _get_sprite_width() -> float:
	for paddle in get_tree().get_nodes_in_group(&"paddles"):
		if paddle.has_meta("sprite") or (paddle is Node and paddle.get("sprite") != null):
			var sprite: Variant = paddle.get("sprite")
			if sprite != null and sprite is AnimatedSprite2D:
				if (
					sprite.sprite_frames != null
					and sprite.sprite_frames.get_frame_count(sprite.animation) > 0
				):
					var frame_texture: Texture2D = sprite.sprite_frames.get_frame_texture(
						sprite.animation, 0
					)
					if frame_texture != null:
						return frame_texture.get_width() * sprite.scale.x
	return 0.0


func _get_sprite_height() -> float:
	for paddle in get_tree().get_nodes_in_group(&"paddles"):
		if paddle.has_meta("sprite") or (paddle is Node and paddle.get("sprite") != null):
			var sprite: Variant = paddle.get("sprite")
			if sprite != null and sprite is AnimatedSprite2D:
				if (
					sprite.sprite_frames != null
					and sprite.sprite_frames.get_frame_count(sprite.animation) > 0
				):
					var frame_texture: Texture2D = sprite.sprite_frames.get_frame_texture(
						sprite.animation, 0
					)
					if frame_texture != null:
						return frame_texture.get_height() * sprite.scale.y
	return 0.0


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


func _on_racket_pos_slider_changed(value: float) -> void:
	if _racket_pos_spinbox != null:
		_racket_pos_spinbox.value = value
	_apply_racket_position(value)


func _on_racket_pos_spinbox_changed(value: float) -> void:
	if _racket_pos_slider != null:
		_racket_pos_slider.value = value
	_apply_racket_position(value)


func _on_racket_height_slider_changed(value: float) -> void:
	if _racket_height_spinbox != null:
		_racket_height_spinbox.value = value
	_apply_racket_height(value)


func _on_racket_height_spinbox_changed(value: float) -> void:
	if _racket_height_slider != null:
		_racket_height_slider.value = value
	_apply_racket_height(value)


func _on_collider_visibility_toggled(pressed: bool) -> void:
	_set_collider_visibility(pressed)


func _apply_height(value: float) -> void:
	_sprite_height_scale = value
	_refresh_readout()
	_apply_to_paddles()


func _apply_width(value: float) -> void:
	_sprite_width_scale = value
	_refresh_readout()
	_apply_to_paddles()


func _apply_racket_position(value: float) -> void:
	_racket_position_y = value
	for paddle in get_tree().get_nodes_in_group(&"paddles"):
		if paddle.has_method("set_racket_position_y"):
			paddle.set_racket_position_y(value)


func _apply_racket_height(value: float) -> void:
	_racket_height = value
	for paddle in get_tree().get_nodes_in_group(&"paddles"):
		if paddle.has_method("set_racket_height"):
			paddle.set_racket_height(value)


func _set_collider_visibility(visible: bool) -> void:
	for paddle in get_tree().get_nodes_in_group(&"paddles"):
		if paddle.has_method("set_collider_visible"):
			paddle.set_collider_visible(visible)


func _apply_to_paddles() -> void:
	for paddle in get_tree().get_nodes_in_group(&"paddles"):
		if paddle.has_method("set_sprite_height_scale"):
			paddle.set_sprite_height_scale(_sprite_height_scale)
		if paddle.has_method("set_sprite_width_scale"):
			paddle.set_sprite_width_scale(_sprite_width_scale)
