class_name Stats
extends RefCounted


## Combines a typed base value with the active additive and percentage modifiers for a stat key.
## Pass `item_manager` to read modifiers from an injected seam; defaults to the autoload.
static func resolve(base: float, stat_key: StringName, item_manager: Node = null) -> float:
	var source: Node = item_manager if item_manager != null else ItemManager
	var additive: float = source.get_modifier(stat_key)
	var pct: float = source.get_percentage_offset(stat_key)
	return (base + additive) * (1.0 + pct)
