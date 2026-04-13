class_name GameActionOutcome
extends Outcome

@export var action_key: StringName


func apply(_effect_state: EffectState, _source_key: String, _level: int) -> void:
	pass


func describe() -> String:
	return str(action_key)
