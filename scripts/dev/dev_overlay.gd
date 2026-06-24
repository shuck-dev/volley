class_name DevOverlay
extends Node2D

@onready var body_collider: BodyColliderOverlay = $BodyColliderOverlay
@onready var racket_collider: RacketColliderOverlay = $RacketColliderOverlay
@onready var ray_overlay: GroundRayOverlay = $GroundRayOverlay
@onready var state_label: AnimationStateLabel = $AnimationStateLabel


func _ready() -> void:
	if not OS.is_debug_build():
		queue_free()


func set_body_collider_visible(shown: bool) -> void:
	body_collider.visible = shown


func set_racket_collider_visible(shown: bool) -> void:
	racket_collider.visible = shown


func set_ground_ray_visible(shown: bool) -> void:
	ray_overlay.visible = shown


func set_state_label_visible(shown: bool) -> void:
	state_label.visible = shown
