class_name EconomyState
extends RefCounted

var friendship_point_balance := 0
var total_friendship_points_earned := 0


func clear() -> void:
	friendship_point_balance = 0
	total_friendship_points_earned = 0


func to_save_dict() -> Dictionary:
	return {
		"friendship_point_balance": friendship_point_balance,
		"total_friendship_points_earned": total_friendship_points_earned,
	}


func apply_save_dict(data: Dictionary) -> void:
	friendship_point_balance = int(data.get("friendship_point_balance", 0))
	total_friendship_points_earned = int(data.get("total_friendship_points_earned", 0))
