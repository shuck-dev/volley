class_name CursorOverlayPalette
extends Resource

## Tunable colour cluster + ring metrics for the placeholder grab-cursor overlay; replaced by SH-298 textures.

@export var color_default: Color = Color(1.0, 1.0, 1.0, 0.0)
@export var color_dragging: Color = Color(0.85, 0.85, 0.85, 0.85)
@export var color_can_drop: Color = Color(0.45, 0.95, 0.55, 0.95)
@export var color_forbidden: Color = Color(0.95, 0.35, 0.35, 0.95)
@export_range(1.0, 64.0, 1.0) var cursor_radius_px: float = 18.0
@export_range(0.5, 16.0, 0.5) var ring_width_px: float = 3.0
