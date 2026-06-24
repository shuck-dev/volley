class_name AnimationStateLabel
extends Label

const STATE_LABEL_GAP := 8.0

@export var sprite: AnimatedSprite2D
@export var collision: CollisionShape2D


func _ready() -> void:
	if not OS.is_debug_build():
		queue_free()
		return

	z_index = 101
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_theme_color_override(&"font_color", Color.WHITE)
	visible = false


func _refresh() -> void:
	if sprite == null:
		return
	text = String(sprite.animation)
	_position_label()


func _position_label() -> void:
	var half_height: float = STATE_LABEL_GAP
	if collision != null:
		var shape: RectangleShape2D = collision.shape
		if shape != null:
			half_height = shape.size.y * 0.5 + STATE_LABEL_GAP
	size = Vector2.ZERO
	var min_size: Vector2 = get_minimum_size()
	position = Vector2(-min_size.x * 0.5, -half_height - min_size.y)
