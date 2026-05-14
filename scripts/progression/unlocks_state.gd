class_name UnlocksState
extends RefCounted

var shop_unlocked := false


func clear() -> void:
	shop_unlocked = false


func to_save_dict() -> Dictionary:
	return {
		"shop_unlocked": shop_unlocked,
	}


func apply_save_dict(data: Dictionary) -> void:
	shop_unlocked = bool(data.get("shop_unlocked", false))
