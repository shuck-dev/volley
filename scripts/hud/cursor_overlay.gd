class_name CursorOverlay
extends Node2D

## Placeholder visual for the grab cursor state machine; replaced by SH-298 textures.

const CursorStateScript: GDScript = preload("res://scripts/items/cursor_state.gd")

const CURSOR_RADIUS_PX: float = 18.0
const RING_WIDTH_PX: float = 3.0

const COLOR_DEFAULT: Color = Color(1.0, 1.0, 1.0, 0.0)
const COLOR_DRAGGING: Color = Color(0.85, 0.85, 0.85, 0.85)
const COLOR_CAN_DROP: Color = Color(0.45, 0.95, 0.55, 0.95)
const COLOR_FORBIDDEN: Color = Color(0.95, 0.35, 0.35, 0.95)

var _state: int = CursorStateScript.State.DEFAULT


func _ready() -> void:
	z_index = 4096
	top_level = true
	visible = false


func set_state(state: int, world_position: Vector2) -> void:
	global_position = world_position
	if state == _state:
		queue_redraw()
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
	draw_arc(Vector2.ZERO, CURSOR_RADIUS_PX, 0.0, TAU, 32, ring_color, RING_WIDTH_PX, true)
	# Centre dot reads as the press point regardless of which state is active.
	draw_circle(Vector2.ZERO, RING_WIDTH_PX, ring_color)


func _color_for_state(state: int) -> Color:
	match state:
		CursorStateScript.State.DRAGGING:
			return COLOR_DRAGGING
		CursorStateScript.State.CAN_DROP:
			return COLOR_CAN_DROP
		CursorStateScript.State.FORBIDDEN:
			return COLOR_FORBIDDEN
		_:
			return COLOR_DEFAULT
