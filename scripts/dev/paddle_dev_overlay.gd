class_name PaddleDevOverlay
extends Node

const STATE_LABEL_GAP := 8.0

@export var collision: CollisionShape2D
@export var racket_hitbox: Area2D
@export var racket_shape: CollisionShape2D
@export var sprite: AnimatedSprite2D
@export var ground_ray: RayCast2D

var _body_shape: RectangleShape2D
var _racket_shape: RectangleShape2D

@onready var _collider_overlay: ColliderOverlay = $ColliderOverlay
@onready var _state_label: Label = $StateLabel


func _ready() -> void:
	if not OS.is_debug_build():
		queue_free()
		return

	if collision != null and collision.shape is RectangleShape2D:
		_body_shape = collision.shape
	if racket_shape != null and racket_shape.shape is RectangleShape2D:
		_racket_shape = racket_shape.shape

	sprite.animation_changed.connect(_refresh_state_label)
	_refresh_state_label()


func _physics_process(_delta: float) -> void:
	_refresh_overlay_shapes()
	_collider_overlay.tick_ray_draw()


func set_state_label_visible(value: bool) -> void:
	if _state_label != null:
		_state_label.visible = value


func _position_state_label() -> void:
	var half_height: float = STATE_LABEL_GAP
	if _body_shape != null:
		half_height = _body_shape.size.y * 0.5 + STATE_LABEL_GAP
	_state_label.size = Vector2.ZERO
	var min_size: Vector2 = _state_label.get_minimum_size()
	_state_label.position = Vector2(-min_size.x * 0.5, -half_height - min_size.y)


func _refresh_state_label() -> void:
	if sprite == null:
		return
	_state_label.text = String(sprite.animation)
	_position_state_label()


func set_body_collider_visible(shown: bool) -> void:
	_collider_overlay.set_body_active(shown)


func set_ground_ray_visible(shown: bool) -> void:
	_collider_overlay.set_ray_visible(shown, ground_ray)


func set_racket_collider_visible(shown: bool) -> void:
	_collider_overlay.set_racket_active(shown)


func _refresh_overlay_shapes() -> void:
	var body_size: Vector2 = _body_shape.size if _body_shape != null else Vector2.ZERO
	var body_offset: Vector2 = collision.position if collision != null else Vector2.ZERO
	var racket_size: Vector2 = _racket_shape.size if _racket_shape != null else Vector2.ZERO
	var racket_offset: Vector2 = racket_hitbox.position if racket_hitbox != null else Vector2.ZERO
	_collider_overlay.set_shapes(body_size, body_offset, racket_size, racket_offset)
