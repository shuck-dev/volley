class_name VenueCamera
extends Camera2D

@export var pan_speed: float = 800.0
@export var left_anchor: Node2D
@export var right_anchor: Node2D


func _ready() -> void:
	# Clamp math assumes the camera centres its frame on position.
	assert(anchor_mode == ANCHOR_MODE_DRAG_CENTER)


func _process(delta: float) -> void:
	var direction: float = Input.get_axis(&"camera_left", &"camera_right")
	if direction != 0.0:
		global_position.x += direction * pan_speed * delta
	_clamp_to_anchors()


func _clamp_to_anchors() -> void:
	if left_anchor == null or right_anchor == null:
		return
	var half_width: float = get_viewport_rect().size.x * 0.5 / zoom.x
	var left_edge: float = left_anchor.global_position.x + half_width
	var right_edge: float = right_anchor.global_position.x - half_width
	var clamp_min: float = min(left_edge, right_edge)
	var clamp_max: float = max(left_edge, right_edge)
	global_position.x = clamp(global_position.x, clamp_min, clamp_max)
