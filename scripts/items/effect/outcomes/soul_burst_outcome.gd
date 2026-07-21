class_name SoulBurstOutcome
extends GameActionOutcome

## Probability (0.0–1.0) that this burst fires on consolidation.
@export var burst_chance: float = 0.5


func _init() -> void:
	action_key = &"soul_burst"
