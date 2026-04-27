class_name BallReconciler
extends Node

## Live-ball lifecycle owner; spec lives in designs/01-prototype/21-ball-dynamics.md.

signal ball_spawned(item_key: String, ball: Ball)
## Emitted whenever a ball enters the tracked set (spawn, ensure, adoption).
signal ball_added(ball: Ball)
## Emitted whenever a ball leaves the tracked set (release, deactivate).
signal ball_removed(ball: Ball)

const BallScene: PackedScene = preload("res://scenes/ball.tscn")

@export var ball_scene: PackedScene = BallScene

var _item_manager: Node
var _ball_host: Node
var _balls_by_key: Dictionary = {}
var _initial_reconcile_pending: bool = true


func configure(item_manager: Node, ball_host: Node) -> void:
	_item_manager = item_manager
	_ball_host = ball_host


func _ready() -> void:
	if _item_manager == null:
		_item_manager = ItemManager
	if _ball_host == null:
		_ball_host = get_parent()

	_item_manager.court_changed.connect(_on_court_changed)

	# Deferred so sibling listeners connect to ball_spawned before we emit.
	call_deferred(&"adopt_pre_existing_balls")
	call_deferred(&"_reconcile_initial_state")


## Registers each authored Ball under its `item_key`, applies item art, and ensures
## placement reflects "this ball is on court" so the rack hides the matching token.
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
		if ball.item_key == "":
			push_warning("BallReconciler: skipping adoption of authored Ball with no item_key")
			continue
		var key: String = ball.item_key
		_balls_by_key[key] = ball
		_apply_item_art(ball, key)
		# Authored ball needs level >= 1 and ON_COURT so the rack hides its token.
		if _item_manager.has_method("adopt_authored"):
			_item_manager.adopt_authored(key)
		elif (
			_item_manager.has_method("activate")
			and _item_manager.get_level(key) > 0
			and not _item_manager.is_on_court(key)
		):
			_item_manager.activate(key)
		ball_spawned.emit(key, ball)
		ball_added.emit(ball)


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


## Returns the tracked Ball for `item_key` or instantiates one; `preserved_speed` >= 0 carries friendship energy through grab-and-release.
func ensure_ball_for_key(
	item_key: String,
	spawn_position: Vector2,
	initial_velocity: Vector2,
	preserved_speed: float = -1.0,
) -> Ball:
	var existing: Ball = get_ball_for_key(item_key)
	if existing != null:
		existing.global_position = spawn_position
		existing.linear_velocity = initial_velocity
		_apply_preserved_speed(existing, preserved_speed)
		return existing

	var ball: Ball = ball_scene.instantiate()
	_ball_host.add_child(ball)
	ball.global_position = spawn_position
	ball.linear_velocity = initial_velocity
	_apply_item_art(ball, item_key)
	_balls_by_key[item_key] = ball
	ball_spawned.emit(item_key, ball)
	ball_added.emit(ball)
	_apply_preserved_speed(ball, preserved_speed)
	return ball


## Activates the item if needed, then ensures a single Ball at `spawn_position` with `initial_velocity`.
func bring_into_play(
	item_key: String,
	spawn_position: Vector2,
	initial_velocity: Vector2,
	preserved_speed: float = -1.0,
) -> Ball:
	if not _item_manager.is_on_court(item_key):
		_item_manager.activate(item_key)
	return ensure_ball_for_key(item_key, spawn_position, initial_velocity, preserved_speed)


## SH-288: friendship energy persists across grab-and-release. When `preserved_speed` is non-negative,
## the ball adopts that speed and re-magnitudes its velocity along the requested direction.
func _apply_preserved_speed(ball: Ball, preserved_speed: float) -> void:
	if preserved_speed < 0.0:
		return
	ball.speed = preserved_speed
	if ball.linear_velocity.length() > 0.0:
		ball.linear_velocity = ball.linear_velocity.normalized() * preserved_speed


func release_ball(item_key: String) -> Ball:
	var ball: Ball = get_ball_for_key(item_key)
	if ball == null:
		return null

	_initial_reconcile_pending = false
	_balls_by_key.erase(item_key)
	ball_removed.emit(ball)
	return ball


func _on_court_changed(item_key: String, on_court: bool) -> void:
	_initial_reconcile_pending = false
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
	ball_removed.emit(ball)
	ball.call_deferred("queue_free")


## One-shot recovery for saved-on-court keys without an authored Ball child.
## Skipped once any signal-driven activity has begun.
func _reconcile_initial_state() -> void:
	if not _initial_reconcile_pending:
		return
	_initial_reconcile_pending = false
	for key in _item_manager.get_court_items():
		if get_ball_for_key(key) == null:
			ensure_ball_for_key(
				key, _default_spawn_position(), _item_manager.get_default_ball_launch_velocity()
			)


func _default_spawn_position() -> Vector2:
	if _ball_host is Node2D:
		return (_ball_host as Node2D).global_position
	return Vector2.ZERO


## Swaps the art into the authored ItemArtHolder slot on Ball; idempotent across re-applications.
func _apply_item_art(ball: Ball, item_key: String) -> void:
	var definition: ItemDefinition = _get_item_definition(item_key)
	if definition == null or definition.art == null:
		return
	var holder: Node2D = ball.get_node_or_null("ItemArtHolder") as Node2D
	if holder == null:
		push_warning("BallReconciler: ball.tscn missing ItemArtHolder slot; skipping art swap")
		return
	for child in holder.get_children():
		holder.remove_child(child)
		child.queue_free()
	holder.scale = definition.token_scale
	holder.add_child(definition.art.instantiate())
	var default_sprite: Node = ball.get_node_or_null("Sprite")
	if default_sprite != null:
		default_sprite.visible = false


func _get_item_definition(item_key: String) -> ItemDefinition:
	for item: ItemDefinition in _item_manager.items:
		if item.key == item_key:
			return item
	return null
