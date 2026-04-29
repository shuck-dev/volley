class_name CursorOverlayPalette
extends Resource

## Tunable colour cluster + ring metrics for the placeholder grab-cursor overlay; replaced by SH-298 textures.

@export var color_default: Color = Color(1.0, 1.0, 1.0, 0.0)
@export var color_dragging: Color = Color(1.0, 1.0, 1.0, 1.0)
@export var color_can_drop: Color = Color(0.35, 1.0, 0.45, 1.0)
@export var color_forbidden: Color = Color(1.0, 0.25, 0.25, 1.0)
@export_range(1.0, 64.0, 1.0) var cursor_radius_px: float = 24.0
@export_range(0.5, 16.0, 0.5) var ring_width_px: float = 5.0
