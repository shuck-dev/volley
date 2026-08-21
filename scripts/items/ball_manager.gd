# gdlint:ignore = max-public-methods
extends Node

signal soul_balance_changed(balance: int)
signal item_level_changed(ball_key: String)
signal item_placement_changed(ball_key: String, placement: int)
## Emitted when the rack slot map mutates so a stale RackDisplay re-renders the changed slot.
signal rack_slots_changed
## Emitted after any state mutation (level, placement, or initial load) so consumers derive from one signal.
signal state_changed

const _ITEM_PATHS: Array[String] = [
	"res://resources/items/old_ball.tres",
	"res://resources/items/standard_ball.tres",
	"res://resources/items/cadence_ball.tres",
	"res://resources/items/goop_ball.tres",
	"res://resources/items/cheater_ball.tres",
	"res://resources/items/comeback_ball.tres",
]

## Populated in _ready via load() rather than a preload initializer, avoiding a parse-time cycle the web export can't tolerate.
var items: Array[BallDefinition] = []

var economy: EconomyState

var _state: BallState


func _ready() -> void:
	if items.is_empty():
		for path in _ITEM_PATHS:
			items.append(load(path))

	if _state == null:
		_state = SaveManager.items

	if economy == null:
		economy = SaveManager.economy

	_register_existing_items()
	state_changed.emit()


## Default launch velocity for a ball that lacks a player-supplied gesture.
func get_default_ball_launch_velocity() -> Vector2:
	var min_speed: float = GameRules.base.ball_speed_min
	return Vector2(min_speed, min_speed * 0.5).normalized() * min_speed


## Returns current level of an item (0 if not owned)
func get_level(ball_key: String) -> int:
	if _state.ball_levels.has(ball_key):
		return _state.ball_levels[ball_key]

	var base := _base_key(ball_key)

	if base != ball_key:
		return 0

	var item_def := _get_item(ball_key)

	if item_def == null:
		return 0

	var max_level := 0
	for key in _state.ball_levels:
		if BallKey.is_instance(ball_key, key):
			max_level = max(max_level, _state.ball_levels[key])

	return max(max_level, get_owned_count(ball_key))


## Returns the current placement of an item. Every owned item has exactly one entry.
func _get_placement(ball_key: String) -> int:
	assert(
		_state.ball_placement.has(ball_key), "BallManager: no placement recorded for %s" % ball_key
	)
	return _state.ball_placement.get(ball_key, Placement.LOOSE_IN_VENUE)


## Returns the current placement; STORED, ON_COURT, LOOSE_IN_VENUE, or IN_KIT.
func get_placement(ball_key: String) -> int:
	return _get_placement(ball_key)


## True when the item's placement is LOOSE_IN_VENUE; tolerates an unregistered ball (false).
func is_loose_in_venue(ball_key: String) -> bool:
	return _state.ball_placement.get(ball_key, -1) == Placement.LOOSE_IN_VENUE


## Marks an owned item as loose-in-venue at `position`. Idempotent. Emits item_placement_changed.
func mark_loose_in_venue(ball_key: String, position: Vector2 = Vector2.ZERO) -> void:
	if is_loose_in_venue(ball_key):
		_state.ball_venue_position[ball_key] = position
		return
	_set_item_placement(ball_key, Placement.LOOSE_IN_VENUE, position)


## Restores a loose item to the rack. Idempotent. Emits item_placement_changed.
func clear_loose_in_venue(ball_key: String) -> void:
	if not is_loose_in_venue(ball_key):
		return
	_set_item_placement(ball_key, Placement.STORED)


## True when an item is currently placed on the court, false on the rack or loose in venue.
func is_on_court(ball_key: String) -> bool:
	return _get_placement(ball_key) == Placement.ON_COURT


## Slot index assigned to `ball_key` while STORED; -1 when not stored (including unowned keys).
func get_rack_slot_index(ball_key: String) -> int:
	if _state.ball_placement.get(ball_key, -1) != Placement.STORED:
		return -1
	return _state.ball_slot.get(ball_key, -1)


## Frees the rack slot a held item occupied so concurrent inserts fill from the lowest free slot.
## Held balls stay STORED with no held-ness signal here, so the drag path releases the slot.
func release_rack_slot(ball_key: String) -> void:
	if not _state.ball_slot.has(ball_key):
		return
	_state.ball_slot.erase(ball_key)
	rack_slots_changed.emit()


## Re-assigns the lowest free rack slot when a held item returns to the rack.
func reassign_rack_slot(ball_key: String) -> void:
	_assign_rack_slot(ball_key)


## Picks the lowest free slot index among STORED items (ball_slot is shared with Kit) and records it.
func _assign_rack_slot(ball_key: String) -> void:
	if (
		_state.ball_slot.has(ball_key)
		and _state.ball_placement.get(ball_key, -1) == Placement.STORED
	):
		return

	var used: Dictionary = {}
	for key: String in _state.ball_slot:
		if _state.ball_placement.get(key, -1) == Placement.STORED:
			used[_state.ball_slot[key]] = true

	var candidate: int = 0
	while used.has(candidate):
		candidate += 1

	_state.ball_slot[ball_key] = candidate
	rack_slots_changed.emit()


## Returns owned items whose placement is ON_COURT.
func get_on_court_items() -> Array[String]:
	return _items_with_placement(Placement.ON_COURT)


## Returns owned items whose placement is STORED (on the rack).
func get_stored_items() -> Array[String]:
	return _items_with_placement(Placement.STORED)


## Returns owned items whose placement is IN_KIT (the Ball Kit staging area).
func get_kit_items() -> Array[String]:
	return _items_with_placement(Placement.IN_KIT)


func _items_with_placement(placement: int) -> Array[String]:
	var result: Array[String] = []

	for key in _state.ball_levels:
		if _state.ball_levels[key] <= 0:
			continue
		if _get_placement(key) != placement:
			continue
		if _get_item(key) != null:
			result.append(key)

	return result


## Kit slot index assigned to `ball_key` while IN_KIT; -1 when not kitted (including unowned keys).
func get_kit_slot_index(ball_key: String) -> int:
	if _state.ball_placement.get(ball_key, -1) != Placement.IN_KIT:
		return -1
	return _state.ball_slot.get(ball_key, -1)


## The owned item occupying `slot_index`, or "" when that Kit slot is empty.
func get_ball_in_kit_slot(slot_index: int) -> String:
	for key: String in get_kit_items():
		if _state.ball_slot.get(key, -1) == slot_index:
			return key
	return ""


## Sets a ball to on court, starting its effects
func activate(ball_key: String) -> bool:
	if get_level(ball_key) <= 0:
		return false

	_set_item_placement(ball_key, Placement.ON_COURT)

	return true


## Moves an owned item back to the rack and unregisters its effects; false if unowned.
func deactivate(ball_key: String) -> bool:
	if get_level(ball_key) <= 0:
		return false

	_set_item_placement(ball_key, Placement.STORED)

	return true


## Moves an owned item into a specific Kit slot; false if unowned or the slot holds a different item.
func add_to_kit(ball_key: String, slot_index: int) -> bool:
	if get_level(ball_key) <= 0:
		return false
	var occupant: String = get_ball_in_kit_slot(slot_index)
	if occupant != "" and occupant != ball_key:
		return false

	_set_item_placement(ball_key, Placement.IN_KIT, Vector2.ZERO, slot_index)

	return true


## Moves an owned item from the Ball Kit back to the rack; false if unowned.
func remove_from_kit(ball_key: String) -> bool:
	if get_level(ball_key) <= 0:
		return false

	_set_item_placement(ball_key, Placement.STORED)

	return true


func calculate_for_purchase(ball_key: String) -> int:
	var item := get_item(ball_key)
	return int(item.base_cost * pow(2.0, get_owned_count(item.key)))


## Returns total cost of an item at its current level
func calculate_cost(ball_key: String) -> int:
	var item := get_item(ball_key)
	return int(item.base_cost * pow(item.cost_scaling, get_level(ball_key)))


## Returns true if the item is affordable. Used by drop targets.
func can_acquire(ball_key: String) -> bool:
	return economy.soul_balance >= calculate_for_purchase(ball_key)


## Returns whether the player can afford and has not maxed an item
func can_purchase(ball_key: String) -> bool:
	var item := get_item(ball_key)
	return economy.soul_balance >= calculate_cost(ball_key) and get_level(ball_key) < item.max_level


## Purchases an item if affordable, returns true on success
func purchase(ball_key: String) -> bool:
	if not can_purchase(ball_key):
		return false

	subtract_soul(calculate_cost(ball_key))
	var new_level := get_level(ball_key) + 1
	_state.ball_levels[ball_key] = new_level

	item_level_changed.emit(ball_key)
	state_changed.emit()
	SaveManager.save()

	return true


## Returns current soul balance.
func get_soul_balance() -> int:
	return economy.soul_balance


## Only earning path. Increments `total_soul_earned` so the shop unlock check stays correct across spending.
func add_soul(points: int) -> void:
	economy.soul_balance += points
	economy.total_soul_earned += points
	soul_balance_changed.emit(economy.soul_balance)


## Returns spent soul without crediting total soul earned.
## So a cancelled purchase does not affect progression.
func refund_soul(points: int) -> void:
	economy.soul_balance += points
	soul_balance_changed.emit(economy.soul_balance)


## Subtracts soul (clamped to zero).
func subtract_soul(points: int) -> void:
	economy.soul_balance = max(0, economy.soul_balance - points)
	soul_balance_changed.emit(economy.soul_balance)


func _register_existing_items() -> void:
	for key in _state.ball_levels:
		if _state.ball_levels[key] <= 0:
			continue
		var item := _get_item(key)
		if item == null:
			continue
		if not _state.ball_placement.has(key):
			mark_loose_in_venue(key)

		SaveManager.save()


## Deducts soul for purchasing a ball. The tracker owns instance key generation
## and _state registration; this only handles economics.
func take_ball(ball_key: String) -> bool:
	var item := _get_item(ball_key)
	if item == null:
		return false
	if economy.soul_balance < calculate_for_purchase(ball_key):
		return false
	subtract_soul(calculate_for_purchase(ball_key))
	SaveManager.save()
	return true


## Mints an instance for a ball whose price has already been paid, mote by mote,
## by the shop's hold-to-buy fill. Pay for it with `take_ball` first.
func take(ball_key: String) -> String:
	var item := _get_item(ball_key)

	if item == null:
		return ""

	var instance_key: String = generate_instance_key(ball_key)
	register_instance(instance_key)

	return instance_key


func _set_level(ball_key: String, level: int) -> void:
	_state.ball_levels[ball_key] = level
	item_level_changed.emit(ball_key)


## Sets `ball_key`'s placement, owning and clearing whichever payload field (slot/position) applies.
func _set_item_placement(
	ball_key: String, placement: int, venue_position: Vector2 = Vector2.ZERO, slot_index: int = -1
) -> void:
	var previous: int = _state.ball_placement.get(ball_key, -1)

	_state.ball_placement[ball_key] = placement
	_state.ball_venue_position.erase(ball_key)
	_state.ball_slot.erase(ball_key)

	if placement == Placement.STORED:
		_assign_rack_slot(ball_key)
	elif placement == Placement.IN_KIT:
		_state.ball_slot[ball_key] = slot_index
	elif placement == Placement.LOOSE_IN_VENUE:
		_state.ball_venue_position[ball_key] = venue_position

	state_changed.emit()

	if previous == placement:
		return

	item_placement_changed.emit(ball_key, placement)


func _base_key(ball_key: String) -> String:
	var base := BallKey.base_key(ball_key)
	if base == ball_key:
		return ball_key
	for item: BallDefinition in items:
		if item.key == base:
			return base
	return ball_key


func get_owned_count(base_key: String) -> int:
	var count := 0
	for key in _state.ball_levels:
		if BallKey.is_instance(base_key, key) and _state.ball_levels[key] > 0:
			count += 1
		elif key == base_key and _state.ball_levels[key] > 0:
			count += 1
	return count


func generate_instance_key(base_key: String) -> String:
	return BallKey.generate(base_key, _state.ball_levels)


func register_instance(ball_key: String) -> void:
	_state.ball_levels[ball_key] = 1
	mark_loose_in_venue(ball_key)
	SaveManager.save()


func adopt_instance(ball_key: String) -> void:
	_state.ball_levels[ball_key] = 1
	mark_loose_in_venue(ball_key)
	SaveManager.save()


func _get_item(ball_key: String) -> BallDefinition:
	var base_key := _base_key(ball_key)
	for item: BallDefinition in items:
		if item.key == base_key:
			return item
	push_warning("BallManager: unknown item key: %s" % ball_key)
	return null


## Same as `_get_item`, but asserts non-null; a miss here is a real bug, not an unowned item.
func get_item(ball_key: String) -> BallDefinition:
	var item := _get_item(ball_key)
	assert(item != null, "BallManager: expected a known item for key: %s" % ball_key)
	return item
