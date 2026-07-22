class_name BallReconciler
extends Node

## Live-ball lifecycle owner.

signal ball_spawned(item_key: String, ball: Ball)

## Emitted whenever a ball enters the tracked set (spawn, ensure, adoption).
signal ball_added(ball: Ball)

## Emitted whenever a ball leaves the tracked set (release, deactivate).
signal ball_removed(ball: Ball)
signal ball_missed(ball: Ball)

## Fires on final-consolidation entry (true) and exit (false), re-emitted from the live ball.
signal ball_final_consolidation_changed(in_final: bool)

## Fires when any tracked ball crosses a tier ceiling, carrying the ball and its new tier.
signal ball_tier_advanced(ball: Ball, new_tier: int)

signal current_ball_changed(ball: Ball)

const BallScene: PackedScene = preload("res://scenes/ball.tscn")
const PRESERVED_SPEED_NONE: float = -1.0

@export var ball_scene: PackedScene = BallScene

## Ball-role rack consulted for STORED slot positions during initial kit-walk and deactivate transitions.
@export var ball_rack: RackDisplay

@export var spawn_origin: Vector2 = Vector2.ZERO
@export var court_config: CourtConfig
@export var player_paddle: Node2D

var bound_y: float = 0.0

var _item_manager: ItemManager
var _balls_by_key: Dictionary = {}
var _initial_reconcile_pending: bool = true

var _balls: Array[Ball] = []
var _current_ball: Ball
var _miss_zones: Array[MissZone] = []


func configure(item_manager: Node) -> void:
	_item_manager = item_manager


func _ready() -> void:
	add_to_group(&"ball_trackers")

	if _item_manager == null:
		_item_manager = ItemManager

	_item_manager.court_changed.connect(_on_court_changed)
	_item_manager.item_manager_state_changed.connect(_reconcile)

	# Position persistence: SaveManager pulls live positions from us before each
	# disk write so balls reload where the player left them, not the spawn marker.
	if _has_save_manager_autoload():
		SaveManager.set_position_provider(collect_item_positions)
		SaveManager.set_play_state_provider(collect_ball_play_states)

	# Deferred so sibling listeners connect before we emit.
	call_deferred(&"_reconcile")


func _has_save_manager_autoload() -> bool:
	return get_tree() != null and get_tree().root.has_node("SaveManager")


## Snapshot of live ball positions keyed by item_key.
func collect_item_positions() -> Dictionary[String, Vector2]:
	var positions: Dictionary[String, Vector2] = {}
	for ball in _balls:
		if not is_instance_valid(ball):
			continue

		if ball.play_state == Ball.PlayState.STORED:
			continue

		if ball.item_key.is_empty():
			continue

		positions[ball.item_key] = ball.global_position

	return positions


## Snapshot of live ball PlayState enums keyed by item_key.
func collect_ball_play_states() -> Dictionary[String, int]:
	var states: Dictionary[String, int] = {}
	for ball in _balls:
		if not is_instance_valid(ball):
			continue
		if ball.play_state == Ball.PlayState.STORED:
			continue
		if ball.item_key.is_empty():
			continue
		states[ball.item_key] = int(ball.play_state)
	return states


## True when any tracked ball is in PLAY_NORMAL or PLAY_ARC; drives the rally-in-progress gate.
func has_ball_in_play() -> bool:
	for raw: Variant in _balls_by_key.values():
		if not is_instance_valid(raw):
			continue
		var ball: Ball = raw
		if (
			ball.play_state == Ball.PlayState.PLAY_NORMAL
			or ball.play_state == Ball.PlayState.PLAY_ARC
		):
			return true
	return false


## Returns the tracked Ball for `item_key` and instances.
func get_ball_for_key(item_key: String) -> Ball:
	if _balls_by_key.has(item_key):
		var raw: Variant = _balls_by_key[item_key]
		if is_instance_valid(raw):
			return raw
		_balls_by_key.erase(item_key)
		return null
	for key in _balls_by_key:
		if BallKey.is_instance(item_key, key):
			var raw: Variant = _balls_by_key[key]
			if is_instance_valid(raw):
				return raw
	return null


## Returns the tracked Ball for `item_key` or instantiates one; `preserved_speed` >= 0 carries rally speed through grab-and-release.
func ensure_ball_for_key(
	item_key: String,
	spawn_position: Vector2,
	initial_velocity: Vector2,
	preserved_speed: float = PRESERVED_SPEED_NONE,
) -> Ball:
	var existing: Ball = get_ball_for_key(item_key)
	if existing != null:
		# Re-entry from STORED/OUT_REST/OUT_HELD goes through enter_play so physics flags flip cleanly.
		if (
			existing.play_state != Ball.PlayState.PLAY_NORMAL
			and existing.play_state != Ball.PlayState.PLAY_ARC
		):
			existing.enter_play()
		existing.global_position = spawn_position
		existing.linear_velocity = initial_velocity
		_apply_preserved_speed(existing, preserved_speed)
		return existing

	var ball: Ball = _create_ball(item_key, spawn_position, initial_velocity)
	_apply_preserved_speed(ball, preserved_speed)
	return ball


## Ensures a registry Ball at `position`, in OUT_REST, carrying `velocity`.
func release_into_rest(item_key: String, position: Vector2, velocity: Vector2) -> Ball:
	var ball: Ball = get_ball_for_key(item_key)
	if ball == null:
		ball = _create_ball(item_key, position, velocity)

	ball.global_position = position
	ball.enter_out_rest()
	ball.linear_velocity = velocity
	return ball


## Spawns a STORED ball at `spawn_position` and registers it under `item_key`.
func adopt_stored(item_key: String, spawn_position: Vector2) -> Ball:
	var ball: Ball = ball_scene.instantiate()
	ball.court_config = court_config
	ball.bound_y = bound_y
	add_child(ball)
	ball.item_key = item_key
	ball.enter_stored()
	ball.global_position = spawn_position
	_apply_item_art(ball, item_key)

	_balls_by_key[item_key] = ball
	ball_spawned.emit(item_key, ball)
	_register_ball(ball)
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
func _create_ball(item_key: String, spawn_position: Vector2, initial_velocity: Vector2) -> Ball:
	var ball: Ball = ball_scene.instantiate()
	ball.court_config = court_config
	ball.bound_y = bound_y
	add_child(ball)
	ball.item_key = item_key
	ball.global_position = spawn_position
	ball.linear_velocity = initial_velocity
	ball.bound_y = bound_y
	_apply_item_art(ball, item_key)
	_balls_by_key[item_key] = ball
	ball_spawned.emit(item_key, ball)
	_register_ball(ball)
	return ball


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
	_detach(ball)
	return ball


func _on_court_changed(item_key: String, on_court: bool) -> void:
	_initial_reconcile_pending = false
	if on_court:
		var existing: Ball = get_ball_for_key(item_key)
		# Existing PLAY balls (pre-existing, mid-rally) already live at the right spot; reposition would clobber them.
		if (
			existing != null
			and (
				existing.play_state == Ball.PlayState.PLAY_NORMAL
				or existing.play_state == Ball.PlayState.PLAY_ARC
			)
		):
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

	# Membership = existence; deactivate becomes a state change, registry entry survives.
	ball.enter_stored()
	if ball_rack != null:
		ball.global_position = ball_rack.get_slot_position_for(item_key)


func _reconcile() -> void:
	var keys_to_remove: Array[String] = []
	for key: String in _balls_by_key:
		if _item_manager.get_level(key) <= 0:
			keys_to_remove.append(key)

	for key: String in keys_to_remove:
		var ball: Ball = get_ball_for_key(key)
		if ball != null:
			_balls_by_key.erase(key)
			_detach(ball)
			ball.queue_free()

	if _initial_reconcile_pending:
		_initial_reconcile_pending = false
		for key in _item_manager.get_court_items():
			if get_ball_for_key(key) == null:
				ensure_ball_for_key(
					key,
					_spawn_position_for(key),
					_item_manager.get_default_ball_launch_velocity(),
				)
	_reconcile_stored_kit_items()


## Populates STORED Balls for kit ball-role items absent from the court. Rack owns slot->world mapping.
func _reconcile_stored_kit_items() -> void:
	if ball_rack == null:
		return
	for key in _item_manager.get_kit_items(&"ball"):
		ensure_stored_ball_for_key(key)


## Guarantees a tracked STORED Ball for a kit ball-role key so its slot is indexed and grabbable.
## The one-shot _reconcile_stored_kit_items guard can leave a second stored ball untracked;
## this lets the rack/grab paths lazily back-fill it without re-running the whole sweep.
func ensure_stored_ball_for_key(item_key: String) -> Ball:
	var existing: Ball = get_ball_for_key(item_key)
	if existing != null:
		return existing
	if ball_rack == null or _item_manager == null:
		return null
	if _item_manager.get_level(item_key) <= 0:
		return null
	if _item_manager.get_rack_slot_index(item_key) < 0:
		return null
	return adopt_stored(item_key, ball_rack.get_slot_position_for(item_key))


func _default_spawn_position() -> Vector2:
	return spawn_origin


## Prefer the saved position so reloaded balls keep their last in-play spot.
## Falls back to the default spawn when no save data exists for the key.
func _spawn_position_for(item_key: String) -> Vector2:
	if not _has_save_manager_autoload():
		return _default_spawn_position()
	var state: ItemState = SaveManager.items
	if state != null and state.ball_positions.has(item_key):
		return state.ball_positions[item_key]
	return _default_spawn_position()


## Swaps the art into the pre-existing ItemArtHolder slot on Ball; idempotent across re-applications.
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
		if item.key == item_key or BallKey.is_instance(item.key, item_key):
			return item
	return null


func get_balls() -> Array[Ball]:
	return _balls


func get_current_ball() -> Ball:
	return _current_ball


## Sets court_config and bound_y on the ball, then registers it for tracking.
func attach(new_ball: Ball) -> void:
	if new_ball == null or _balls.has(new_ball):
		return
	new_ball.court_config = court_config
	new_ball.bound_y = bound_y
	_register_ball(new_ball)


## Removes the ball from tracking, disconnects signals, and emits ball_removed.
func _detach(old_ball: Ball) -> void:
	if old_ball == null:
		return
	var was_tracked: bool = _balls.has(old_ball)
	_balls.erase(old_ball)

	if is_instance_valid(old_ball):
		if old_ball.missed.is_connected(_on_ball_missed):
			old_ball.missed.disconnect(_on_ball_missed)

		if old_ball.at_max_speed_changed.is_connected(_on_ball_final_consolidation_changed):
			old_ball.at_max_speed_changed.disconnect(_on_ball_final_consolidation_changed)

		if old_ball.tier_advanced.is_connected(_on_ball_tier_advanced):
			old_ball.tier_advanced.disconnect(_on_ball_tier_advanced)

	if _current_ball == old_ball:
		var fallback: Ball = _balls.back() if not _balls.is_empty() else null
		_set_current(fallback)

	if was_tracked:
		ball_removed.emit(old_ball)


func register_miss_zone_globally() -> void:
	for zone in get_tree().get_nodes_in_group(&"miss_zones"):
		if zone is MissZone and not _miss_zones.has(zone):
			_miss_zones.append(zone)
			for tracked in _balls:
				if is_instance_valid(tracked):
					tracked.register_miss_zone(zone)


func register_miss_zone(zone: MissZone) -> void:
	if zone == null or _miss_zones.has(zone):
		return
	_miss_zones.append(zone)
	for tracked in _balls:
		if is_instance_valid(tracked):
			tracked.register_miss_zone(zone)


func unregister_miss_zone(zone: MissZone) -> void:
	_miss_zones.erase(zone)


func _set_current(new_current: Ball) -> void:
	if _current_ball == new_current:
		return
	_current_ball = new_current
	current_ball_changed.emit(new_current)


func _register_ball(ball: Ball) -> void:
	if ball == null or _balls.has(ball):
		return
	_balls.append(ball)
	if _current_ball == null:
		_set_current(ball)

	if not ball.missed.is_connected(_on_ball_missed):
		ball.missed.connect(_on_ball_missed)

	if not ball.at_max_speed_changed.is_connected(_on_ball_final_consolidation_changed):
		ball.at_max_speed_changed.connect(_on_ball_final_consolidation_changed)

	if not ball.tier_advanced.is_connected(_on_ball_tier_advanced):
		ball.tier_advanced.connect(_on_ball_tier_advanced)

	if ball.effect_processor != null:
		var paddles: Array[Node2D] = []
		if player_paddle != null:
			paddles.append(player_paddle)
		ball.effect_processor.paddles = paddles
	for zone in _miss_zones:
		if is_instance_valid(zone):
			ball.register_miss_zone(zone)
	ball_added.emit(ball)


func _on_ball_missed(ball: Ball) -> void:
	ball_missed.emit(ball)


func _on_ball_final_consolidation_changed(in_final: bool) -> void:
	ball_final_consolidation_changed.emit(in_final)


func _on_ball_tier_advanced(ball: Ball, new_tier: int) -> void:
	ball_tier_advanced.emit(ball, new_tier)
