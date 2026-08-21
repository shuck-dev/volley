class_name SoulFlight
extends Node2D

## One stream of soul between the counter and a catcher.
## Owns its motes and its own share of the ledger, so flights in opposite directions never touch.

## Raised once every mote of this flight has landed.
signal settled(flight: SoulFlight)

const MOTE_SCENE: PackedScene = preload("res://scenes/effects/shop_soul_mote.tscn")

## Delay between each mote's spawn, so the price streams rather than leaving at once.
const SPAWN_INTERVAL := 0.04

## Speed the flight's motes travel at.
var mote_speed := 1200.0

## Soul taken from the soul balance
var _spent: int = 0

var _in_flight: int = 0
var _spawning: bool = false
var _refunding: bool = false


## Whether soul is still in transit both on purchase and refund.
func is_active() -> bool:
	return _spawning or _in_flight > 0


## Streams `values` out to `catcher`, debiting each mote's soul as it leaves.
func drain(catcher: SoulCatcher, values: Array[int], origin: Callable) -> void:
	_spawning = true

	for value in values:
		if _refunding or not is_inside_tree() or not is_instance_valid(catcher):
			break

		var mote: ShopSoulMote = _add_mote(value, origin.call())

		mote.fly_to(catcher.global_position)

		BallManager.subtract_soul(value)
		_spent += value

		await get_tree().create_timer(SPAWN_INTERVAL).timeout

	# A refund took over the spawning, so leave the flag to it.
	if _refunding:
		return

	_spawning = false

	_settle_if_done()


## If purchase is canceled, refund the soul
func refund(origin: Vector2, home: Callable) -> void:
	_refunding = true

	var owed: int = _spent

	# Motes still outbound turn where they are, so only the landed soul needs new ones.
	for mote: ShopSoulMote in _motes():
		owed -= mote.soul_value

		mote.fly_to(home.call())

	_spent = 0

	_spawning = true

	for value in SoulBurstMath.split(owed):
		if not is_inside_tree():
			break

		var mote: ShopSoulMote = _add_mote(value, origin)

		# Drawn under the ball, so the soul reads as coming out from behind it.
		mote.z_index = -1
		mote.fly_to(home.call())

		await get_tree().create_timer(SPAWN_INTERVAL).timeout

	_spawning = false

	_settle_if_done()


## Motes of this flight still carrying soul.
func _motes() -> Array[ShopSoulMote]:
	var motes: Array[ShopSoulMote] = []

	for child: Node in get_children():
		var mote: ShopSoulMote = child as ShopSoulMote

		# A landed mote is freed at end of frame, so it is still a child here.
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
	# A refunding flight is paying soul back; an outbound one already spent it.
	if _refunding:
		BallManager.refund_soul(soul_value)

	_in_flight -= 1

	_settle_if_done()


func _settle_if_done() -> void:
	if is_active():
		return

	# Deferred so a flight that finished spawning synchronously still gets awaited.
	settled.emit.call_deferred(self)
