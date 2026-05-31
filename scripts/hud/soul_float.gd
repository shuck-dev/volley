class_name SoulFloat
extends Label

## Spawns at an anchor, rises, fades, then frees itself.

@export var rise_distance_px: float = 60.0
@export var duration_s: float = 1.2
@export var color: Color = Color(0.8, 0.6, 1.0, 1.0)

var _elapsed: float = 0.0
var _start_y: float = 0.0


func _ready() -> void:
	modulate = color
	_start_y = position.y


func _process(delta: float) -> void:
	_elapsed += delta

	var t: float = clampf(_elapsed / duration_s, 0.0, 1.0)

	position.y = _start_y - rise_distance_px * t
	modulate.a = 1.0 - t

	if t >= 1.0:
		queue_free()
