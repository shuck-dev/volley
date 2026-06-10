class_name TierConsolidationCue
extends CPUParticles2D

const GROUP: StringName = &"tier_consolidation_cue"


func _ready() -> void:
	add_to_group(GROUP)
	if not finished.is_connected(queue_free):
		finished.connect(queue_free)
