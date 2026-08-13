class_name BallReconciler
extends Node

## Live-ball lifecycle owner.

signal ball_spawned(ball_key: String, ball: Ball)

## Emitted whenever a ball is in play.
signal ball_added(ball: Ball)

## Emitted whenever a ball leaves play.
signal ball_removed(ball: Ball)
signal ball_missed(ball: Ball)

signal ball_tier_advanced(ball: Ball, new_tier: int)

signal current_ball_changed(ball: Ball)

const PRESERVED_SPEED_NONE: float = -1.0

## Ball-role rack for STORED slot positions.
@export var ball_rack: RackDisplay

@export var spawn_origin: Vector2 = Vector2.ZERO
@export var player_paddle: Node2D

var bound_y: float = 0.0
## Apex ceiling in pixels above the soul bound; Court sets this, then it is passed onto every ball this reconciler spawns.
var arc_height_max: float = 0.0

var _ball_manager: BallManager
var _balls_by_key: Dictionary = {}
var _initial_reconcile_pending: bool = true

var _balls: Array[Ball] = []
var _current_ball: Ball
var _miss_zones: Array[MissZone] = []


func configure(ball_manager: Node) -> void:
	_ball_manager = ball_manager


func _ready() -> void:
	add_to_group(&"ball_trackers")

	if _ball_manager == null:
		_ball_manager = BallManager

	_ball_manager.court_changed.connect(_on_court_changed)
	_ball_manager.ball_manager_state_changed.connect(_reconcile)
	_ball_manager.item_placement_changed.connect(_on_item_placement_changed)

	# Position persistence
	if _has_save_manager_autoload():
		SaveManager.set_position_provider(collect_item_positions)

	# Deferred so sibling listeners connect before we emit.
	call_deferred(&"_reconcile")


## Snapshot of live ball positions keyed by ball_key.
func collect_item_positions() -> Dictionary[String, Vector2]:
	var positions: Dictionary[String, Vector2] = {}
	for ball in _balls:
		if not is_instance_valid(ball):
			continue

		if ball.play_state == Ball.PlayState.STORED:
			continue

		if ball.ball_key.is_empty():
			continue

		positions[ball.ball_key] = ball.global_position

	return positions


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


## Returns the tracked Ball for `ball_key` and instances.
func get_ball_for_key(ball_key: String) -> Ball:
	if _balls_by_key.has(ball_key):
		var raw: Variant = _balls_by_key[ball_key]

		if is_instance_valid(raw):
			return raw

		_balls_by_key.erase(ball_key)

		return null

	for key in _balls_by_key:
		if BallKey.is_instance(ball_key, key):
			var raw: Variant = _balls_by_key[key]

			if is_instance_valid(raw):
				return raw

	return null


## Ensures a registry Ball at `position`, in OUT_REST, carrying `velocity`.
func release_into_rest(ball_key: String, position: Vector2, velocity: Vector2) -> Ball:
	var ball: Ball = get_ball_for_key(ball_key)
	if ball == null:
		ball = _create_ball(ball_key, position, velocity)

	ball.global_position = position
	ball.enter_out_rest()
	ball.linear_velocity = velocity
	return ball


## Spawns a purchased ball on the rack.
func spawn_stored(template_key: String, position: Vector2) -> Ball:
	var key := _ball_manager.generate_instance_key(template_key)
	_ball_manager.register_instance(key)
	return _create_stored(key, position)


## Spawns a ball onto the venue floor.
func spawn_at_rest(template_key: String, position: Vector2, velocity: Vector2) -> Ball:
	var key := _ball_manager.generate_instance_key(template_key)
	var ball := _create_ball(key, position, velocity)
	ball.global_position = position
	ball.enter_out_rest()
	ball.linear_velocity = velocity
	return ball


## Puts a ball into active play on the court.
func bring_into_play(
	ball_key: String,
	spawn_position: Vector2,
	initial_velocity: Vector2,
	preserved_speed: float = PRESERVED_SPEED_NONE,
) -> Ball:
	if not _ball_manager.is_on_court(ball_key):
		_ball_manager.activate(ball_key)
	var ball: Ball = get_ball_for_key(ball_key)
	if ball != null:
		ball.enter_play()
		ball.global_position = spawn_position
		ball.linear_velocity = initial_velocity
		_apply_preserved_speed(ball, preserved_speed)
		return ball
	ball = _create_ball(ball_key, spawn_position, initial_velocity)
	_apply_preserved_speed(ball, preserved_speed)
	return ball


func release_ball(ball_key: String) -> Ball:
	var ball: Ball = get_ball_for_key(ball_key)
	if ball == null:
		return null

	_initial_reconcile_pending = false
	_balls_by_key.erase(ball_key)
	_detach(ball)
	return ball


## Creates a tracked STORED Ball for a stored item key, if one doesn't already exist.
func create_ball_from_key(ball_key: String) -> Ball:
	var existing: Ball = get_ball_for_key(ball_key)
	if existing != null:
		return existing
	if ball_rack == null or _ball_manager == null:
		return null
	if _ball_manager.get_level(ball_key) <= 0:
		return null
	if _ball_manager.get_rack_slot_index(ball_key) < 0:
		return null
	return _create_stored(ball_key, ball_rack.get_slot_position_for(ball_key))


func get_balls() -> Array[Ball]:
	return _balls


## Soonest-to-arrive in-play ball approaching a paddle at `paddle_x`. Null when none qualifies.
func get_closest_approaching_ball(paddle_x: float, lane_sign: float) -> Ball:
	var best: Ball = null
	var best_time: float = INF

	for candidate in _balls:
		if candidate == null or not is_instance_valid(candidate):
			continue

		var state: Ball.PlayState = candidate.play_state
		if state != Ball.PlayState.PLAY_NORMAL and state != Ball.PlayState.PLAY_ARC:
			continue

		if lane_sign * candidate.linear_velocity.x >= 0:
			continue

		if lane_sign * candidate.position.x <= lane_sign * paddle_x:
			continue

		var speed_x: float = absf(candidate.linear_velocity.x)
		if speed_x < 1.0:
			continue

		var arrival: float = absf(paddle_x - candidate.position.x) / speed_x

		if arrival < best_time:
			best_time = arrival
			best = candidate

	return best


func get_current_ball() -> Ball:
	return _current_ball


## Adopts a ball already in the scene tree.
func attach(new_ball: Ball) -> void:
	if new_ball == null or _balls.has(new_ball):
		return
	new_ball.arc_height_max = arc_height_max
	new_ball.bound_y = bound_y
	_register_ball(new_ball)


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


func _has_save_manager_autoload() -> bool:
	return get_tree() != null and get_tree().root.has_node("SaveManager")


## Internal: spawns a STORED ball at a slot position.
func _create_stored(ball_key: String, spawn_position: Vector2) -> Ball:
	var definition: BallDefinition = _ball_manager.get_item(ball_key)
	var ball: Ball = definition.scene.instantiate()
	ball.arc_height_max = arc_height_max
	ball.bound_y = bound_y
	ball.ball_key = ball_key
	ball.stats = definition.stats
	ball.speed_tiers = definition.speed_tiers
	add_child(ball)
	ball.enter_stored()
	ball.global_position = spawn_position

	_balls_by_key[ball_key] = ball
	ball_spawned.emit(ball_key, ball)
	_register_ball(ball)
	return ball


## Internal: spawns a Ball node without key generation.
func _create_ball(ball_key: String, spawn_position: Vector2, initial_velocity: Vector2) -> Ball:
	var definition: BallDefinition = _ball_manager.get_item(ball_key)
	var ball: Ball = definition.scene.instantiate()

	ball.arc_height_max = arc_height_max
	ball.bound_y = bound_y
	ball.ball_key = ball_key
	ball.stats = definition.stats
	ball.speed_tiers = definition.speed_tiers

	add_child(ball)

	ball.global_position = spawn_position
	ball.linear_velocity = initial_velocity
	ball.bound_y = bound_y

	_balls_by_key[ball_key] = ball
	ball_spawned.emit(ball_key, ball)

	_register_ball(ball)

	return ball


func _apply_preserved_speed(ball: Ball, preserved_speed: float) -> void:
	if preserved_speed < 0.0:
		return
	ball.speed = preserved_speed
	if ball.linear_velocity.length() > 0.0:
		ball.linear_velocity = ball.linear_velocity.normalized() * preserved_speed


func _on_court_changed(ball_key: String, on_court: bool) -> void:
	_initial_reconcile_pending = false
	if on_court:
		var existing: Ball = get_ball_for_key(ball_key)
		if (
			existing != null
			and (
				existing.play_state == Ball.PlayState.PLAY_NORMAL
				or existing.play_state == Ball.PlayState.PLAY_ARC
			)
		):
			return
		var pos := _spawn_position_for(ball_key)
		var vel := _ball_manager.get_default_ball_launch_velocity()
		if existing != null:
			existing.global_position = pos
			existing.linear_velocity = vel
			existing.enter_play()
		else:
			_create_ball(ball_key, pos, vel)
		return

	var ball: Ball = get_ball_for_key(ball_key)
	if ball == null:
		return

	ball.enter_stored()
	if ball_rack != null:
		ball.global_position = ball_rack.get_slot_position_for(ball_key)


## A Kit item has no live body; free the one that was tracking it before the placement changed.
func _on_item_placement_changed(ball_key: String, placement: int) -> void:
	if placement != Placement.IN_KIT:
		return
	var ball: Ball = get_ball_for_key(ball_key)
	if ball == null:
		return
	_balls_by_key.erase(ball_key)
	_detach(ball)
	ball.queue_free()


func _reconcile() -> void:
	var keys_to_remove: Array[String] = []
	for key: String in _balls_by_key:
		if _ball_manager.get_level(key) <= 0:
			keys_to_remove.append(key)

	for key: String in keys_to_remove:
		var ball: Ball = get_ball_for_key(key)
		if ball != null:
			_balls_by_key.erase(key)
			_detach(ball)
			ball.queue_free()

	if _initial_reconcile_pending:
		_initial_reconcile_pending = false
		for key in _ball_keys():
			if get_ball_for_key(key) == null:
				_create_ball(
					key, _spawn_position_for(key), _ball_manager.get_default_ball_launch_velocity()
				)
	_reconcile_stored_items()


func _reconcile_stored_items() -> void:
	if ball_rack == null:
		return
	for key in _ball_manager.get_stored_items():
		create_ball_from_key(key)


func _default_spawn_position() -> Vector2:
	return spawn_origin


func _ball_keys() -> Array[String]:
	var result: Array[String] = []
	for key in _ball_manager.state.ball_levels:
		if _ball_manager.state.ball_levels[key] <= 0:
			continue
		if _ball_manager.get_placement(key) != Placement.ON_COURT:
			continue
		if _get_ball_definition(key) != null:
			result.append(key)
	return result


## Where a reloaded ball lands so it appears where the player left it.
func _spawn_position_for(ball_key: String) -> Vector2:
	if not _has_save_manager_autoload():
		return _default_spawn_position()
	var state: BallState = SaveManager.items
	if state != null and state.ball_positions.has(ball_key):
		return state.ball_positions[ball_key]
	return _default_spawn_position()


func _get_ball_definition(ball_key: String) -> BallDefinition:
	for item: BallDefinition in _ball_manager.items:
		if item.key == ball_key or BallKey.is_instance(item.key, ball_key):
			return item
	return null


## Releases a ball from tracking.
func _detach(old_ball: Ball) -> void:
	if old_ball == null:
		return
	var was_tracked: bool = _balls.has(old_ball)
	_balls.erase(old_ball)

	if is_instance_valid(old_ball):
		if old_ball.missed.is_connected(_on_ball_missed):
			old_ball.missed.disconnect(_on_ball_missed)

		if old_ball.tier_advanced.is_connected(_on_ball_tier_advanced):
			old_ball.tier_advanced.disconnect(_on_ball_tier_advanced)

	if _current_ball == old_ball:
		var fallback: Ball = _balls.back() if not _balls.is_empty() else null
		_set_current(fallback)

	if was_tracked:
		ball_removed.emit(old_ball)


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

	if not ball.tier_advanced.is_connected(_on_ball_tier_advanced):
		ball.tier_advanced.connect(_on_ball_tier_advanced)

	for zone in _miss_zones:
		if is_instance_valid(zone):
			ball.register_miss_zone(zone)
	ball_added.emit(ball)


func _on_ball_missed(ball: Ball) -> void:
	ball_missed.emit(ball)
	free_temporary.call_deferred(ball)


func _on_ball_tier_advanced(ball: Ball, new_tier: int) -> void:
	ball_tier_advanced.emit(ball, new_tier)


## Spawns an temporary Ball, not tracked or saved.
func spawn_temporary(scene: PackedScene, spawn_position: Vector2, velocity: Vector2) -> Ball:
	var ball: Ball = scene.instantiate()
	ball.arc_height_max = arc_height_max
	ball.bound_y = bound_y
	ball.is_temporary = true

	add_child(ball)

	ball.global_position = spawn_position
	ball.linear_velocity = velocity

	ball_spawned.emit("", ball)
	_register_ball(ball)
	return ball


## Frees a temporary ball.
func free_temporary(ball: Ball) -> void:
	if ball == null or not is_instance_valid(ball) or not ball.is_temporary:
		return
	_detach(ball)
	ball.queue_free()
