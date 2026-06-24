class_name RacketColliderOverlay
extends Node2D

@export var racket_hitbox: Area2D
@export var racket_shape: CollisionShape2D


func _ready() -> void:
	if not OS.is_debug_build():
		queue_free()


func _draw() -> void:
	if racket_shape == null:
		return
	var shape: RectangleShape2D = racket_shape.shape
	if shape == null:
		return
	var offset: Vector2 = racket_hitbox.position if racket_hitbox != null else Vector2.ZERO
	draw_rect(Rect2(offset - shape.size * 0.5, shape.size), Color(1.0, 0.4, 0.2, 0.5))
