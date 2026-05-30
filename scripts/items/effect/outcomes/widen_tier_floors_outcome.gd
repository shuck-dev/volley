class_name WidenTierFloorsOutcome
extends Outcome

## Lift applied to the floor of every tier above Tier 0, as a fraction of the world max; bands start higher, climbs shorten, ceilings hold.
@export var lift_fraction := 0.0


func apply(effect_state: EffectState, source_key: String, level: int) -> void:
	var modifier := StatModifier.new()
	modifier.source_key = source_key
	modifier.stat_key = &"tier_floor_lift"
	modifier.operation = StatModifier.Operation.ADD
	modifier.value = scaled_value(lift_fraction, level)
	effect_state.add_modifier(modifier)


func describe() -> String:
	var positive_prefix := "+" if lift_fraction > 0 else ""

	return "%s%.0f%% tier floors" % [positive_prefix, lift_fraction * 100]
