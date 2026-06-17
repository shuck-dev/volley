class_name VenueParallax
extends Node2D

@export_group("Layer 01: Deep Background")
@export var deep_background_color: Color = Color(0.05, 0.05, 0.12)
@export_range(0.0, 1.0) var deep_background_scroll_x: float = 0.05
@export_range(0.0, 1.0) var deep_background_scroll_y: float = 0.05

@export_group("Layer 02: Background")
@export var background_color: Color = Color(0.1, 0.1, 0.2)
@export_range(0.0, 1.0) var background_scroll_x: float = 0.2
@export_range(0.0, 1.0) var background_scroll_y: float = 0.2

@export_group("Layer 04: Near Foreground")
@export var near_foreground_color: Color = Color(0.18, 0.16, 0.28)
@export_range(0.5, 2.0) var near_foreground_scroll_x: float = 1.3
@export_range(0.5, 2.0) var near_foreground_scroll_y: float = 1.3

@export_group("Layer 05: Foreground")
@export var foreground_color: Color = Color(0.22, 0.2, 0.32)
@export_range(0.5, 3.0) var foreground_scroll_x: float = 1.8
@export_range(0.5, 3.0) var foreground_scroll_y: float = 1.8


func _ready() -> void:
	_add_layer(deep_background_color, Vector2(deep_background_scroll_x, deep_background_scroll_y))
	_add_layer(background_color, Vector2(background_scroll_x, background_scroll_y))
	_add_layer(near_foreground_color, Vector2(near_foreground_scroll_x, near_foreground_scroll_y))
	_add_layer(foreground_color, Vector2(foreground_scroll_x, foreground_scroll_y))


func _add_layer(color: Color, scroll_scale: Vector2) -> void:
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
