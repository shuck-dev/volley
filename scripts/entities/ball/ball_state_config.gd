## Per-PlayState physics and collision config; ordering-sensitive steps stay imperative around apply().
class_name BallStateConfig
extends Resource

## True freezes the RigidBody2D in place: no physics integration, no collision response.
@export var freeze: bool = false
## Bitmask of layers the body lives on. 0 means the body is on no layer and cannot be hit.
@export var collision_layer: int = 1
## Bitmask of layers the body scans for collisions. 0 means the body sees nothing.
@export var collision_mask: int = 1
## Multiplier on world gravity for this body. 0 disables gravity; 1 applies it normally.
@export var gravity_scale: float = 0.0
## Friction / bounce profile for collisions. Null disables material-driven response.
@export var physics_material_override: PhysicsMaterial


func apply(body: RigidBody2D) -> void:
	body.freeze = freeze
	body.collision_layer = collision_layer
	body.collision_mask = collision_mask
	body.gravity_scale = gravity_scale
	body.physics_material_override = physics_material_override
