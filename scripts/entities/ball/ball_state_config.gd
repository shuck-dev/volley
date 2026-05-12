## Per-PlayState physics+collision bundle; ordering-sensitive steps stay imperative around apply().
class_name BallStateConfig
extends Resource

@export var freeze: bool = false
@export var collision_layer: int = 1
@export var collision_mask: int = 1
@export var gravity_scale: float = 0.0
@export var linear_damp: float = 0.0
@export var physics_material_override: PhysicsMaterial


func apply(body: RigidBody2D) -> void:
	body.freeze = freeze
	body.collision_layer = collision_layer
	body.collision_mask = collision_mask
	body.gravity_scale = gravity_scale
	body.linear_damp = linear_damp
	body.physics_material_override = physics_material_override
