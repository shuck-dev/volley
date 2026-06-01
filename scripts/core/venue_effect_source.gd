class_name VenueEffectSource
extends Resource

## Built-in effect source for the venue; provides the on_consolidation soul multiplier effect.


func get_key() -> String:
	return "venue"


func get_effects_for_level(_level: int) -> Array[Effect]:
	var trigger: Trigger = load("res://scripts/items/effect/trigger.gd").new()
	trigger.type = &"on_consolidation"

	var outcome: StatUntilMissOutcome = (
		load("res://scripts/items/effect/outcomes/stat_until_miss_outcome.gd").new()
	)
	outcome.stat_key = &"soul_multiplier"
	outcome.operation = &"add"
	outcome.value = 1.0

	var effect: Effect = load("res://scripts/items/effect/effect.gd").new()
	effect.trigger = trigger
	effect.outcomes = [outcome]

	var results: Array[Effect] = [effect]
	return results
