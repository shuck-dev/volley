class_name DropTarget
extends Area2D

## Lower wins when several targets accept the same release; see ItemDragController.find_accepting_target.
@export var drop_priority: int = 0

var _world: World2D


func _ready() -> void:
	_world = get_viewport().find_world_2d()
	add_to_group(&"drop_targets")


func can_accept(_item: HeldBall, _world_position: Vector2, _screen_position: Vector2) -> bool:
	assert(false, "DropTarget.can_accept() must be overridden by subclass")
	return false


## Returns true when the target actually took the item, so a refusal leaves it on the cursor.
func accept(_item: HeldBall, _world_position: Vector2, _gesture_velocity: Vector2) -> bool:
	assert(false, "DropTarget.accept() must be overridden by subclass")
	return false


## A target with no rectangular collider contains nothing, so it accepts nothing.
func contains_point(world_position: Vector2) -> bool:
	var collision_shape: CollisionShape2D = _get_collision_shape()

	if collision_shape == null:
		return false

	var rectangle: RectangleShape2D = collision_shape.shape as RectangleShape2D

	if rectangle == null:
		return false

	return rectangle.get_rect().has_point(collision_shape.to_local(world_position))


## A physical placement check: true when `collision_shape` at `world_position` overlaps nothing.
## Targets that accept anywhere inside their rect without a real placement don't call this.
func _projection_clear(world_position: Vector2, collision_shape: Shape2D) -> bool:
	if _world == null:
		return true
	var space: PhysicsDirectSpaceState2D = _world.direct_space_state
	if space == null:
		return true
	if collision_shape == null:
		return true
	var params: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	params.shape = collision_shape
	params.transform = Transform2D(0.0, world_position)
	params.collide_with_bodies = true
	params.collide_with_areas = false

	# A body freed earlier this frame is still in the space, so a drop must not collide with it.
	for hit: Dictionary in space.intersect_shape(params, 8):
		var collider: Node = hit.get("collider") as Node
		if collider != null and not collider.is_queued_for_deletion():
			return false
	return true


func _get_collision_shape() -> CollisionShape2D:
	for child in get_children():
		if child is CollisionShape2D:
			return child as CollisionShape2D
	return null
