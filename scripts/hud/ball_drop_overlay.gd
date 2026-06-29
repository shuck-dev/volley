class_name BallDropOverlay
extends Node2D

## Placeholder visual for the grab cursor state machine; replaced by SH-298 textures.

const CursorStateScript: GDScript = preload("res://scripts/items/cursor_state.gd")
const DEFAULT_STYLE: CursorStyle = preload("res://resources/hud/cursor_style.tres")

## Colour-per-state plus ring metrics; tunable per-scene by swapping the style resource.
@export var style: CursorStyle = DEFAULT_STYLE

var dev_visible: bool = true
var _state: int = CursorStateScript.State.DEFAULT


func _ready() -> void:
	if style == null:
		style = DEFAULT_STYLE
	z_index = 4096
	visible = false
	add_to_group(&"dev_overlays")
	add_to_group(&"cursor_overlay")


func set_state(state: int, world_position: Vector2) -> void:
	global_position = get_viewport().get_canvas_transform() * world_position
	if state == _state:
		return
	_state = state
	visible = dev_visible and state != CursorStateScript.State.DEFAULT
	queue_redraw()


func set_dev_visible(value: bool) -> void:
	dev_visible = value
	visible = dev_visible and _state != CursorStateScript.State.DEFAULT


func get_state() -> int:
	return _state


func _draw() -> void:
	if _state == CursorStateScript.State.DEFAULT:
		return
	var ring_color: Color = _color_for_state(_state)
	draw_arc(
		Vector2.ZERO, style.cursor_radius_px, 0.0, TAU, 32, ring_color, style.ring_width_px, true
	)
	# Centre dot reads as the press point regardless of which state is active.
	draw_circle(Vector2.ZERO, style.ring_width_px, ring_color)


func _color_for_state(state: int) -> Color:
	match state:
		CursorStateScript.State.DRAGGING:
			return style.color_dragging
		CursorStateScript.State.CAN_DROP:
			return style.color_can_drop
		CursorStateScript.State.FORBIDDEN:
			return style.color_forbidden
		_:
			return style.color_default
