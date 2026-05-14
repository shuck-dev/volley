class_name RecordsState
extends RefCounted

var personal_volley_best := 0


func clear() -> void:
	personal_volley_best = 0


func to_save_dict() -> Dictionary:
	return {
		"personal_volley_best": personal_volley_best,
	}


func apply_save_dict(data: Dictionary) -> void:
	personal_volley_best = int(data.get("personal_volley_best", 0))
