class_name SoulPurchaseHandler
extends Node

## Handles the visualisation of soul motes when purchasing from the shop.

signal purchase_completed

## Raised when the last refunded mote has reached the counter.
signal refunds_settled

const MOTE_SCENE: PackedScene = preload("res://scenes/effects/shop_soul_mote.tscn")

## Delay between each mote's spawn, so the price streams out rather than leaving all at once.
const SPAWN_INTERVAL := 0.04

## Where motes enter from; placed off screen so they never pop into view.
@export var spawn_point: Node2D

## Spread around the spawn point, so motes arrive as a stream rather than single file.
@export var spawn_spread := 600.0

## Speed purchase motes fly at; faster than a burst, since they are not showing off.
@export var mote_speed := 1200.0

var _target_catcher: SoulCatcher = null
var _outstanding_motes: int = 0
var _refunding: bool = false
var _spent: int = 0
var _purchase_generation: int = 0
var _refunding_motes: int = 0


## Begins draining `price` from the counter into `catcher`. One mote per denomination.
func begin_purchase(catcher: SoulCatcher, price: int) -> void:
	var values: Array[int] = SoulBurstMath.split(price)

	# A free item has no soul to move, so the purchase is already done.
	if values.is_empty():
		purchase_completed.emit()

		return

	_purchase_generation += 1
	_target_catcher = catcher
	_refunding = false
	_outstanding_motes = values.size()

	var generation: int = _purchase_generation

	for value in values:
		# A cancel resets the shared flags, so the loop tracks its own generation to
		# know it is stale; spawn against the parameter for the same reason.
		if generation != _purchase_generation or not is_inside_tree():
			return

		if not is_instance_valid(catcher):
			return

		_spawn_mote(value, _spawn_position(), catcher.global_position)

		await get_tree().create_timer(SPAWN_INTERVAL).timeout


## Sends back every soul taken so far, out from `origin`. Motes still streaming
## turn around where they are; whatever already landed leaves as fresh ones.
func refund(origin: Vector2) -> void:
	if _refunding:
		return

	_refunding = true
	# Retires the in-flight spawn loop, which outlives the flags that _reset clears.
	_purchase_generation += 1

	var owed: int = _spent

	for mote: ShopSoulMote in _live_motes():
		owed -= mote.soul_value

		_refunding_motes += 1

		mote.landed.connect(_on_refund_mote_landed)
		mote.fly_to(_spawn_position())

	_outstanding_motes = 0
	_spent = 0
	_target_catcher = null

	await _stream_refund(origin, owed)

	_refunding = false

	# Nothing was in flight to announce its own arrival, so settle immediately.
	if _refunding_motes == 0:
		refunds_settled.emit()


func is_purchasing() -> bool:
	return _outstanding_motes > 0


## Soul taken for the current purchase and not yet given back.
func spent() -> int:
	return _spent


## The ball reached a target, so the soul it cost is spent for good.
func settle_purchase() -> void:
	_spent = 0


## One mote per soul, each returning its own value to the counter as it leaves.
func _stream_refund(origin: Vector2, amount: int) -> void:
	if amount <= 0:
		return

	for value in SoulBurstMath.split(amount):
		if not is_inside_tree():
			return

		_refunding_motes += 1

		var mote: ShopSoulMote = _add_mote(value, origin)

		# Drawn under the ball, so the soul reads as coming out from behind it.
		mote.z_index = -1
		mote.landed.connect(_on_refund_mote_landed)
		mote.fly_to(_spawn_position())

		await get_tree().create_timer(SPAWN_INTERVAL).timeout


## Sends one soul from the counter to the ball, emptying the counter as it leaves.
func _spawn_mote(soul_value: int, from: Vector2, toward: Vector2) -> void:
	var mote: ShopSoulMote = _add_mote(soul_value, from)

	mote.landed.connect(_on_mote_landed)
	mote.fly_to(toward)

	BallManager.subtract_soul(soul_value)
	_spent += soul_value


## Puts a mote in the tree at `position`, ready for a caller to give it a flight.
func _add_mote(soul_value: int, position: Vector2) -> ShopSoulMote:
	var mote: ShopSoulMote = MOTE_SCENE.instantiate()
	mote.soul_value = soul_value
	mote.speed = mote_speed

	add_child(mote)
	mote.global_position = position

	return mote


func _live_motes() -> Array[ShopSoulMote]:
	var motes: Array[ShopSoulMote] = []

	for child: Node in get_children():
		var mote: ShopSoulMote = child as ShopSoulMote

		# A landed mote is freed at end of frame, so it is still a child here.
		if mote != null and not mote.is_queued_for_deletion():
			motes.append(mote)

	return motes


func _on_mote_landed(_soul_value: int) -> void:
	if _refunding:
		return

	_outstanding_motes -= 1

	if _outstanding_motes == 0:
		# `_spent` outlives the purchase, so a later refund knows what was taken.
		_outstanding_motes = 0
		_target_catcher = null
		# Arrival runs inside the physics flush, where spawning the ball cannot
		# touch collision state; hand completion to the next idle frame.
		purchase_completed.emit.call_deferred()


## Refunded soul lands back in the counter as the mote leaves the screen.
func _on_refund_mote_landed(soul_value: int) -> void:
	BallManager.refund_soul(soul_value)

	_refunding_motes -= 1

	if _refunding_motes == 0:
		refunds_settled.emit()


func _spawn_position() -> Vector2:
	var sideways := randf_range(-spawn_spread, spawn_spread) * 0.5

	return spawn_point.global_position + Vector2(sideways, 0.0)


func _reset() -> void:
	_outstanding_motes = 0
	_refunding = false
	_spent = 0
	_target_catcher = null
