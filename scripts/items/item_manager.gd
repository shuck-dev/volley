# gdlint:ignore = max-public-methods
extends Node

signal friendship_point_balance_changed(balance: int)
signal item_level_changed(item_key: String)
signal item_placement_changed(item_key: String, placement: int)
signal court_changed(item_key: String, on_court: bool)
## Emitted when equip refuses; reason is currently &"capacity_exceeded" (sole case).
signal equip_refused(item_key: String, reason: StringName)

const PlacementScript: GDScript = preload("res://scripts/items/placement.gd")

var items: Array[ItemDefinition] = [
	preload("res://resources/items/ankle_weights.tres"),
	preload("res://resources/items/grip_tape.tres"),
	preload("res://resources/items/base_ball.tres"),
	preload("res://resources/items/training_ball.tres"),
	preload("res://resources/items/court_lines.tres"),
	preload("res://resources/items/spare.tres"),
	preload("res://resources/items/cadence.tres"),
	preload("res://resources/items/wrist_brace.tres"),
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


func _register_existing_items() -> void:
	for item in items:
		if get_level(item.key) <= 0:
			continue
		if _is_placed(item.key):
			_effect_manager.register_source(item, get_level(item.key))
		elif not state.rack_slot_index_by_key.has(item.key):
			_assign_rack_slot(item.key, item.role)


## Resyncs effect registrations and emits signals after progression data has been
## reset externally (e.g. dev clear-save).
func reload_from_progression() -> void:
	for item in items:
		_effect_manager.unregister_source(item)

	for partner in ProgressionManager.partners_roster:
		_effect_manager.unregister_source(partner)

	_register_existing_items()
	friendship_point_balance_changed.emit(economy.friendship_point_balance)

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


## Default launch velocity for a ball that lacks a player-supplied gesture.
func get_default_ball_launch_velocity() -> Vector2:
	var min_speed: float = Stats.resolve(GameRules.base.ball_speed_min, &"ball_speed_min")
	return Vector2(min_speed, min_speed * 0.5).normalized() * min_speed


## Returns the summed additive modifiers (including oscillations) for a stat key.
func get_modifier(key: StringName) -> float:
	return _effect_manager.get_modifier(key)


## Same as `get_modifier`, excluding temporary (until-miss) modifiers.
func get_permanent_modifier(key: StringName) -> float:
	return _effect_manager.get_permanent_modifier(key)


## Returns the summed percentage offset for a stat (e.g. 0.8 means +80%)
func get_percentage_offset(key: StringName) -> float:
	return _effect_manager.get_percentage_offset(key)


## Returns whether a named game state is currently active
func is_game_state_active(game_state: StringName) -> bool:
	return _effect_manager.is_game_state_active(game_state)


## Returns current level of an item (0 if not owned)
func get_level(item_key: String) -> int:
	return state.item_levels.get(item_key, 0)


## Returns the current placement of an item. Defaults to STORED (on the rack).
## LOOSE_IN_VENUE overlays the persisted placement so callers see the runtime state.
func _get_placement(item_key: String) -> int:
	if state.loose_in_venue.has(item_key):
		return PlacementScript.LOOSE_IN_VENUE
	return state.item_placements.get(item_key, PlacementScript.STORED)


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
	item_placement_changed.emit(item_key, PlacementScript.LOOSE_IN_VENUE)


## Clears the loose-in-venue entry. Idempotent. Emits item_placement_changed with the underlying placement.
func clear_loose_in_venue(item_key: String) -> void:
	if not state.loose_in_venue.has(item_key):
		return
	state.loose_in_venue.erase(item_key)
	item_placement_changed.emit(item_key, _get_placement(item_key))


## True when an item is currently placed (on player or court), false on the rack or loose in venue.
func is_on_court(item_key: String) -> bool:
	var placement: int = _get_placement(item_key)
	return placement == PlacementScript.EQUIPPED or placement == PlacementScript.ON_COURT


## Returns the list of ball-role item keys currently on the court.
func get_court_items() -> Array[String]:
	var result: Array[String] = []
	for item in items:
		if item.role == &"ball" and _get_placement(item.key) == PlacementScript.ON_COURT:
			result.append(item.key)
	return result


## Slot index assigned to `item_key` while STORED; -1 when not stored.
func get_rack_slot_index(item_key: String) -> int:
	return state.rack_slot_index_by_key.get(item_key, -1)


## Picks the lowest free slot index among STORED items of the same role and records it.
## Idempotent: an item with an existing assignment keeps it.
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


## Returns owned items of the given role whose placement is STORED (on the rack).
func get_kit_items(role: StringName) -> Array[String]:
	var result: Array[String] = []

	for item in items:
		if item.role != role:
			continue

		if get_level(item.key) <= 0:
			continue

		if _get_placement(item.key) != PlacementScript.STORED:
			continue

		result.append(item.key)

	return result


## Places an owned item on its natural target and registers effects at current level; false if unowned.
func activate(item_key: String) -> bool:
	if get_level(item_key) <= 0:
		return false

	_set_item_placement(item_key, _natural_target(_get_item(item_key)))

	return true


## Moves an owned item back to the rack and unregisters its effects; false if unowned.
func deactivate(item_key: String) -> bool:
	if get_level(item_key) <= 0:
		return false

	_set_item_placement(item_key, PlacementScript.STORED)

	return true


## Free kit slots; clamped at zero so over-capacity loads do not report negative.
func get_kit_remaining() -> int:
	var cap: int = int(floor(Stats.resolve(GameRules.base.kit_slots, &"kit_slots", self)))
	var equipped_count: int = 0

	for key: String in state.item_placements:
		if int(state.item_placements[key]) == PlacementScript.EQUIPPED:
			equipped_count += 1

	return max(0, cap - equipped_count)


## Equipment-role placement gated by kit capacity; emits `equip_refused` on capacity rejection.
## Returns false silently on role mismatch so callers can fall through to other targets.
func equip(item_key: String) -> bool:
	var item: ItemDefinition = _get_item(item_key)
	if item.role != &"equipment":
		return false

	if get_kit_remaining() < 1:
		equip_refused.emit(item_key, &"capacity_exceeded")
		return false

	return activate(item_key)


## Symmetric wrapper over `deactivate`; named for intent at equip/unequip call sites.
func unequip(item_key: String) -> bool:
	return deactivate(item_key)


## Returns total cost of an item at its current level
func calculate_cost(item_key: String) -> int:
	var item: ItemDefinition = _get_item(item_key)
	return int(item.base_cost * pow(item.cost_scaling, get_level(item_key)))


## Returns true if the item is unowned and affordable. Used by drop targets.
func can_acquire(item_key: String) -> bool:
	return get_level(item_key) == 0 and economy.friendship_point_balance >= calculate_cost(item_key)


## Returns whether the player can afford and has not maxed an item
func can_purchase(item_key: String) -> bool:
	var item := _get_item(item_key)
	return (
		economy.friendship_point_balance >= calculate_cost(item_key)
		and get_level(item_key) < item.max_level
	)


## Purchases an item if affordable, returns true on success
func purchase(item_key: String) -> bool:
	if not can_purchase(item_key):
		return false

	var was_unowned := get_level(item_key) == 0
	subtract_friendship_points(calculate_cost(item_key))
	var new_level := get_level(item_key) + 1
	state.item_levels[item_key] = new_level

	if was_unowned:
		var item := _get_item(item_key)
		var goes_to_rack: bool = item.role == &"equipment" and item.type != &"court"
		var landing: int = PlacementScript.STORED if goes_to_rack else _natural_target(item)
		if landing == PlacementScript.STORED:
			_assign_rack_slot(item_key, item.role)
		else:
			_set_item_placement(item_key, landing)
	elif _is_placed(item_key):
		_refresh_registration(item_key)

	item_level_changed.emit(item_key)
	SaveManager.save()

	return true


## Returns current friendship point balance
func get_friendship_point_balance() -> int:
	return economy.friendship_point_balance


## Only earning path. Increments `total_friendship_points_earned` so the shop
## unlock check stays correct across spending. Refunds use `_refund_friendship_points`.
func add_friendship_points(points: int) -> void:
	economy.friendship_point_balance += points
	economy.total_friendship_points_earned += points
	friendship_point_balance_changed.emit(economy.friendship_point_balance)


## Subtracts friendship points (clamped to zero) and emits balance changed signal
func subtract_friendship_points(points: int) -> void:
	economy.friendship_point_balance = max(0, economy.friendship_point_balance - points)
	friendship_point_balance_changed.emit(economy.friendship_point_balance)


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

		if current_level - 1 == 0:
			# Fully removed: treat the item as if it was never owned; clear placement.
			_set_item_placement(item_key, PlacementScript.STORED)
		SaveManager.save()


## Adopts an authored on-court item at level >= 1 with on-court placement; idempotent.
func adopt_authored(item_key: String) -> void:
	if get_level(item_key) <= 0:
		state.item_levels[item_key] = 1
		item_level_changed.emit(item_key)

	if not is_on_court(item_key):
		_set_item_placement(item_key, _natural_target(_get_item(item_key)))


## Acquires an item without registering its effects. The item is owned but
## inert until equipped into the kit. Returns true on success.
func take(item_key: String) -> bool:
	if get_level(item_key) >= 1:
		return false

	if economy.friendship_point_balance < calculate_cost(item_key):
		return false

	subtract_friendship_points(calculate_cost(item_key))
	state.item_levels[item_key] = 1
	_assign_rack_slot(item_key, _get_item(item_key).role)
	item_level_changed.emit(item_key)
	SaveManager.save()

	return true


## Returns points to the balance without counting them as newly earned.
## Used for undo flows (dev level removal, future kit swaps); not a public API.
func _refund_friendship_points(points: int) -> void:
	economy.friendship_point_balance += points
	friendship_point_balance_changed.emit(economy.friendship_point_balance)


func _set_level(item_key: String, level: int) -> void:
	state.item_levels[item_key] = level

	if _is_placed(item_key):
		_refresh_registration(item_key)

	item_level_changed.emit(item_key)


func _set_item_placement(item_key: String, placement: int) -> void:
	var previous := _get_placement(item_key)
	if previous == placement:
		return
	var item := _get_item(item_key)
	assert(item.role != StringName(), "ItemDefinition.role must be set: " + item.key)
	if placement == PlacementScript.STORED:
		state.item_placements.erase(item_key)
		_effect_manager.unregister_source(item)
		_assign_rack_slot(item_key, item.role)
	else:
		state.item_placements[item_key] = placement
		_effect_manager.unregister_source(item)
		_effect_manager.register_source(item, get_level(item_key))
		state.rack_slot_index_by_key.erase(item_key)
	item_placement_changed.emit(item_key, placement)
	var was_on_court := previous == PlacementScript.ON_COURT
	var now_on_court := placement == PlacementScript.ON_COURT
	if was_on_court != now_on_court and item.role == &"ball":
		court_changed.emit(item_key, now_on_court)


func _refresh_registration(item_key: String) -> void:
	var item := _get_item(item_key)
	_effect_manager.unregister_source(item)
	var level := get_level(item_key)
	if level > 0:
		_effect_manager.register_source(item, level)


func _is_placed(item_key: String) -> bool:
	return _get_placement(item_key) != PlacementScript.STORED


func _natural_target(item: ItemDefinition) -> int:
	return PlacementScript.ON_COURT if item.role == &"ball" else PlacementScript.EQUIPPED


func _get_item(item_key: String) -> ItemDefinition:
	for item: ItemDefinition in items:
		if item.key == item_key:
			return item
	assert(false, "Unknown item key: %s" % item_key)
	return null
