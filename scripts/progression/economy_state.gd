class_name EconomyState
extends RefCounted

var soul_balance := 0
var total_soul_earned := 0


func clear() -> void:
	soul_balance = 0
	total_soul_earned = 0


func to_save_dict() -> Dictionary:
	return {
		"soul_balance": soul_balance,
		"total_soul_earned": total_soul_earned,
	}


func apply_save_dict(data: Dictionary) -> void:
	soul_balance = int(data.get("soul_balance", 0))
	total_soul_earned = int(data.get("total_soul_earned", 0))
