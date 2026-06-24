class_name PaddleDevOverlay
extends Node2D

@export var collision: CollisionShape2D
@export var racket_hitbox: Area2D
@export var racket_shape: CollisionShape2D
@export var sprite: AnimatedSprite2D
@export var ground_ray: RayCast2D

@export var body_collider: BodyColliderOverlay
@export var racket_collider: RacketColliderOverlay
@export var ray_overlay: GroundRayOverlay
@export var state_label: AnimationStateLabel


func _ready() -> void:
	if not OS.is_debug_build():
		queue_free()
		return

	if body_collider != null:
		body_collider.collision = collision
		body_collider.queue_redraw()
	if racket_collider != null:
		racket_collider.racket_hitbox = racket_hitbox
		racket_collider.racket_shape = racket_shape
		racket_collider.queue_redraw()
	if ray_overlay != null:
		ray_overlay.ground_ray = ground_ray
		ray_overlay.queue_redraw()
	if state_label != null and sprite != null:
		state_label.sprite = sprite
		state_label.collision = collision
		sprite.animation_changed.connect(state_label._refresh)
		state_label._refresh()


func _physics_process(_delta: float) -> void:
	if ray_overlay != null:
		ray_overlay.queue_redraw()


func set_body_collider_visible(shown: bool) -> void:
	if body_collider != null:
		body_collider.visible = shown


func set_racket_collider_visible(shown: bool) -> void:
	if racket_collider != null:
		racket_collider.visible = shown


func set_ground_ray_visible(shown: bool) -> void:
	if ray_overlay != null:
		ray_overlay.visible = shown


func set_state_label_visible(shown: bool) -> void:
	if state_label != null:
		state_label.visible = shown
