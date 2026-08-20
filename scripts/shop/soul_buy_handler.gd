class_name SoulBuyHandler
extends Node

## Streams the purchase price out of the soul counter and into the held ball.
## The counter ticks down as each mote leaves and back up as a refunded one
## departs, so the number always tracks soul that is visibly in flight.

signal buy_completed

const MOTE_SCENE: PackedScene = preload("res://scenes/effects/soul_mote.tscn")

## Delay between each mote's spawn, so the price streams out rather than leaving all at once.
const SPAWN_INTERVAL := 0.04

## Where motes enter from; placed off screen so they never pop into view.
@export var spawn_point: Node2D

## Spread around the spawn point, so motes arrive as a stream rather than single file.
@export var spawn_spread := 600.0

## Speed purchase motes fly at; faster than a burst, since they are not showing off.
@export var mote_speed := 1200.0

## Cone the refund fans across as it leaves the ball, before curving to the counter.
@export var refund_cone_degrees := 90.0

var _target_catcher: SoulCatcher = null
var _outstanding_motes: int = 0
var _refunding: bool = false
var _spent: int = 0
var _buy_generation: int = 0


## Begins draining `price` from the counter into `catcher`. One mote per denomination.
func begin_buy(catcher: SoulCatcher, price: int) -> void:
	var values: Array[int] = SoulBurstMath.split(price)

	# A free item has no soul to move, so the purchase is already done.
	if values.is_empty():
		buy_completed.emit()

		return

	_buy_generation += 1
	_target_catcher = catcher
	_refunding = false
	_outstanding_motes = values.size()

	var generation: int = _buy_generation

	for value in values:
		# A cancel resets the shared flags, so the loop tracks its own generation to
		# know it is stale; spawn against the parameter for the same reason.
		if generation != _buy_generation or not is_inside_tree():
			return

		if not is_instance_valid(catcher):
			return

		_spawn_mote(value, _spawn_position(), catcher)

		await get_tree().create_timer(SPAWN_INTERVAL).timeout


## Sends every soul taken so far back out, as motes that credit once they leave.
func cancel_buy() -> void:
	if _refunding or _outstanding_motes == 0:
		return

	_refunding = true
	# Retires the in-flight spawn loop, which outlives the flags that _reset clears.
	_buy_generation += 1

	var owed: int = _spent

	# Motes still in flight carry their soul back out themselves; the rest was
	# collected by motes already freed, so it needs fresh ones to carry it.
	for mote: SoulMote in _live_motes():
		owed -= mote.soul_value

		mote.departed.connect(_on_refund_mote_departed)
		mote.send_home(_spawn_position())

	if is_instance_valid(_target_catcher):
		refund_from(_target_catcher.global_position, owed)

	_reset()


## Streams `amount` back out from `origin`, one mote per soul, each returning its
## own value to the counter as it leaves.
func refund_from(origin: Vector2, amount: int) -> void:
	if amount <= 0:
		return

	for value in SoulBurstMath.split(amount):
		if not is_inside_tree():
			return

		var mote: SoulMote = MOTE_SCENE.instantiate()
		mote.soul_value = value
		mote.drifts_before_homing = false
		mote.attract_speed = mote_speed
		mote.departed.connect(_on_refund_mote_departed)
		# Drawn under the ball, so the soul reads as coming out from behind it.
		mote.z_index = -1
		add_child(mote)
		mote.global_position = origin
		mote.send_home(_spawn_position(), deg_to_rad(refund_cone_degrees))

		await get_tree().create_timer(SPAWN_INTERVAL).timeout


func is_buying() -> bool:
	return _outstanding_motes > 0


func _spawn_mote(soul_value: int, from: Vector2, toward: Node2D) -> void:
	var mote: SoulMote = MOTE_SCENE.instantiate()
	mote.soul_value = soul_value
	mote.target = toward
	mote.initial_heading = (toward.global_position - from).normalized()
	# Purchase motes head straight for the ball; the burst drift is a payout flourish.
	mote.drifts_before_homing = false
	mote.attract_speed = mote_speed
	mote.arrived.connect(_on_mote_arrived)
	add_child(mote)
	mote.global_position = from

	# The counter empties as the soul leaves it, not when it reaches the ball.
	BallManager.subtract_soul(soul_value)
	_spent += soul_value


func _live_motes() -> Array[SoulMote]:
	var motes: Array[SoulMote] = []

	for child: Node in get_children():
		var mote: SoulMote = child as SoulMote

		# A landed mote is freed at end of frame, so it is still a child here.
		if mote != null and not mote.is_queued_for_deletion():
			motes.append(mote)

	return motes


func _on_mote_arrived(_soul_value: int) -> void:
	if _refunding:
		return

	_outstanding_motes -= 1

	if _outstanding_motes == 0:
		_reset()
		# Arrival runs inside the physics flush, where spawning the ball cannot
		# touch collision state; hand completion to the next idle frame.
		buy_completed.emit.call_deferred()


## Refunded soul lands back in the counter as the mote leaves the screen.
func _on_refund_mote_departed(soul_value: int) -> void:
	BallManager.refund_soul(soul_value)


func _spawn_position() -> Vector2:
	var sideways := randf_range(-spawn_spread, spawn_spread) * 0.5

	return spawn_point.global_position + Vector2(sideways, 0.0)


func _reset() -> void:
	_outstanding_motes = 0
	_refunding = false
	_spent = 0
	_target_catcher = null
