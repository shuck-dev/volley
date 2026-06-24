class_name PlayerSprite
extends VBoxContainer

## Dev panel to tune the player paddle's sprite and racket dimensions live, and show the colliders.

## Spinbox ceiling, high enough to be no practical limit on a typed or drag-scrubbed value.
const MAX_TUNE := 100000.0
## Size floor: a RectangleShape2D or sprite scale cannot be zero or negative.
const MIN_SIZE := 0.01

var _drag: DraggableBehavior = DraggableBehavior.new()
var _readout_label: Label

var _sprite_height_scale: float = 1.0
var _sprite_width_scale: float = 1.0
var _racket_position_x: float = 0.0
var _racket_position_y: float = -10.0
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

	# Sizes floor at MIN_SIZE (a RectangleShape2D/scale cannot be negative); positions may go negative.
	_add_control("Sprite Height", 0.05, _sprite_height_scale, _apply_sprite_height, MIN_SIZE)
	_add_control("Sprite Width", 0.05, _sprite_width_scale, _apply_sprite_width, MIN_SIZE)
	_add_control("Racket X", 1.0, _racket_position_x, _apply_racket_position_x, -MAX_TUNE)
	_add_control("Racket Y", 1.0, _racket_position_y, _apply_racket_position_y, -MAX_TUNE)
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


# Builds a labelled SpinBox that calls apply(value) on change. SpinBox is the native drag-to-scrub
# control: drag the arrows up or down to scrub, or type an exact value. Uncapped, no slider track.
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


func _apply_sprite_height(value: float) -> void:
	_sprite_height_scale = value
	_refresh_readout()
	_for_each_paddle("set_sprite_height_scale", value)


func _apply_sprite_width(value: float) -> void:
	_sprite_width_scale = value
	_refresh_readout()
	_for_each_paddle("set_sprite_width_scale", value)


func _apply_racket_position_x(value: float) -> void:
	_racket_position_x = value
	_for_each_paddle("set_racket_position_x", value)


func _apply_racket_position_y(value: float) -> void:
	_racket_position_y = value
	_for_each_paddle("set_racket_position_y", value)


func _apply_racket_width(value: float) -> void:
	_racket_width = value
	_for_each_paddle("set_racket_width", value)


func _apply_racket_height(value: float) -> void:
	_racket_height = value
	_for_each_paddle("set_racket_height", value)


func _apply_body_visible(pressed: bool) -> void:
	_for_each_paddle("set_body_collider_visible", pressed)


func _apply_racket_visible(pressed: bool) -> void:
	_for_each_paddle("set_racket_collider_visible", pressed)


func _apply_state_label_visible(pressed: bool) -> void:
	_for_each_paddle("set_state_label_visible", pressed)


func _apply_ground_ray_visible(pressed: bool) -> void:
	_for_each_paddle("set_ground_ray_visible", pressed)


func _for_each_paddle(method: StringName, value: Variant) -> void:
	for paddle in get_tree().get_nodes_in_group(&"paddles"):
		var overlay: Node = paddle.get_node_or_null("PaddleDevOverlay")
		if overlay != null and overlay.has_method(method):
			overlay.call(method, value)
		elif paddle.has_method(method):
			paddle.call(method, value)
