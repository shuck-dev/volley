class_name RacketColliderOverlay
extends Node2D

@export var racket_hitbox: RacketHitbox


func _ready() -> void:
	if not OS.is_debug_build():
		queue_free()
	visible = false


func _physics_process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if racket_hitbox == null:
		return
	var shape: RectangleShape2D = racket_hitbox.collision.shape
	if shape == null:
		return
	draw_rect(
		Rect2(racket_hitbox.position - shape.size * 0.5, shape.size), Color(1.0, 0.4, 0.2, 0.5)
	)
