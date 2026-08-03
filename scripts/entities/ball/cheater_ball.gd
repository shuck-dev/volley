class_name CheaterBall
extends Ball

## Particle cue fired on every wobble; authored in the inherited scene.
@export var wobble_cue: CPUParticles2D
@export var min_interval_seconds: float = 1.5
@export var max_interval_seconds: float = 4.0
@export var wobble_angle_max_degrees: float = 15.0

var _time_since_wobble := 0.0
var _wobble_interval := 0.0


func _ready() -> void:
	super._ready()
	_wobble_interval = randf_range(min_interval_seconds, max_interval_seconds)


func _physics_process(delta: float) -> void:
	if linear_velocity == Vector2.ZERO:
		return

	_advance_wobble(delta)
	super._physics_process(delta)


func _advance_wobble(delta: float) -> void:
	_time_since_wobble += delta
	if _time_since_wobble < _wobble_interval:
		return

	_time_since_wobble = 0.0
	_wobble_interval = randf_range(min_interval_seconds, max_interval_seconds)
	linear_velocity = linear_velocity.rotated(
		deg_to_rad(randf_range(-wobble_angle_max_degrees, wobble_angle_max_degrees))
	)
	_fire_wobble_cue()


func _fire_wobble_cue() -> void:
	if wobble_cue == null:
		return
	wobble_cue.restart()
	wobble_cue.emitting = true
