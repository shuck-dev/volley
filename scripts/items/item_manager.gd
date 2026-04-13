extends Node

signal friendship_point_balance_changed(balance: int)
signal item_level_changed(item_key: String)

var items: Array[ItemDefinition] = [
	preload("res://resources/items/ankle_weights.tres"),
	preload("res://resources/items/grip_tape.tres"),
	preload("res://resources/items/training_ball.tres"),
	preload("res://resources/items/court_lines.tres"),
	preload("res://resources/items/double_knot.tres"),
	preload("res://resources/items/spare.tres"),
	preload("res://resources/items/cadence.tres"),
	preload("res://resources/items/wrist_brace.tres"),
]

var _progression: ProgressionData
var _effect_manager: EffectManager


func _ready() -> void:
	if _progression == null:
		_progression = SaveManager.get_progression_data()
	if _effect_manager == null:
		_effect_manager = EffectManager.new()
		_effect_manager.name = "EffectManager"

	add_child(_effect_manager)
	_register_existing_items()


func _register_existing_items() -> void:
	for item in items:
		var level: int = get_level(item.key)
		if level > 0:
			_effect_manager.register_source(item, level)


## Resyncs effect registrations and emits signals after progression data has been
## reset externally (e.g. dev clear-save).
func reload_from_progression() -> void:
	for item in items:
		_effect_manager.unregister_source(item)
	_register_existing_items()
	friendship_point_balance_changed.emit(_progression.friendship_point_balance)
	for item in items:
		item_level_changed.emit(item.key)


## Registers a partner's effects with the effect system
func register_partner(partner: Resource) -> void:
	_effect_manager.register_source(partner, 1)


## Unregisters a partner's effects from the effect system
func unregister_partner(partner: Resource) -> void:
	_effect_manager.unregister_source(partner)


## Dispatches a game event to the effect system for causality processing
func process_event(event_type: StringName) -> Array[StringName]:
	return _effect_manager.process_event(event_type)


## Advances continuous effects like oscillation
func process_frame(delta: float) -> void:
	_effect_manager.process_frame(delta)


## Returns the resolved stat value after all active modifiers
func get_stat(key: StringName) -> float:
	return _effect_manager.get_stat(key)


## Returns the stat value excluding temporary (until-miss) modifiers
func get_base_stat(key: StringName) -> float:
	return _effect_manager.get_base_stat(key)


## Returns the summed percentage offset for a stat (e.g. 0.8 means +80%)
func get_percentage_offset(key: StringName) -> float:
	return _effect_manager.get_percentage_offset(key)


## Returns whether a named game state is currently active
func is_game_state_active(state: StringName) -> bool:
	return _effect_manager.is_game_state_active(state)


## Returns current level of an item (0 if not owned)
func get_level(item_key: String) -> int:
	return _progression.item_levels.get(item_key, 0)


## Returns total cost of an item at its current level
func calculate_cost(item_key: String) -> int:
	var item: ItemDefinition = _get_item(item_key)
	return int(item.base_cost * pow(item.cost_scaling, get_level(item_key)))


## Returns true if the item is unowned and affordable. Used by drop targets.
func can_acquire(item_key: String) -> bool:
	return (
		get_level(item_key) == 0
		and _progression.friendship_point_balance >= calculate_cost(item_key)
	)


## Returns whether the player can afford and has not maxed an item
func can_purchase(item_key: String) -> bool:
	var item := _get_item(item_key)
	return (
		_progression.friendship_point_balance >= calculate_cost(item_key)
		and get_level(item_key) < item.max_level
	)


## Purchases an item if affordable, returns true on success
func purchase(item_key: String) -> bool:
	if not can_purchase(item_key):
		return false
	subtract_friendship_points(calculate_cost(item_key))
	_set_level(item_key, get_level(item_key) + 1)
	SaveManager.save()
	return true


## Returns current friendship point balance
func get_friendship_point_balance() -> int:
	return _progression.friendship_point_balance


## Only earning path. Increments `total_friendship_points_earned` so the shop
## unlock check stays correct across spending. Refunds use `_refund_friendship_points`.
func add_friendship_points(points: int) -> void:
	_progression.friendship_point_balance += points
	_progression.total_friendship_points_earned += points
	friendship_point_balance_changed.emit(_progression.friendship_point_balance)


## Subtracts friendship points (clamped to zero) and emits balance changed signal
func subtract_friendship_points(points: int) -> void:
	_progression.friendship_point_balance = max(0, _progression.friendship_point_balance - points)
	friendship_point_balance_changed.emit(_progression.friendship_point_balance)


## Removes one level from an item (dev/debug only)
func remove_level(item_key: String) -> void:
	if not OS.is_debug_build():
		return

	var current_level := get_level(item_key)
	if current_level > 0:
		var item := _get_item(item_key)
		var refund := int(item.base_cost * pow(item.cost_scaling, current_level - 1))
		_refund_friendship_points(refund)
		_set_level(item_key, current_level - 1)
		SaveManager.save()


## Acquires an item without registering its effects. The item is owned but
## inert until equipped into the kit. Returns true on success.
func take(item_key: String) -> bool:
	if get_level(item_key) >= 1:
		return false
	if _progression.friendship_point_balance < calculate_cost(item_key):
		return false
	subtract_friendship_points(calculate_cost(item_key))
	_progression.item_levels[item_key] = 1
	item_level_changed.emit(item_key)
	SaveManager.save()
	return true


## Returns points to the balance without counting them as newly earned.
## Used for undo flows (dev level removal, future kit swaps); not a public API.
func _refund_friendship_points(points: int) -> void:
	_progression.friendship_point_balance += points
	friendship_point_balance_changed.emit(_progression.friendship_point_balance)


func _set_level(item_key: String, level: int) -> void:
	var item := _get_item(item_key)
	_effect_manager.unregister_source(item)
	_progression.item_levels[item_key] = level
	if level > 0:
		_effect_manager.register_source(item, level)
	item_level_changed.emit(item_key)


func _get_item(item_key: String) -> ItemDefinition:
	for item: ItemDefinition in items:
		if item.key == item_key:
			return item
	assert(false, "Unknown item key: %s" % item_key)
	return null
