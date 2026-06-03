extends Node

## Minimal stand-in for ItemManager, the slice a Ball touches when no item modifiers
## are under test. Returns neutral values so the ball resolves its base stats off
## GameRules alone. Use the real ItemManager (with items) when item-modified behaviour
## is what the test asserts.


func get_modifier(_key: StringName) -> float:
	return 0.0


func get_percentage_offset(_key: StringName) -> float:
	return 0.0


func process_event(_event_type: StringName) -> Array[StringName]:
	return []
