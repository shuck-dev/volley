class_name Stats
extends RefCounted


## Combines a typed base value with the active additive and percentage modifiers for a stat key.
## Pass `ball_manager` to read modifiers from an injected seam; defaults to the autoload.
## Pass `instance_key` (a ball's ball_key) to scope ball-owned effects to that ball only.
static func resolve(
	base: float, stat_key: StringName, ball_manager: Node = null, instance_key: String = ""
) -> float:
	var source: Node = ball_manager if ball_manager != null else BallManager
	var additive: float = source.get_modifier(stat_key, instance_key)
	var pct: float = source.get_percentage_offset(stat_key, instance_key)
	return (base + additive) * (1.0 + pct)
