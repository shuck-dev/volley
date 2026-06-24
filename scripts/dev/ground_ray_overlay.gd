class_name GroundRayOverlay
extends Node2D

@export var ground_ray: RayCast2D


func _ready() -> void:
	if not OS.is_debug_build():
		queue_free()
	visible = false


func _physics_process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if ground_ray == null or not is_instance_valid(ground_ray):
		return
	var colliding: bool = ground_ray.is_colliding()
	var colour := Color.GREEN if colliding else Color.RED
	var origin := ground_ray.position
	var end := origin + Vector2(0.0, ground_ray.target_position.y)
	draw_line(origin, end, colour, 2.0)
