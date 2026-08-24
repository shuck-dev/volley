class_name SoulPurchaseHandler
extends Node

## Handles the visualisation of soul motes when purchasing from the shop.

signal purchase_completed

## Where motes enter from; placed off screen so they never pop into view.
@export var spawn_point: Node2D

## Spread around the spawn point, so motes arrive as a stream rather than single file.
@export var spawn_spread := 600.0

## Speed purchase motes fly at; faster than a burst, since they are not showing off.
@export var mote_speed := 1800.0

## The flight carrying soul out to a catcher; refunding ones live on as children.
var _purchase: SoulFlight = null


## Drains price from the counter into catcher. One mote per denomination.
func drain_soul_purchase(catcher: SoulCatcher, price: int) -> void:
	# One purchase at a time: a second drain would orphan the flight paying for the first.
	if _purchase != null:
		return

	var values: Array[int] = SoulMath.split(price)

	# A free item has no soul to move, so the purchase is already done.
	if values.is_empty():
		purchase_completed.emit()

		return

	_purchase = _add_flight()

	_purchase.drain(catcher, values, _spawn_position)


## Sends back every soul taken before a complete purchase.
func refund(origin: Vector2) -> void:
	if _purchase == null:
		return

	var flight: SoulFlight = _purchase

	_purchase = null

	flight.refund(origin, _spawn_position)

	if flight.is_active():
		await flight.settled


## The ball reached a target, so the soul it cost is spent and its flight is done.
func settle_purchase() -> void:
	if _purchase != null:
		_purchase.queue_free()

	_purchase = null


func _add_flight() -> SoulFlight:
	var flight := SoulFlight.new()
	flight.mote_speed = mote_speed

	add_child(flight)
	flight.settled.connect(_on_flight_settled)

	return flight


func _on_flight_settled(flight: SoulFlight) -> void:
	if flight == _purchase:
		purchase_completed.emit()

		return

	flight.queue_free()


func _spawn_position() -> Vector2:
	var sideways := randf_range(-spawn_spread, spawn_spread) * 0.5

	return spawn_point.global_position + Vector2(sideways, 0.0)
