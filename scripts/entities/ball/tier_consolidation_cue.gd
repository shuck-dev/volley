class_name TierConsolidationCue
extends CPUParticles2D

const _STAR_TEXTURE: Texture2D = preload("res://assets/ui/tier_cue_star.svg")
const GROUP: StringName = &"tier_consolidation_cue"

## Number of star particles in the burst.
@export_range(4, 64) var particle_count: int = 16
## How long each particle lives (seconds).
@export_range(0.05, 2.0) var particle_lifetime: float = 0.35
## Initial outward speed of the particles (px/s).
@export_range(10.0, 500.0) var burst_speed: float = 80.0
## Angular spread of the burst around the full circle (degrees).
@export_range(10.0, 360.0) var burst_spread: float = 360.0
## Tint applied to all particles; alpha fades to zero over lifetime.
@export var burst_color: Color = Color(1.0, 1.0, 1.0, 1.0)


func _ready() -> void:
	add_to_group(GROUP)
	z_index = 1

	texture = _STAR_TEXTURE
	amount = particle_count
	lifetime = particle_lifetime
	one_shot = true
	emitting = true

	direction = Vector2.UP
	spread = burst_spread * 0.5
	initial_velocity_min = burst_speed
	initial_velocity_max = burst_speed
	gravity = Vector2.ZERO

	# color_ramp owns the per-particle tint and the alpha fade; a flat `color` would be ignored.
	var fade := Gradient.new()
	fade.set_color(0, burst_color)
	fade.set_color(1, Color(burst_color.r, burst_color.g, burst_color.b, 0.0))
	color_ramp = fade

	if not finished.is_connected(queue_free):
		finished.connect(queue_free)
