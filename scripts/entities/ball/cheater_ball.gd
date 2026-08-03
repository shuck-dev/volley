class_name CheaterBall
extends Ball

@export var wobble_cue: CPUParticles2D
@export var min_interval_seconds: float = 1.5
@export var max_interval_seconds: float = 4.0
@export var wobble_angle_min_degrees: float = 5.0
@export var wobble_angle_max_degrees: float = 15.0

var _time_since_wobble := 0.0
var _wobble_interval := 0.0


func _ready() -> void:
	super._ready()
	_wobble_interval = randf_range(min_interval_seconds, max_interval_seconds)


func _physics_process(delta: float) -> void:
	if linear_velocity == Vector2.ZERO:
		return

	_wobble(delta)
	super._physics_process(delta)


func _wobble(delta: float) -> void:
	if play_state != PlayState.PLAY_NORMAL and play_state != PlayState.PLAY_ARC:
		return

	_time_since_wobble += delta
	if _time_since_wobble < _wobble_interval:
		return

	_time_since_wobble = 0.0
	_wobble_interval = randf_range(min_interval_seconds, max_interval_seconds)

	var wobble_angle_degrees: float = randf_range(
		wobble_angle_min_degrees, wobble_angle_max_degrees
	)

	if randf() < 0.5:
		wobble_angle_degrees = -wobble_angle_degrees

	linear_velocity = linear_velocity.rotated(deg_to_rad(wobble_angle_degrees))

	_fire_wobble_cue()


func _fire_wobble_cue() -> void:
	if wobble_cue == null:
		return

	wobble_cue.restart()
	wobble_cue.emitting = true
