class_name ProgressionData
extends RefCounted

var friendship_point_balance := 0
var upgrade_levels: Dictionary[String, int]
var personal_volley_best := 0


func save() -> bool:
	return true


func load() -> bool:
	return true


func to_dict() -> Dictionary:
	return {
		"friendship_point_balance": friendship_point_balance,
		"upgrade_levels": upgrade_levels,
		"personal_volley_best": personal_volley_best
	}


static func from_dict(data: Dictionary) -> ProgressionData:
	var progression := ProgressionData.new()
	progression.friendship_point_balance = data.get("friendship_point_balance", 0)
	progression.upgrade_levels = _to_typed_dict(data.get("upgrade_levels", {}))
	progression.personal_volley_best = data.get("personal_volley_best", 0)

	return progression


static func _to_typed_dict(raw: Dictionary) -> Dictionary[String, int]:
	var typed: Dictionary[String, int] = {}
	for key: String in raw:
		typed[key] = int(raw[key])

	return typed
