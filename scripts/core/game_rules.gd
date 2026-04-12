class_name GameRules
extends RefCounted

const CONFIG: Resource = preload("res://resources/base_stats.tres")

## Read-only dictionary of base stat values loaded from base_stats.tres.
static var base_stats: Dictionary = _init_base_stats()


static func _init_base_stats() -> Dictionary:
	var stats: Dictionary = CONFIG.to_dict()
	stats.make_read_only()
	return stats
