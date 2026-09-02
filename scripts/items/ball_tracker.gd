extends Node

## Live-ball lifecycle owner.

## Ball was moved into play.
signal ball_added(ball: Ball)

## Ball was removed from play.
signal ball_removed(ball: Ball)

## Ball was removed from play by a miss.
signal ball_missed(ball: Ball)

## Ball enters a new speed range
signal ball_tier_advanced(ball: Ball, new_tier: int)

## Vertical gap between stacked balls on spawn.
const _COURT_BALL_SPAWN_STACK_OFFSET: float = 24.0

var _bound_y: float

## Apex arc ceiling above the soul bound.
var _arc_height_max: float

var _ball_manager: BallManager

var _balls: Array[Ball] = []

## Temporary keys for this session; held outside BallManager's state so they never reach the save.
var _temporary_keys: Dictionary = {}

var _miss_zones: Array[MissZone] = []
var _player_paddle: Node2D
var _court_ball_spawn: Vector2


func _ready() -> void:
	if _ball_manager == null:
		_ball_manager = BallManager

	SaveManager.save_cleared.connect(_on_save_cleared)


func configure(ball_manager: Node) -> void:
	_ball_manager = ball_manager


## Pulls the scene-derived facts a Court owns: spawn position, apex height, bound, player paddle.
func set_court(court: Court) -> void:
	_court_ball_spawn = court.court_ball_spawn.global_position
	_arc_height_max = court.arc_height_max
	_bound_y = court.soul_bound.global_position.y
	_player_paddle = court.player_paddle

	# Saved balls need the court's spawn point to load first.
	_load_resting_balls.call_deferred()


## Live position of the player paddle
func get_player_paddle_position() -> Variant:
	if _player_paddle == null:
		return null
	return _player_paddle.global_position


## True when any tracked ball is in play, driving the rally-in-progress gate.
func has_ball_in_play() -> bool:
	for ball in _balls:
		if (
			ball.play_state == Ball.PlayState.PLAY_NORMAL
			or ball.play_state == Ball.PlayState.PLAY_ARC
		):
			return true

	return false


## Returns the tracked Ball for the exact `ball_key`.
func get_ball_for_key(ball_key: String) -> Ball:
	for ball in _balls:
		if ball.ball_key == ball_key:
			return ball

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


## Spawns a ball onto the venue floor.
func spawn_at_rest(template_key: String, position: Vector2, velocity: Vector2) -> Ball:
	var key := _ball_manager.generate_instance_key(template_key)
	var ball := _create_ball(key, position, velocity)
	ball.global_position = position
	ball.enter_out_rest()
	ball.linear_velocity = velocity
	return ball


## Puts a ball into active play on the court.
func bring_into_play(ball_key: String, spawn_position: Vector2, initial_velocity: Vector2) -> Ball:
	if not _ball_manager.is_on_court(ball_key):
		_ball_manager.activate(ball_key)
	var ball: Ball = get_ball_for_key(ball_key)
	if ball != null:
		ball.enter_play()
		ball.global_position = spawn_position
		ball.linear_velocity = initial_velocity
		return ball
	return _create_ball(ball_key, spawn_position, initial_velocity)


## Detaches and frees the tracked ball for `ball_key`, e.g. when it becomes a Kit's static icon.
func release_ball(ball_key: String) -> void:
	var ball: Ball = get_ball_for_key(ball_key)
	if ball == null:
		return

	_detach(ball)
	ball.queue_free()


func get_balls() -> Array[Ball]:
	return _balls


## Soonest-to-arrive in-play ball approaching a paddle at `paddle_x`. Null when none qualifies.
func get_closest_approaching_ball(paddle_x: float, lane_sign: float) -> Ball:
	var best: Ball = null
	var best_time: float = INF

	for candidate in _balls:
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


func register_miss_zone(zone: MissZone) -> void:
	if zone == null or _miss_zones.has(zone):
		return
	_miss_zones.append(zone)
	for tracked in _balls:
		tracked.register_miss_zone(zone)


func unregister_miss_zone(zone: MissZone) -> void:
	_miss_zones.erase(zone)


## Spawns an temporary Ball, not tracked or saved.
func spawn_temporary(scene: PackedScene, spawn_position: Vector2, velocity: Vector2) -> Ball:
	var ball: Ball = scene.instantiate()
	ball.arc_height_max = _arc_height_max
	ball.bound_y = _bound_y
	ball.is_temporary = true

	# Addressable like any other ball, but never registered, so never saved.
	ball.ball_key = _ball_manager.generate_instance_key(
		scene.resource_path.get_file().get_basename(), _temporary_keys
	)
	_temporary_keys[ball.ball_key] = true

	add_child(ball)

	ball.global_position = spawn_position
	ball.linear_velocity = velocity

	_register_ball(ball)
	return ball


## Frees a temporary ball.
func free_temporary(ball: Ball) -> void:
	if ball == null or not is_instance_valid(ball) or not ball.is_temporary:
		return
	_temporary_keys.erase(ball.ball_key)
	_detach(ball)
	ball.queue_free()


## Internal: spawns a Ball node without key generation.
func _create_ball(ball_key: String, spawn_position: Vector2, initial_velocity: Vector2) -> Ball:
	var definition: BallDefinition = _ball_manager.get_item(ball_key)
	var ball: Ball = definition.scene.instantiate()

	ball.arc_height_max = _arc_height_max
	ball.bound_y = _bound_y
	ball.ball_key = ball_key
	ball.stats = definition.stats
	ball.speed_tiers = definition.speed_tiers

	add_child(ball)

	ball.global_position = spawn_position
	ball.linear_velocity = initial_velocity
	ball.bound_y = _bound_y

	_register_ball(ball)

	return ball


## Spawns every live ball.
func _load_resting_balls() -> void:
	var court_keys: Array[String] = _ball_manager.get_court_balls()
	var loose_keys: Array[String] = _ball_manager.get_loose_balls()

	_load_court_balls(court_keys)
	_load_loose_balls(loose_keys)


## Transitions on court balls to a resting position.
func _load_court_balls(keys: Array[String]) -> void:
	for stack_index in keys.size():
		var key: String = keys[stack_index]
		var position: Vector2 = (
			_court_ball_spawn + Vector2(0.0, -_COURT_BALL_SPAWN_STACK_OFFSET * stack_index)
		)
		_ball_manager.mark_loose_in_venue(key, position)
		_spawn_resting_ball(key, position)


func _load_loose_balls(keys: Array[String]) -> void:
	for key in keys:
		_spawn_resting_ball(key, _ball_manager.get_venue_position(key, _court_ball_spawn))


func _spawn_resting_ball(ball_key: String, position: Vector2) -> void:
	var ball := _create_ball(ball_key, position, Vector2.ZERO)
	ball.enter_out_rest()


func _detach(old_ball: Ball) -> void:
	if old_ball == null:
		return
	var was_tracked: bool = _balls.has(old_ball)
	_balls.erase(old_ball)

	if old_ball.missed.is_connected(_on_ball_missed):
		old_ball.missed.disconnect(_on_ball_missed)

	if old_ball.tier_advanced.is_connected(_on_ball_tier_advanced):
		old_ball.tier_advanced.disconnect(_on_ball_tier_advanced)

	if was_tracked:
		ball_removed.emit(old_ball)


func _register_ball(ball: Ball) -> void:
	if ball == null or _balls.has(ball):
		return

	_balls.append(ball)

	if not ball.missed.is_connected(_on_ball_missed):
		ball.missed.connect(_on_ball_missed)

	if not ball.tier_advanced.is_connected(_on_ball_tier_advanced):
		ball.tier_advanced.connect(_on_ball_tier_advanced)

	for zone in _miss_zones:
		ball.register_miss_zone(zone)
	ball_added.emit(ball)


func _on_ball_missed(ball: Ball) -> void:
	ball_missed.emit(ball)
	free_temporary.call_deferred(ball)


## Free autoload children on save clear, since the reload doesn't touch them.
func _on_save_cleared() -> void:
	for ball in _balls:
		ball.queue_free()
	_balls.clear()


func _on_ball_tier_advanced(ball: Ball, new_tier: int) -> void:
	ball_tier_advanced.emit(ball, new_tier)
