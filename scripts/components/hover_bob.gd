class_name HoverBob
extends Node

@export var sprite: Node2D
@export var amplitude: float = 10.0
@export var frequency: float = 3.0

var _time: float = 0.0
var _active: bool = false


func _ready() -> void:
	if sprite == null:
		return

	if not sprite.has_signal("animation_changed"):
		return

	sprite.animation_changed.connect(_on_animation_changed)
	set_process(false)


func _on_animation_changed() -> void:
	var anim_name: StringName = sprite.get("animation")

	if anim_name == &"ready_flying":
		_active = true
		_time = 0.0
		set_process(true)
	else:
		_active = false
		set_process(false)
		sprite.position.y = 0.0


func _process(delta: float) -> void:
	if not _active:
		return

	_time += delta
	sprite.position.y = sin(_time * frequency) * amplitude
