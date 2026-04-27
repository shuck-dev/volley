class_name BallReconciler
extends Node

## Single ownership point for live Ball instances. Drives lifecycle (spawn, art, freeing)
## from `on_court[&ball]` and exposes `current_ball` so callers don't reach into the scene.

signal ball_spawned(item_key: String, ball: Ball)
signal current_ball_changed(ball: Ball)

const BallScene: PackedScene = preload("res://scenes/ball.tscn")

@export var ball_scene: PackedScene = BallScene
@export var spawn_for_existing_on_load: bool = false

var current_ball: Ball = null

var _item_manager: Node
var _ball_host: Node
var _balls_by_key: Dictionary = {}


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
		# Activating fires court_changed, which sees the ball already tracked and is a no-op for spawning.
		# The placement flip is what lets the rack hide the token the player already sees in play.
		if (
			_item_manager.has_method("activate")
			and _item_manager.get_level(key) > 0
			and not _item_manager.is_on_court(key)
		):
			_item_manager.activate(key)
		ball_spawned.emit(key, ball)
		_set_current_ball(ball)


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
	_set_current_ball(ball)
	return ball


## Single entry point for placing a permanent ball on the court: activates the item if needed,
## ensures one Ball at the position with the velocity, applies art. Replaces a stack of
## activate-then-spawn sequences elsewhere.
func bring_into_play(item_key: String, spawn_position: Vector2, initial_velocity: Vector2) -> Ball:
	if not _item_manager.is_on_court(item_key):
		_item_manager.activate(item_key)
	return ensure_ball_for_key(item_key, spawn_position, initial_velocity)


func release_ball(item_key: String) -> Ball:
	var ball: Ball = get_ball_for_key(item_key)
	if ball == null:
		return null

	_balls_by_key.erase(item_key)
	if current_ball == ball:
		_set_current_ball(_pick_current_candidate())
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
	if current_ball == ball:
		_set_current_ball(_pick_current_candidate())
	ball.call_deferred("queue_free")


func _set_current_ball(ball: Ball) -> void:
	if current_ball == ball:
		return
	current_ball = ball
	current_ball_changed.emit(ball)


func _pick_current_candidate() -> Ball:
	for value in _balls_by_key.values():
		if is_instance_valid(value):
			return value
	return null


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


## Owns the art holder lifecycle on a Ball: frees any previous holder, instantiates the
## item's authored art, hides the default sprite. Idempotent across re-applications.
func _apply_item_art(ball: Ball, item_key: String) -> void:
	var definition: ItemDefinition = _get_item_definition(item_key)
	if definition == null or definition.art == null:
		return
	var existing: Node = ball.get_node_or_null("ItemArtHolder")
	if existing != null:
		existing.queue_free()
	var holder: Node2D = Node2D.new()
	holder.name = "ItemArtHolder"
	holder.scale = definition.token_scale
	holder.add_child(definition.art.instantiate())
	ball.add_child(holder)
	var default_sprite: Node = ball.get_node_or_null("Sprite")
	if default_sprite != null:
		default_sprite.visible = false


func _get_item_definition(item_key: String) -> ItemDefinition:
	for item: ItemDefinition in _item_manager.items:
		if item.key == item_key:
			return item
	return null
