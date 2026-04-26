class_name BallReconciler
extends Node

## Owns live Ball instances for permanent on-court ball items.

signal ball_spawned(item_key: String, ball: Ball)

const BallScene: PackedScene = preload("res://scenes/ball.tscn")
## Synthetic key prefix for scene-authored Balls adopted post-load so drag wiring covers them too (SH-262).
const ADOPTED_BALL_KEY_PREFIX: String = "__adopted_ball_"

@export var ball_scene: PackedScene = BallScene
@export var spawn_for_existing_on_load: bool = false

var _item_manager: Node
var _ball_host: Node
var _balls_by_key: Dictionary = {}
var _adopted_ball_counter: int = 0


func configure(item_manager: Node, ball_host: Node) -> void:
	_item_manager = item_manager
	_ball_host = ball_host


func _ready() -> void:
	if _item_manager == null:
		_item_manager = ItemManager
	if _ball_host == null:
		_ball_host = get_parent()

	_item_manager.court_changed.connect(_on_court_changed)

	if spawn_for_existing_on_load:
		_reconcile_initial_state()

	# Deferred so sibling listeners connect to ball_spawned before we emit for adopted balls.
	call_deferred(&"adopt_pre_existing_balls")


## Scans `_ball_host` for Ball instances not yet tracked and registers each
## under its authored item_key (or a synthetic key as a fallback), emitting
## ball_spawned so listeners (drag controller) wire their per-ball connections.
## Idempotent; safe to call repeatedly.
func adopt_pre_existing_balls() -> void:
	if _ball_host == null:
		return
	for child in _ball_host.get_children():
		if not (child is Ball):
			continue
		var ball: Ball = child
		if ball.is_temporary:
			continue
		if ball.is_queued_for_deletion():
			continue
		if _is_tracked(ball):
			continue
		# Skip if a listener has already wired Ball.pressed; re-emitting would double-connect.
		if ball.pressed.get_connections().size() > 0:
			continue
		var key: String
		if ball.item_key != "":
			key = ball.item_key
		else:
			key = "%s%d" % [ADOPTED_BALL_KEY_PREFIX, _adopted_ball_counter]
			_adopted_ball_counter += 1
		_balls_by_key[key] = ball
		# Apply the item's authored art so the held token (and the live ball) render with the canonical visual.
		_apply_item_art(ball, key)
		# Mark a known-item adopted ball as on-court so the rack hides the item the player already sees in play.
		# Without this the rack offers the same key, and a rack-to-court drag would teleport the existing ball instead of spawning a new one.
		if ball.item_key != "" and _item_manager.has_method("activate"):
			if _item_manager.get_level(key) > 0 and not _item_manager.is_on_court(key):
				_item_manager.activate(key)
		ball_spawned.emit(key, ball)


func _is_tracked(ball: Ball) -> bool:
	for tracked in _balls_by_key.values():
		if tracked == ball:
			return true
	return false


func get_ball_for_key(item_key: String) -> Ball:
	if not _balls_by_key.has(item_key):
		return null

	var raw: Variant = _balls_by_key[item_key]
	if not is_instance_valid(raw):
		_balls_by_key.erase(item_key)
		return null
	return raw


## Returns the tracked Ball for `item_key`, repositioning and relaunching it, or instantiates a new one if none is tracked.
func ensure_ball_for_key(
	item_key: String, spawn_position: Vector2, initial_velocity: Vector2
) -> Ball:
	var existing: Ball = get_ball_for_key(item_key)
	if existing != null:
		existing.global_position = spawn_position
		existing.linear_velocity = initial_velocity
		return existing

	var ball: Ball = ball_scene.instantiate()
	_ball_host.add_child(ball)
	ball.global_position = spawn_position
	ball.linear_velocity = initial_velocity
	_apply_item_art(ball, item_key)
	_balls_by_key[item_key] = ball
	ball_spawned.emit(item_key, ball)
	return ball


func release_ball(item_key: String) -> Ball:
	var ball: Ball = get_ball_for_key(item_key)
	if ball == null:
		return null

	_balls_by_key.erase(item_key)
	return ball


func _on_court_changed(item_key: String, on_court: bool) -> void:
	if on_court:
		if get_ball_for_key(item_key) != null:
			return
		ensure_ball_for_key(
			item_key, _default_spawn_position(), _item_manager.get_default_ball_launch_velocity()
		)
		return

	var ball: Ball = get_ball_for_key(item_key)
	if ball == null:
		return

	_balls_by_key.erase(item_key)
	ball.call_deferred("queue_free")


func _reconcile_initial_state() -> void:
	for key in _item_manager.get_court_items():
		if get_ball_for_key(key) == null:
			ensure_ball_for_key(
				key, _default_spawn_position(), _item_manager.get_default_ball_launch_velocity()
			)


func _default_spawn_position() -> Vector2:
	if _ball_host is Node2D:
		return (_ball_host as Node2D).global_position
	return Vector2.ZERO


func _apply_item_art(ball: Ball, item_key: String) -> void:
	var definition: ItemDefinition = _get_item_definition(item_key)
	if definition == null or definition.art == null:
		return
	ball.apply_item_art(definition.art, definition.token_scale)


func _get_item_definition(item_key: String) -> ItemDefinition:
	for item: ItemDefinition in _item_manager.items:
		if item.key == item_key:
			return item
	return null
