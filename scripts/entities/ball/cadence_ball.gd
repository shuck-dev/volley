class_name CadenceBall
extends Ball

## Particle cue fired on every speed-mode shift; authored in the inherited scene.
@export var shift_cue: CPUParticles2D


func _setup_effect_processor() -> void:
	var cadence_processor: BallEffectProcessor = (
		load("res://scripts/entities/ball/cadence_ball_effect_processor.gd").new()
	)
	cadence_processor.name = "BallEffectProcessor"
	cadence_processor.ball = self
	cadence_processor.ball_manager = _ball_manager
	(cadence_processor as CadenceBallEffectProcessor).mode_shifted.connect(_on_mode_shifted)
	effect_processor = cadence_processor
	add_child(cadence_processor)


func _on_mode_shifted(_mode: int) -> void:
	if shift_cue == null:
		return
	shift_cue.restart()
	shift_cue.emitting = true
