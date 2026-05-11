class_name BallReconciler
extends Node

## Live-ball lifecycle owner; spec lives in designs/01-prototype/tech/02-ball-lifecycle.md.

signal ball_spawned(item_key: String, ball: Ball)
## Emitted whenever a ball enters the tracked set (spawn, ensure, adoption).
signal ball_added(ball: Ball)
## Emitted whenever a ball leaves the tracked set (release, deactivate).
signal ball_removed(ball: Ball)

const BallScene: PackedScene = preload("res://scenes/ball.tscn")
const PRESERVED_SPEED_NONE: float = -1.0

@export var ball_scene: PackedScene = BallScene

var _item_manager: Node
var _balls_by_key: Dictionary = {}
var _initial_reconcile_pending: bool = true
## Prevents court_changed from clearing _initial_reconcile_pending before _reconcile_initial_state runs.
var _adopting_pre_existing: bool = false


# Deprecated ball_host arg ignored; reconciler parents its own balls. Retired in step 6 of the lifecycle refactor.
func configure(item_manager: Node, _ball_host: Node = null) -> void:
	_item_manager = item_manager


# Compatibility shim for callers still enumerating loose bodies via the legacy host indirection. Retired in step 6.
func get_ball_host() -> Node:
	return self


func _ready() -> void:
	if _item_manager == null:
		_item_manager = ItemManager

	_item_manager.court_changed.connect(_on_court_changed)

	# Position persistence: SaveManager pulls live positions from us before each
	# disk write so balls reload where the player left them, not the spawn marker.
	if _has_save_manager_autoload():
		SaveManager.set_position_provider(collect_item_positions)

	# Deferred so sibling listeners connect to ball_spawned before we emit.
	call_deferred(&"adopt_pre_existing_balls")
	call_deferred(&"_reconcile_initial_state")


func _has_save_manager_autoload() -> bool:
	# Tests instantiate BallReconciler without the full autoload graph; guard
	# the wiring so unit tests do not crash on missing SaveManager.
	return get_tree() != null and get_tree().root.has_node("SaveManager")


## Snapshot of live ball positions keyed by item_key. Every loose / at-rest / in-play
## ball lives in the registry post-step-5, so the registry walk is the whole story.
func collect_item_positions() -> Dictionary[String, Vector2]:
	var positions: Dictionary[String, Vector2] = {}
	for key: String in _balls_by_key:
		var raw: Variant = _balls_by_key[key]
		if not is_instance_valid(raw):
			continue
		var ball: Ball = raw
		positions[key] = ball.global_position
	return positions


## Idempotent; safe to call repeatedly across scene reloads. Authored Balls live as
## siblings of the reconciler in the scene tree, so scan the parent here.
func adopt_pre_existing_balls() -> void:
	var parent: Node = get_parent()
	if parent == null:
		return
	_adopting_pre_existing = true
	for child in parent.get_children():
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
	_adopting_pre_existing = false


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


## Returns the tracked Ball for `item_key` or instantiates one; `preserved_speed` >= 0 carries rally speed through grab-and-release.
func ensure_ball_for_key(
	item_key: String,
	spawn_position: Vector2,
	initial_velocity: Vector2,
	preserved_speed: float = PRESERVED_SPEED_NONE,
) -> Ball:
	var existing: Ball = get_ball_for_key(item_key)
	if existing != null:
		existing.global_position = spawn_position
		existing.linear_velocity = initial_velocity
		_apply_preserved_speed(existing, preserved_speed)
		return existing

	var ball: Ball = ball_scene.instantiate()
	add_child(ball)
	ball.global_position = spawn_position
	ball.linear_velocity = initial_velocity
	_apply_item_art(ball, item_key)
	_balls_by_key[item_key] = ball
	ball_spawned.emit(item_key, ball)
	ball_added.emit(ball)
	_apply_preserved_speed(ball, preserved_speed)
	return ball


## Step 5: venue-floor release path. Ensures a registry Ball at `position`, in OUT_REST,
## carrying `velocity`. Does not touch ItemManager state; callers flip loose-in-venue / on-court
## overlays as appropriate so the rack filters render the right slots.
func release_into_rest(item_key: String, position: Vector2, velocity: Vector2) -> Ball:
	var ball: Ball = get_ball_for_key(item_key)
	if ball == null:
		ball = ball_scene.instantiate()
		add_child(ball)
		_apply_item_art(ball, item_key)
		_balls_by_key[item_key] = ball
		ball_spawned.emit(item_key, ball)
		ball_added.emit(ball)
	ball.global_position = position
	ball.enter_out_rest()
	ball.linear_velocity = velocity
	return ball


## Activates the item if needed, then ensures a single Ball at `spawn_position` with `initial_velocity`.
func bring_into_play(
	item_key: String,
	spawn_position: Vector2,
	initial_velocity: Vector2,
	preserved_speed: float = PRESERVED_SPEED_NONE,
) -> Ball:
	if not _item_manager.is_on_court(item_key):
		_item_manager.activate(item_key)
	return ensure_ball_for_key(item_key, spawn_position, initial_velocity, preserved_speed)


## Negative sentinel means no preserved energy; negative check avoids zero-speed edge case.
func _apply_preserved_speed(ball: Ball, preserved_speed: float) -> void:
	if preserved_speed < 0.0:
		return
	ball.speed = preserved_speed
	# Re-sync the effect processor's base so the next physics frame's speed-limit clamp
	# does not snap us back to ball_speed_min.
	if ball.effect_processor != null:
		ball.effect_processor.sync_base_speed()
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
	if not _adopting_pre_existing:
		_initial_reconcile_pending = false
	if on_court:
		if get_ball_for_key(item_key) != null:
			return
		ensure_ball_for_key(
			item_key,
			_spawn_position_for(item_key),
			_item_manager.get_default_ball_launch_velocity(),
		)
		return

	var ball: Ball = get_ball_for_key(item_key)
	if ball == null:
		return

	_balls_by_key.erase(item_key)
	ball_removed.emit(ball)
	ball.call_deferred("queue_free")


## One-shot: skipped once any signal-driven court_changed activity has begun.
func _reconcile_initial_state() -> void:
	if not _initial_reconcile_pending:
		return
	_initial_reconcile_pending = false
	for key in _item_manager.get_court_items():
		if get_ball_for_key(key) == null:
			ensure_ball_for_key(
				key,
				_spawn_position_for(key),
				_item_manager.get_default_ball_launch_velocity(),
			)


func _default_spawn_position() -> Vector2:
	var parent: Node = get_parent()
	if parent is Node2D:
		return (parent as Node2D).global_position
	return Vector2.ZERO


## Prefer the saved position so reloaded balls keep their last in-play spot.
## Falls back to the default spawn when no save data exists for the key.
func _spawn_position_for(item_key: String) -> Vector2:
	if not _has_save_manager_autoload():
		return _default_spawn_position()
	var progression: ProgressionData = SaveManager.get_progression_data()
	if progression != null and progression.item_positions.has(item_key):
		return progression.item_positions[item_key]
	return _default_spawn_position()


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
