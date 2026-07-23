# gdlint:ignore = max-public-methods
extends Node

signal soul_balance_changed(balance: int)
signal item_level_changed(item_key: String)
signal item_placement_changed(item_key: String, placement: int)
signal court_changed(item_key: String, on_court: bool)
## Emitted when the rack slot map mutates so a stale RackDisplay re-renders the changed slot.
signal rack_slots_changed
## Emitted after every rack-state mutation so consumers derive from one signal.
signal item_manager_state_changed

var items: Array[ItemDefinition] = [
	preload("res://resources/items/old_ball.tres"),
	preload("res://resources/items/standard_ball.tres"),
	preload("res://resources/items/cadence_ball.tres"),
]

var state: ItemState
var economy: EconomyState
var _effect_manager: EffectManager


func _ready() -> void:
	if state == null:
		state = SaveManager.items

	if economy == null:
		economy = SaveManager.economy

	if _effect_manager == null:
		_effect_manager = EffectManager.new()
		_effect_manager.name = "EffectManager"

	add_child(_effect_manager)
	_register_existing_items()
	item_manager_state_changed.emit()


## Resyncs effect registrations and emits signals after progression data has been
## reset externally (e.g. dev clear-save).
func reload_from_progression() -> void:
	if not OS.is_debug_build():
		return

	for item in items:
		_effect_manager.unregister_source(item, item.key)

	for partner in ProgressionManager.partners_roster:
		_effect_manager.unregister_source(partner)

	_register_existing_items()
	soul_balance_changed.emit(economy.soul_balance)

	for item in items:
		item_level_changed.emit(item.key)


## Registers a partner's effects with the effect system
func register_partner(partner: Resource) -> void:
	_effect_manager.register_source(partner, 1)


## Unregisters a partner's effects from the effect system
func unregister_partner(partner: Resource) -> void:
	_effect_manager.unregister_source(partner)


## Dispatches a game event to the effect system for causality processing
func process_event(event_type: StringName, instance_key: String = "") -> Array[StringName]:
	return _effect_manager.process_event(event_type, instance_key)


## Advances continuous effects like oscillation
func process_frame(delta: float) -> void:
	_effect_manager.process_frame(delta)


## Default launch velocity for a ball that lacks a player-supplied gesture.
func get_default_ball_launch_velocity() -> Vector2:
	var min_speed: float = Stats.resolve(GameRules.base.ball_speed_min, &"ball_speed_min")
	return Vector2(min_speed, min_speed * 0.5).normalized() * min_speed


## Returns the resolved stat value (base + additive modifiers + percentage offset) for a stat key.
func get_stat(key: StringName, instance_key: String = "") -> float:
	return _effect_manager.get_stat(key, instance_key)


## Registers an effect source with the effect system at the given level.
func register_source(
	source: Resource, level: int, source_key: String = "", instanced: bool = false
) -> void:
	_effect_manager.register_source(source, level, source_key, instanced)


## Returns the summed additive modifiers (including stat shifts) for a stat key.
func get_modifier(key: StringName, instance_key: String = "") -> float:
	return _effect_manager.get_modifier(key, instance_key)


## Same as `get_modifier`, excluding temporary (until-miss) modifiers.
func get_permanent_modifier(key: StringName, instance_key: String = "") -> float:
	return _effect_manager.get_permanent_modifier(key, instance_key)


## Returns the summed percentage offset for a stat (e.g. 0.8 means +80%)
func get_percentage_offset(key: StringName, instance_key: String = "") -> float:
	return _effect_manager.get_percentage_offset(key, instance_key)


## Returns whether a named game state is currently active
func is_game_state_active(game_state: StringName) -> bool:
	return _effect_manager.is_game_state_active(game_state)


## Returns the StatShift instances registered under `instance_key` (e.g. a ball's
## item_key), for callers that need to observe a specific instance's transitions.
func get_shifts(instance_key: String) -> Array[StatShift]:
	return _effect_manager.get_shifts(instance_key)


## Returns current level of an item (0 if not owned)
func get_level(item_key: String) -> int:
	if state.item_levels.has(item_key):
		return state.item_levels[item_key]

	var base := _base_key(item_key)

	if base != item_key:
		return 0

	var item_def := _get_item(item_key)

	if item_def != null and item_def.role == &"ball":
		var max_level := 0
		for key in state.item_levels:
			if BallKey.is_instance(item_key, key):
				max_level = max(max_level, state.item_levels[key])

		return max(max_level, get_owned_count(item_key))

	return 0


## Returns the current placement of an item.
func _get_placement(item_key: String) -> int:
	if state.loose_in_venue.has(item_key):
		return Placement.LOOSE_IN_VENUE

	if state.item_placements.has(item_key):
		return state.item_placements[item_key]

	return Placement.STORED


## Returns the current placement; STORED, EQUIPPED, ON_COURT, or LOOSE_IN_VENUE.
func get_placement(item_key: String) -> int:
	return _get_placement(item_key)


## True when a loose body for this item exists on the venue floor.
func is_loose_in_venue(item_key: String) -> bool:
	return state.loose_in_venue.has(item_key)


## Marks an owned item as loose-in-venue at `position`. Idempotent. Emits item_placement_changed.
func mark_loose_in_venue(item_key: String, position: Vector2 = Vector2.ZERO) -> void:
	if state.loose_in_venue.has(item_key):
		state.loose_in_venue[item_key] = position
		return
	state.loose_in_venue[item_key] = position
	item_placement_changed.emit(item_key, Placement.LOOSE_IN_VENUE)


## Clears the loose-in-venue entry. Idempotent. Emits item_placement_changed with the underlying placement.
func clear_loose_in_venue(item_key: String) -> void:
	if not state.loose_in_venue.has(item_key):
		return
	state.loose_in_venue.erase(item_key)
	item_placement_changed.emit(item_key, _get_placement(item_key))


## True when an item is currently placed (on player or court), false on the rack or loose in venue.
func is_on_court(item_key: String) -> bool:
	var placement: int = _get_placement(item_key)
	return placement == Placement.EQUIPPED or placement == Placement.ON_COURT


## Slot index assigned to `item_key` while STORED; -1 when not stored.
func get_rack_slot_index(item_key: String) -> int:
	return state.rack_slot_index_by_key.get(item_key, -1)


## Frees the rack slot a held item occupied so concurrent inserts fill from the lowest free slot.
## Held balls stay STORED with no held-ness signal here, so the drag path releases the slot.
func release_rack_slot(item_key: String) -> void:
	if not state.rack_slot_index_by_key.has(item_key):
		return
	state.rack_slot_index_by_key.erase(item_key)
	rack_slots_changed.emit()


## Re-assigns the lowest free rack slot when a held item returns to the rack.
func reassign_rack_slot(item_key: String) -> void:
	_assign_rack_slot(item_key, _require_item(item_key).role)


## Picks the lowest free slot index among STORED items of the same role and records it.
## Idempotent: an item with an existing assignment keeps it. Survivors of a pop never reshuffle.
func _assign_rack_slot(item_key: String, role: StringName) -> void:
	if state.rack_slot_index_by_key.has(item_key):
		return

	var used: Dictionary = {}
	for key: String in state.rack_slot_index_by_key:
		var definition: ItemDefinition = _get_item(key)
		if definition != null and definition.role == role:
			used[state.rack_slot_index_by_key[key]] = true

	var candidate: int = 0
	while used.has(candidate):
		candidate += 1

	state.rack_slot_index_by_key[item_key] = candidate
	rack_slots_changed.emit()


## Returns owned items of the given role whose placement is STORED (on the rack).
func get_kit_items(role: StringName) -> Array[String]:
	var result: Array[String] = []

	for key in state.item_levels:
		if state.item_levels[key] <= 0:
			continue
		if _get_placement(key) != Placement.STORED:
			continue
		var item := _get_item(key)
		if item != null and item.role == role:
			result.append(key)

	return result


## Places an owned item on its natural target and registers effects at current level; false if unowned.
func activate(item_key: String) -> bool:
	if get_level(item_key) <= 0:
		return false

	_set_item_placement(item_key, _natural_target(_require_item(item_key)))

	return true


## Moves an owned item back to the rack and unregisters its effects; false if unowned.
func deactivate(item_key: String) -> bool:
	if get_level(item_key) <= 0:
		return false

	_set_item_placement(item_key, Placement.STORED)

	return true


## Equipment-role placement; returns false silently on role mismatch so callers can fall through.
func equip(item_key: String) -> bool:
	var item: ItemDefinition = _require_item(item_key)
	if item.role != &"equipment":
		return false

	return activate(item_key)


## Symmetric wrapper over `deactivate`; named for intent at equip/unequip call sites.
func unequip(item_key: String) -> bool:
	return deactivate(item_key)


func calculate_for_purchase(item_key: String) -> int:
	var item := _require_item(item_key)
	if item.role == &"ball":
		return int(item.base_cost * pow(2.0, get_owned_count(item.key)))
	return int(item.base_cost * pow(item.cost_scaling, get_level(item_key)))


## Returns total cost of an item at its current level
func calculate_cost(item_key: String) -> int:
	var item := _require_item(item_key)
	return int(item.base_cost * pow(item.cost_scaling, get_level(item_key)))


## Returns true if the item is affordable. Used by drop targets.
func can_acquire(item_key: String) -> bool:
	var item := _require_item(item_key)
	if item.role == &"ball":
		return economy.soul_balance >= calculate_for_purchase(item_key)
	return get_level(item_key) == 0 and economy.soul_balance >= calculate_cost(item_key)


## Returns whether the player can afford and has not maxed an item
func can_purchase(item_key: String) -> bool:
	var item := _require_item(item_key)
	if item.role == &"ball":
		return (
			economy.soul_balance >= calculate_for_purchase(item_key)
			and get_owned_count(item.key) < item.max_level
		)
	return economy.soul_balance >= calculate_cost(item_key) and get_level(item_key) < item.max_level


## Purchases an item if affordable, returns true on success
func purchase(item_key: String) -> bool:
	if not can_purchase(item_key):
		return false

	subtract_soul(calculate_cost(item_key))
	var new_level := get_level(item_key) + 1
	state.item_levels[item_key] = new_level

	if _is_placed(item_key):
		_refresh_registration(item_key)

	item_level_changed.emit(item_key)
	item_manager_state_changed.emit()
	SaveManager.save()

	return true


## Returns current soul balance.
func get_soul_balance() -> int:
	return economy.soul_balance


## Only earning path. Increments `total_soul_earned` so the shop
## unlock check stays correct across spending. Refunds use `_refund_soul`.
func add_soul(points: int) -> void:
	economy.soul_balance += points
	economy.total_soul_earned += points
	soul_balance_changed.emit(economy.soul_balance)


## Subtracts soul (clamped to zero) and emits balance changed signal.
func subtract_soul(points: int) -> void:
	economy.soul_balance = max(0, economy.soul_balance - points)
	soul_balance_changed.emit(economy.soul_balance)


## Removes one level from an item (dev/debug only)
func remove_level(item_key: String) -> void:
	if not OS.is_debug_build():
		return

	var current_level := get_level(item_key)
	if current_level > 0:
		var item := _require_item(item_key)
		var new_level: int = current_level - 1
		var refund := int(item.base_cost * pow(item.cost_scaling, new_level))
		_refund_soul(refund)
		_set_level(item_key, new_level)

		if current_level - 1 == 0:
			# Fully removed: clear placement so the freed slot is released and no live ball lingers.
			_set_item_placement(item_key, Placement.STORED)
			state.rack_slot_index_by_key.erase(item_key)
	item_manager_state_changed.emit()


func _register_existing_items() -> void:
	for key in state.item_levels:
		if state.item_levels[key] <= 0:
			continue
		var item := _get_item(key)
		if item == null:
			continue
		if _is_placed(key):
			_effect_manager.register_source(item, state.item_levels[key], key, _is_instanced(item))
		elif not state.rack_slot_index_by_key.has(key):
			_assign_rack_slot(key, item.role)

		SaveManager.save()


## Bumps an owned ball item by one level (capped at max_level), refreshing its effects.
## Returns true when the level increased. Intended for tier-completion ball upgrades.
func upgrade_ball(item_key: String) -> bool:
	var item := _get_item(item_key)
	if item == null or item.role != &"ball":
		return false

	var current_level := get_level(item_key)
	if current_level <= 0 or current_level >= item.max_level:
		return false

	_set_level(item_key, current_level + 1)
	return true


## Deducts soul for purchasing a ball. The reconciler owns instance key generation
## and state registration; this only handles economics.
func take_ball(item_key: String) -> bool:
	var item := _get_item(item_key)
	if item == null or item.role != &"ball":
		return false
	if economy.soul_balance < calculate_for_purchase(item_key):
		return false
	subtract_soul(calculate_for_purchase(item_key))
	SaveManager.save()
	return true


## Acquires an equipment item. The item is owned but inert until equipped.
func take_equipment(item_key: String) -> bool:
	var item := _get_item(item_key)
	if item == null or item.role != &"equipment":
		return false
	if get_level(item_key) >= 1:
		return false
	if economy.soul_balance < calculate_cost(item_key):
		return false
	subtract_soul(calculate_cost(item_key))
	state.item_levels[item_key] = 1
	_assign_rack_slot(item_key, item.role)
	item_level_changed.emit(item_key)
	SaveManager.save()
	return true


## Acquires an item without registering its effects. The item is owned but
## inert until equipped. Routes to take_ball or take_equipment by role.
func take(item_key: String) -> bool:
	var item := _get_item(item_key)
	if item == null:
		return false
	if item.role == &"ball":
		if not take_ball(item_key):
			return false
		register_instance(generate_instance_key(item_key), item.role)
		return true
	return take_equipment(item_key)


## Returns points to the balance without counting them as newly earned.
## Used for undo flows (dev level removal, future kit swaps); not a public API.
func _refund_soul(points: int) -> void:
	economy.soul_balance += points
	soul_balance_changed.emit(economy.soul_balance)


func _set_level(item_key: String, level: int) -> void:
	state.item_levels[item_key] = level

	if _is_placed(item_key):
		_refresh_registration(item_key)

	item_level_changed.emit(item_key)


func _set_item_placement(item_key: String, placement: int) -> void:
	var previous: int = state.item_placements.get(item_key, Placement.STORED)
	var item := _require_item(item_key)
	assert(item.role != StringName(), "ItemDefinition.role must be set: " + item.key)

	# Slot bookkeeping runs even on an unchanged placement so a STORED item always owns a slot
	# and a placed item never leaks one, regardless of whether the placement value moved.
	if placement == Placement.STORED:
		state.item_placements.erase(item_key)
		state.loose_in_venue.erase(item_key)
		_effect_manager.unregister_source(item, item_key)
		_assign_rack_slot(item_key, item.role)
	else:
		state.item_placements[item_key] = placement
		state.loose_in_venue.erase(item_key)
		_effect_manager.unregister_source(item, item_key)
		_effect_manager.register_source(item, get_level(item_key), item_key, _is_instanced(item))
		state.rack_slot_index_by_key.erase(item_key)

	item_manager_state_changed.emit()

	if previous == placement and not state.loose_in_venue.has(item_key):
		return

	item_placement_changed.emit(item_key, placement)
	var was_on_court := previous == Placement.ON_COURT
	var now_on_court := placement == Placement.ON_COURT

	if was_on_court != now_on_court and item.role == &"ball":
		court_changed.emit(item_key, now_on_court)


func _refresh_registration(item_key: String) -> void:
	var item := _require_item(item_key)
	_effect_manager.unregister_source(item, item_key)
	var level := get_level(item_key)
	if level > 0:
		_effect_manager.register_source(item, level, item_key, _is_instanced(item))


func _is_placed(item_key: String) -> bool:
	return _get_placement(item_key) != Placement.STORED


func _natural_target(item: ItemDefinition) -> int:
	return Placement.ON_COURT if item.role == &"ball" else Placement.EQUIPPED


## Ball-role items get instance-scoped effect registration; equipment stays global.
func _is_instanced(item: ItemDefinition) -> bool:
	return item.role == &"ball"


func _base_key(item_key: String) -> String:
	var base := BallKey.base_key(item_key)
	if base == item_key:
		return item_key
	for item: ItemDefinition in items:
		if item.key == base:
			return base
	return item_key


func get_owned_count(base_key: String) -> int:
	var count := 0
	for key in state.item_levels:
		if BallKey.is_instance(base_key, key) and state.item_levels[key] > 0:
			count += 1
		elif key == base_key and state.item_levels[key] > 0:
			count += 1
	return count


func generate_instance_key(base_key: String) -> String:
	return BallKey.generate(base_key, state.item_levels)


func register_instance(item_key: String, role: StringName) -> void:
	state.item_levels[item_key] = 1
	_assign_rack_slot(item_key, role)
	item_manager_state_changed.emit()
	SaveManager.save()


func adopt_instance(item_key: String) -> void:
	state.item_levels[item_key] = 1
	item_manager_state_changed.emit()
	SaveManager.save()


func _get_item(item_key: String) -> ItemDefinition:
	var base_key := _base_key(item_key)
	for item: ItemDefinition in items:
		if item.key == base_key:
			return item
	push_warning("ItemManager: unknown item key: %s" % item_key)
	return null


## Same as `_get_item`, but for call sites reached only from live gameplay on an
## already-owned item, where a null result means a real internal inconsistency,
## not a stale/foreign save key. Fails loudly instead of pushing the null onward.
func _require_item(item_key: String) -> ItemDefinition:
	var item := _get_item(item_key)
	assert(item != null, "ItemManager: expected a known item for key: %s" % item_key)
	return item
