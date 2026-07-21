class_name CurveTowardPlayerOutcome
extends Outcome

@export var strength: float = 0.15


func apply(effect_state: EffectState, source_key: String, level: int) -> void:
	var modifier := StatModifier.new()
	modifier.source_key = source_key
	modifier.stat_key = &"curve_toward_player"
	modifier.operation = StatModifier.Operation.ADD
	modifier.value = scaled_value(strength, level)
	effect_state.add_modifier(modifier)


func describe() -> String:
	return "curve toward player %.0f%%" % [strength * 100]
