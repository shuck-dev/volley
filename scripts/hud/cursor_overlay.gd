class_name CursorOverlay
extends Node2D

## Placeholder visual for the grab cursor state machine; replaced by SH-298 textures.

const CursorStateScript: GDScript = preload("res://scripts/items/cursor_state.gd")

## Ring radius for the placeholder cursor overlay; tunable per-scene.
@export var cursor_radius_px: float = 18.0
## Ring stroke width for the placeholder cursor overlay.
@export var ring_width_px: float = 3.0
## Tint per cursor state; alpha 0 hides the default state.
@export var color_default: Color = Color(1.0, 1.0, 1.0, 0.0)
@export var color_dragging: Color = Color(0.85, 0.85, 0.85, 0.85)
@export var color_can_drop: Color = Color(0.45, 0.95, 0.55, 0.95)
@export var color_forbidden: Color = Color(0.95, 0.35, 0.35, 0.95)

var _state: int = CursorStateScript.State.DEFAULT


func _ready() -> void:
	z_index = 4096
	top_level = true
	visible = false


func set_state(state: int, world_position: Vector2) -> void:
	global_position = world_position
	if state == _state:
		return
	_state = state
	visible = state != CursorStateScript.State.DEFAULT
	queue_redraw()


func get_state() -> int:
	return _state


func _draw() -> void:
	if _state == CursorStateScript.State.DEFAULT:
		return
	var ring_color: Color = _color_for_state(_state)
	draw_arc(Vector2.ZERO, cursor_radius_px, 0.0, TAU, 32, ring_color, ring_width_px, true)
	# Centre dot reads as the press point regardless of which state is active.
	draw_circle(Vector2.ZERO, ring_width_px, ring_color)


func _color_for_state(state: int) -> Color:
	match state:
		CursorStateScript.State.DRAGGING:
			return color_dragging
		CursorStateScript.State.CAN_DROP:
			return color_can_drop
		CursorStateScript.State.FORBIDDEN:
			return color_forbidden
		_:
			return color_default
