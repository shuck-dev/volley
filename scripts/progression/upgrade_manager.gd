extends Node

signal friendship_point_balance_changed(balance: int)
signal upgrade_level_changed(upgrade_key: String)

const PADDLE_SPEED_KEY := "paddle_speed"
const PADDLE_SIZE_KEY := "paddle_size"
const BALL_SPEED_MIN_KEY := "ball_speed_min"
const BALL_SPEED_MAX_KEY := "ball_speed_max"

var upgrades: Array[Upgrade] = [
	preload("res://resources/upgrades/paddle_speed.tres"),
	preload("res://resources/upgrades/paddle_size.tres"),
	preload("res://resources/upgrades/ball_speed_min.tres"),
	preload("res://resources/upgrades/ball_speed_max.tres"),
]

var _progression: ProgressionData


func _ready() -> void:
	if _progression == null:
		_progression = SaveManager.get_progression_data()


## Returns total cost of [Upgrade] based on current level
func calculate_cost(upgrade_key: String) -> int:
	var upgrade := _get_upgrade(upgrade_key)
	return _calculate_cost(upgrade)


## Returns current level of [Upgrade]
func get_level(upgrade_key: String) -> int:
	assert(
		upgrades.any(func(upgrade: Upgrade) -> bool: return upgrade.key == upgrade_key),
		"Unknown upgrade key: %s" % upgrade_key
	)
	return _progression.upgrade_levels.get(upgrade_key, 0)


## Purchases [Upgrade] based on cost and max level, level++
func purchase(upgrade_key: String) -> bool:
	var upgrade := _get_upgrade(upgrade_key)

	if _can_purchase(upgrade):
		subtract_friendship_points(_calculate_cost(upgrade))
		_increment_level(upgrade.key)
		upgrade_level_changed.emit(upgrade.key)
		SaveManager.save()
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


## Returns base value of an [Upgrade] before any level modifiers
func get_base_value(upgrade_key: String) -> float:
	var upgrade := _get_upgrade(upgrade_key)
	return upgrade.base_value


## Returns current friendship point balance
func get_friendship_point_balance() -> int:
	return _progression.friendship_point_balance


func add_friendship_points(points: int) -> void:
	_progression.friendship_point_balance += points
	friendship_point_balance_changed.emit(_progression.friendship_point_balance)


func subtract_friendship_points(points: int) -> void:
	_progression.friendship_point_balance = max(0, _progression.friendship_point_balance - points)
	friendship_point_balance_changed.emit(_progression.friendship_point_balance)


func _get_upgrade(key: String) -> Upgrade:
	assert(
		upgrades.any(func(upgrade: Upgrade) -> bool: return upgrade.key == key),
		"Unknown upgrade key: %s" % key
	)

	for upgrade: Upgrade in upgrades:
		if upgrade.key == key:
			return upgrade

	return null


func _can_purchase(upgrade: Upgrade) -> bool:
	return (
		_progression.friendship_point_balance >= _calculate_cost(upgrade)
		and get_level(upgrade.key) < upgrade.max_level
	)


func _calculate_cost(upgrade: Upgrade) -> int:
	return int(upgrade.base_cost * pow(upgrade.cost_scaling, get_level(upgrade.key)))


func _calculate_modifier(upgrade: Upgrade) -> float:
	return upgrade.effect_per_level * get_level(upgrade.key)


## Removes one level from an upgrade (dev/debug only)
func remove_level(upgrade_key: String) -> void:
	var current_level := get_level(upgrade_key)
	if current_level > 0:
		_progression.upgrade_levels[upgrade_key] = current_level - 1
		upgrade_level_changed.emit(upgrade_key)
		SaveManager.save()


func _increment_level(upgrade_key: String) -> void:
	_progression.upgrade_levels[upgrade_key] = get_level(upgrade_key) + 1
