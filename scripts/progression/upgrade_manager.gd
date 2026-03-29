extends Node

const PADDLE_SPEED_KEY := "paddle_speed"
const PADDLE_SIZE_KEY := "paddle_size"
const BALL_SPEED_MIN_KEY := "ball_speed_min"

var upgrades: Array[Upgrade] = [
	preload("res://resources/upgrades/paddle_speed.tres"),
	preload("res://resources/upgrades/paddle_size.tres"),
	preload("res://resources/upgrades/ball_speed_min.tres"),
]
var _progression: ProgressionData


func _ready():
	_progression = ProgressionData.new()


## Returns total cost of [Upgrade] based on current level
func calculate_cost(upgrade_key: String) -> int:
	var upgrade := _get_upgrade(upgrade_key)
	return _calculate_cost(upgrade)


## Returns current level of [Upgrade]
func get_level(upgrade_key: String) -> int:
	assert(
		upgrades.any(func(upgrade: Upgrade) -> bool: return upgrade.effect_key == upgrade_key),
		"Unknown upgrade key: %s" % upgrade_key
	)
	return _progression.upgrade_levels.get(upgrade_key, 0)


## Purchases [Upgrade] based on cost and max level, level++
func purchase(upgrade_key: String) -> bool:
	var upgrade := _get_upgrade(upgrade_key)

	if _can_purchase(upgrade):
		_progression.friendship_point_balance -= _calculate_cost(upgrade)
		_increment_level(upgrade.effect_key)
		return true

	return false


## Returns if there are enough friendship points to puchase an [Upgrade]
func can_purchase(upgrade_key: String) -> bool:
	var upgrade := _get_upgrade(upgrade_key)
	return _can_purchase(upgrade)


## Returns total value of an [Upgrade] for its current level
func get_value(upgrade_key: String) -> float:
	var upgrade := _get_upgrade(upgrade_key)
	return upgrade.base_value + _calculate_modifier(upgrade)


func _get_upgrade(key: String) -> Upgrade:
	assert(
		upgrades.any(func(upgrade: Upgrade) -> bool: return upgrade.effect_key == key),
		"Unknown effect key: %s" % key
	)

	for upgrade: Upgrade in upgrades:
		if upgrade.effect_key == key:
			return upgrade

	return null


func _can_purchase(upgrade: Upgrade) -> bool:
	return (
		_progression.friendship_point_balance >= _calculate_cost(upgrade)
		and get_level(upgrade.effect_key) < upgrade.max_level
	)


func _calculate_cost(upgrade: Upgrade) -> int:
	return int(upgrade.base_cost * pow(upgrade.cost_scaling, get_level(upgrade.effect_key)))


func _calculate_modifier(upgrade: Upgrade) -> float:
	return upgrade.effect_per_level * get_level(upgrade.effect_key)


func _increment_level(upgrade_key: String) -> void:
	_progression.upgrade_levels[upgrade_key] = get_level(upgrade_key) + 1
