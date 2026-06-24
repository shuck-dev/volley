class_name DevOverlay
extends Node2D

@export var collision: CollisionShape2D
@export var racket_hitbox: Area2D
@export var racket_shape: CollisionShape2D
@export var sprite: AnimatedSprite2D
@export var ground_ray: RayCast2D

@onready var body_collider: BodyColliderOverlay = $BodyColliderOverlay
@onready var racket_collider: RacketColliderOverlay = $RacketColliderOverlay
@onready var ray_overlay: GroundRayOverlay = $GroundRayOverlay
@onready var state_label: AnimationStateLabel = $AnimationStateLabel


func _ready() -> void:
	if not OS.is_debug_build():
		queue_free()
		return

	body_collider.collision = collision
	body_collider.queue_redraw()
	racket_collider.racket_hitbox = racket_hitbox
	racket_collider.racket_shape = racket_shape
	racket_collider.queue_redraw()
	ray_overlay.ground_ray = ground_ray
	ray_overlay.queue_redraw()
	state_label.sprite = sprite
	state_label.collision = collision
	sprite.animation_changed.connect(state_label._refresh)
	state_label._refresh()


func _physics_process(_delta: float) -> void:
	ray_overlay.queue_redraw()


func set_body_collider_visible(shown: bool) -> void:
	body_collider.visible = shown


func set_racket_collider_visible(shown: bool) -> void:
	racket_collider.visible = shown


func set_ground_ray_visible(shown: bool) -> void:
	ray_overlay.visible = shown


func set_state_label_visible(shown: bool) -> void:
	state_label.visible = shown
