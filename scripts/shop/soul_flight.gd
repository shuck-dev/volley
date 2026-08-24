class_name SoulFlight
extends Node2D

## One stream of soul between the spawn point and a catcher.
## Owns its motes and the state of a purchase.

## Raised once every mote of this flight has landed.
signal settled(flight: SoulFlight)

## The state of a soul flight depending on if player is still purchasing.
enum State { DRAINING, REFUNDING, SETTLED }

const MOTE_SCENE: PackedScene = preload("res://scenes/effects/shop_soul_mote.tscn")

const SPAWN_WINDOW := 0.5

var mote_speed := 1800.0
var _state: State = State.DRAINING
var _spent: int = 0
var _in_flight: int = 0

## Motes still waiting to be released, and the schedule releasing them.
var _queue: Array[int] = []
var _queue_size: int = 0
var _elapsed: float = 0.0

var _spawn_position: Callable
var _item_position: Vector2


func _enter_tree() -> void:
	SaveManager.lock_save()


func _exit_tree() -> void:
	_settle()


## Whether soul is still in transit both on purchase and refund.
func is_active() -> bool:
	return not _queue.is_empty() or _in_flight > 0


## Streams `values` out to `catcher`, debiting each mote's soul as it leaves.
func drain(catcher: SoulCatcher, values: Array[int], spawn_position: Callable) -> void:
	_spawn_position = spawn_position
	_item_position = catcher.global_position

	_queue_release(values)


## Sends back every soul this flight has taken.
func refund(item: Vector2, spawn_position: Callable) -> void:
	if _state == State.SETTLED:
		SaveManager.lock_save()

	_state = State.REFUNDING

	var owed: int = _spent

	for mote: ShopSoulMote in _motes():
		owed -= mote.soul_value

		mote.fly_to(spawn_position.call())

	_spent = 0

	_spawn_position = spawn_position
	_item_position = item

	_queue_release(SoulMath.split(owed))


func _process(delta: float) -> void:
	if _queue.is_empty():
		return

	_elapsed += delta

	while _queue.size() > _owed():
		_release_next()

	if _queue.is_empty():
		_settle_if_done()


## Motes the schedule says should be released.
func _owed() -> int:
	if SPAWN_WINDOW <= 0.0:
		return 0

	var elapsed_fraction: float = minf(_elapsed / SPAWN_WINDOW, 1.0)

	return _queue_size - ceili(elapsed_fraction * _queue_size)


func _release_next() -> void:
	var value: int = _queue.pop_front()

	if _state == State.REFUNDING:
		var returning: ShopSoulMote = _add_mote(value, _item_position)
		returning.z_index = -1
		returning.fly_to(_spawn_position.call())

		return

	var leaving: ShopSoulMote = _add_mote(value, _spawn_position.call())

	leaving.fly_to(_item_position)

	BallManager.subtract_soul(value)
	_spent += value


func _queue_release(values: Array[int]) -> void:
	_queue = values.duplicate()
	_queue_size = _queue.size()
	_elapsed = 0.0

	if _queue.is_empty():
		_settle_if_done()


## Motes of this flight still carrying soul.
func _motes() -> Array[ShopSoulMote]:
	var motes: Array[ShopSoulMote] = []

	for child: Node in get_children():
		var mote: ShopSoulMote = child as ShopSoulMote

		if mote != null and not mote.is_queued_for_deletion():
			motes.append(mote)

	return motes


func _add_mote(soul_value: int, mote_position: Vector2) -> ShopSoulMote:
	var mote: ShopSoulMote = MOTE_SCENE.instantiate()
	mote.soul_value = soul_value
	mote.speed = mote_speed

	add_child(mote)
	mote.global_position = mote_position
	mote.landed.connect(_on_mote_landed)

	_in_flight += 1

	return mote


func _on_mote_landed(soul_value: int) -> void:
	if _state == State.REFUNDING:
		BallManager.refund_soul(soul_value)

	_in_flight -= 1

	_settle_if_done()


func _settle_if_done() -> void:
	if is_active():
		return

	_settle()

	# Deferred so a flight that finished spawning synchronously still gets awaited.
	settled.emit.call_deferred(self)


## Balances the books: lets the save resume, then writes what this flight moved.
func _settle() -> void:
	if _state == State.SETTLED:
		return

	_state = State.SETTLED

	SaveManager.unlock_save()
	SaveManager.save()
