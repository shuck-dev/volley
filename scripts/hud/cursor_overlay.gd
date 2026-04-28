class_name CursorOverlay
extends Node2D

## Placeholder visual for the grab cursor state machine; replaced by SH-298 textures.

const CursorStateScript: GDScript = preload("res://scripts/items/cursor_state.gd")
const DEFAULT_PALETTE: CursorOverlayPalette = preload(
	"res://resources/hud/cursor_overlay_palette.tres"
)

## Colour cluster + ring metrics; tunable per-scene by swapping the palette resource.
@export var palette: CursorOverlayPalette = DEFAULT_PALETTE

var _state: int = CursorStateScript.State.DEFAULT


func _ready() -> void:
	if palette == null:
		palette = DEFAULT_PALETTE
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
	draw_arc(
		Vector2.ZERO,
		palette.cursor_radius_px,
		0.0,
		TAU,
		32,
		ring_color,
		palette.ring_width_px,
		true
	)
	# Centre dot reads as the press point regardless of which state is active.
	draw_circle(Vector2.ZERO, palette.ring_width_px, ring_color)


func _color_for_state(state: int) -> Color:
	match state:
		CursorStateScript.State.DRAGGING:
			return palette.color_dragging
		CursorStateScript.State.CAN_DROP:
			return palette.color_can_drop
		CursorStateScript.State.FORBIDDEN:
			return palette.color_forbidden
		_:
			return palette.color_default
