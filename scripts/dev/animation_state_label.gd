class_name AnimationStateLabel
extends Label

const STATE_LABEL_GAP := 8.0

@export var sprite: AnimatedSprite2D


func _ready() -> void:
	if not OS.is_debug_build():
		queue_free()
		return

	z_index = 101
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_theme_color_override(&"font_color", Color.WHITE)
	visible = false

	if sprite != null:
		sprite.animation_changed.connect(_refresh)
		_refresh()


func _refresh() -> void:
	if sprite == null:
		return
	text = String(sprite.animation)
	var half_height: float = STATE_LABEL_GAP
	if sprite.sprite_frames != null:
		var frame := sprite.sprite_frames.get_frame_texture(sprite.animation, 0)
		if frame != null:
			half_height = frame.get_height() * sprite.scale.y * 0.5 + STATE_LABEL_GAP
	size = Vector2.ZERO
	var min_size: Vector2 = get_minimum_size()
	position = Vector2(-min_size.x * 0.5, -half_height - min_size.y)
