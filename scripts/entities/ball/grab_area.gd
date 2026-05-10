class_name GrabArea
extends Area2D

signal grabbed(area: GrabArea)

@export_range(1.0, 4.0, 0.1) var hitbox_inflation: float = 2.4


func _ready() -> void:
	if not input_event.is_connected(_on_input_event):
		input_event.connect(_on_input_event)


# Duplicate the authored sub-resource so per-instance inflation does not mutate the shared shape.
func inflate_to(authored_radius: float) -> void:
	var press_shape: CollisionShape2D = _find_collision_shape()
	if press_shape == null:
		return
	var circle: CircleShape2D = press_shape.shape as CircleShape2D
	if circle == null or authored_radius <= 0.0:
		return
	var local_circle: CircleShape2D = circle.duplicate() as CircleShape2D
	local_circle.radius = authored_radius * hitbox_inflation
	press_shape.shape = local_circle


func _find_collision_shape() -> CollisionShape2D:
	for child in get_children():
		if child is CollisionShape2D:
			return child
	return null


func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if not (event is InputEventMouseButton):
		return
	var mouse_button: InputEventMouseButton = event
	if mouse_button.button_index != MOUSE_BUTTON_LEFT:
		return
	if not mouse_button.pressed:
		return
	grabbed.emit(self)
