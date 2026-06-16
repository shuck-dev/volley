class_name VenueParallax
extends Node2D

@export_group("Deep Background")
@export var deep_color: Color = Color(0.05, 0.05, 0.12)
@export_range(0.0, 1.0) var deep_scroll_x: float = 0.05
@export_range(0.0, 1.0) var deep_scroll_y: float = 0.05

@export_group("Background")
@export var bg_color: Color = Color(0.1, 0.1, 0.2)
@export_range(0.0, 1.0) var bg_scroll_x: float = 0.2
@export_range(0.0, 1.0) var bg_scroll_y: float = 0.2

@export_group("Midground")
@export var mid_color: Color = Color(0.15, 0.14, 0.26)
@export_range(0.0, 1.0) var mid_scroll_x: float = 0.5
@export_range(0.0, 1.0) var mid_scroll_y: float = 0.5


func _ready() -> void:
	_add_parallax_layer(deep_color, Vector2(deep_scroll_x, deep_scroll_y))
	_add_parallax_layer(bg_color, Vector2(bg_scroll_x, bg_scroll_y))
	_add_parallax_layer(mid_color, Vector2(mid_scroll_x, mid_scroll_y))


func _add_parallax_layer(color: Color, scroll_scale: Vector2) -> void:
	var parallax := Parallax2D.new()
	parallax.follow_viewport = true
	parallax.scroll_scale = scroll_scale
	parallax.repeat_size = Vector2(4000, 0)
	parallax.repeat_times = 4
	add_child(parallax)

	var rect := ColorRect.new()
	rect.color = color
	rect.size = Vector2(4000, 3000)
	rect.position = Vector2(-2000, -1500)
	parallax.add_child(rect)
