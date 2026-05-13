class_name GameRules
extends RefCounted

const BASE_CONFIG: BaseStatsConfig = preload("res://resources/base_stats.tres")
const PADDLE_CONFIG: PaddleConfig = preload("res://resources/paddle_stats.tres")

## Read-only dictionary of base stat values merged from base_stats.tres and paddle_stats.tres.
static var base_stats: Dictionary = _init_base_stats()
## Paddle-specific config resource; use for direct typed reads when a dictionary lookup is not needed.
static var paddle: PaddleConfig = PADDLE_CONFIG


static func _init_base_stats() -> Dictionary:
	var stats: Dictionary = BASE_CONFIG.to_dict()
	stats.merge(PADDLE_CONFIG.to_dict())
	stats.make_read_only()
	return stats
