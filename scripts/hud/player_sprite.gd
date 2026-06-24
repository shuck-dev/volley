class_name PlayerSprite
extends VBoxContainer

## Dev panel to tune the player paddle's raster dimensions live, and show the colliders.

const MAX_TUNE := 100000.0
const MIN_SIZE := 0.01

var _drag: DraggableBehavior = DraggableBehavior.new()
var _readout_label: Label

var _racket_width: float = 24.0
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
	_add_label("--- DEBUG: Player Sprite ---", Color(1.0, 1.0, 0.6))

	_add_control("Racket Width", 1.0, _racket_width, _apply_racket_width, MIN_SIZE)
	_add_control("Racket Height", 1.0, _racket_height, _apply_racket_height, MIN_SIZE)

	_add_checkbox("Show Body Collider", _apply_body_visible)
	_add_checkbox("Show Racket Collider", _apply_racket_visible)
	_add_checkbox("Show State Label", _apply_state_label_visible)
	_add_checkbox("Show Ground Ray", _apply_ground_ray_visible)

	_readout_label = Label.new()
	_readout_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_readout_label.add_theme_color_override("font_color", Color(0.8, 1.0, 0.8))
	add_child(_readout_label)
	_refresh_readout()


func _add_label(text: String, colour: Color) -> void:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", colour)
	add_child(label)


func _add_control(
	label_text: String, step: float, start: float, apply: Callable, min_value: float
) -> void:
	var label := Label.new()
	label.text = label_text + ":"
	label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	add_child(label)

	var spinbox := SpinBox.new()
	spinbox.min_value = min_value
	spinbox.max_value = MAX_TUNE
	spinbox.step = step
	spinbox.value = start
	spinbox.focus_mode = Control.FOCUS_NONE
	spinbox.get_line_edit().focus_mode = Control.FOCUS_NONE
	spinbox.value_changed.connect(apply)
	add_child(spinbox)


func _add_checkbox(text: String, apply: Callable) -> void:
	var checkbox := CheckBox.new()
	checkbox.text = text
	checkbox.button_pressed = false
	checkbox.focus_mode = Control.FOCUS_NONE
	checkbox.toggled.connect(apply)
	add_child(checkbox)


func _refresh_readout() -> void:
	if _readout_label == null:
		return
	_readout_label.text = "%.0f x %.0f px" % [_get_sprite_width(), _get_sprite_height()]


func _sprite_frame_size() -> Vector2:
	for paddle in get_tree().get_nodes_in_group(&"paddles"):
		var sprite: Variant = paddle.get("sprite")
		if sprite != null and sprite is AnimatedSprite2D:
			if (
				sprite.sprite_frames != null
				and sprite.sprite_frames.get_frame_count(sprite.animation) > 0
			):
				var frame: Texture2D = sprite.sprite_frames.get_frame_texture(sprite.animation, 0)
				if frame != null:
					return Vector2(
						frame.get_width() * sprite.scale.x, frame.get_height() * sprite.scale.y
					)
	return Vector2.ZERO


func _get_sprite_width() -> float:
	return _sprite_frame_size().x


func _get_sprite_height() -> float:
	return _sprite_frame_size().y


func _apply_racket_width(value: float) -> void:
	_racket_width = value
	for paddle in get_tree().get_nodes_in_group(&"paddles"):
		if paddle.has_method("set_racket_width"):
			paddle.set_racket_width(value)


func _apply_racket_height(value: float) -> void:
	_racket_height = value
	for paddle in get_tree().get_nodes_in_group(&"paddles"):
		if paddle.has_method("set_racket_height"):
			paddle.set_racket_height(value)


func _for_each_overlay(method: StringName, value: Variant) -> void:
	for paddle in get_tree().get_nodes_in_group(&"paddles"):
		var overlay: PaddleDevOverlay = paddle.get("dev_overlay")
		if overlay != null and overlay.has_method(method):
			overlay.call(method, value)


func _apply_body_visible(pressed: bool) -> void:
	_for_each_overlay("set_body_collider_visible", pressed)


func _apply_racket_visible(pressed: bool) -> void:
	_for_each_overlay("set_racket_collider_visible", pressed)


func _apply_state_label_visible(pressed: bool) -> void:
	_for_each_overlay("set_state_label_visible", pressed)


func _apply_ground_ray_visible(pressed: bool) -> void:
	_for_each_overlay("set_ground_ray_visible", pressed)
