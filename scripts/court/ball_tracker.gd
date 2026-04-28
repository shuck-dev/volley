class_name BallTracker
extends Node

## Multi-ball ownership; spec lives in designs/01-prototype/21-ball-dynamics.md.

signal ball_missed
signal ball_at_max_speed_changed(is_at_max: bool)
signal current_ball_changed(ball: Ball)
## Re-emitted so subscribers bind to the tracker, not past it.
signal ball_added(ball: Ball)
signal ball_removed(ball: Ball)

@export var ball_system: BallReconciler

var _balls: Array[Ball] = []
var _current_ball: Ball
var _partner_paddle: Node2D
var _player_paddle: Node2D
var _miss_zones: Array[MissZone] = []


func configure(player_paddle: Node2D) -> void:
	_player_paddle = player_paddle


func _ready() -> void:
	if ball_system != null:
		ball_system.ball_added.connect(attach)
		ball_system.ball_removed.connect(detach)


func get_balls() -> Array[Ball]:
	return _balls


func get_current_ball() -> Ball:
	return _current_ball


func attach(new_ball: Ball) -> void:
	if new_ball == null or _balls.has(new_ball):
		return
	_balls.append(new_ball)
	if _current_ball == null:
		_set_current(new_ball)
	if not new_ball.missed.is_connected(_on_ball_missed):
		new_ball.missed.connect(_on_ball_missed)

	if not new_ball.at_max_speed_changed.is_connected(_on_ball_at_max_speed_changed):
		new_ball.at_max_speed_changed.connect(_on_ball_at_max_speed_changed)
	if new_ball.effect_processor != null:
		var paddles: Array[Node2D] = []
		if _player_paddle != null:
			paddles.append(_player_paddle)
		if _partner_paddle != null:
			paddles.append(_partner_paddle)
		new_ball.effect_processor.paddles = paddles
	for zone in _miss_zones:
		if is_instance_valid(zone):
			new_ball.register_miss_zone(zone)
	if _partner_paddle != null and _partner_paddle.has_method("set_ball"):
		_partner_paddle.set_ball(new_ball)
	ball_added.emit(new_ball)


func detach(old_ball: Ball) -> void:
	if old_ball == null:
		return
	var was_tracked: bool = _balls.has(old_ball)
	_balls.erase(old_ball)
	if is_instance_valid(old_ball):
		if old_ball.missed.is_connected(_on_ball_missed):
			old_ball.missed.disconnect(_on_ball_missed)

		if old_ball.at_max_speed_changed.is_connected(_on_ball_at_max_speed_changed):
			old_ball.at_max_speed_changed.disconnect(_on_ball_at_max_speed_changed)
	if _current_ball == old_ball:
		var fallback: Ball = _balls.back() if not _balls.is_empty() else null
		_set_current(fallback)
		if _partner_paddle != null and fallback != null and _partner_paddle.has_method("set_ball"):
			_partner_paddle.set_ball(fallback)
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


func set_partner_paddle(paddle: Node2D) -> void:
	_partner_paddle = paddle
	if paddle == null:
		return
	for tracked in _balls:
		if not is_instance_valid(tracked):
			continue
		if tracked.effect_processor != null:
			if not tracked.effect_processor.paddles.has(paddle):
				tracked.effect_processor.paddles.append(paddle)
	if _current_ball != null and paddle.has_method("set_ball"):
		paddle.set_ball(_current_ball)


func clear_partner_paddle(paddle: Node2D) -> void:
	for tracked in _balls:
		if is_instance_valid(tracked) and tracked.effect_processor != null:
			tracked.effect_processor.paddles.erase(paddle)
	if _partner_paddle == paddle:
		_partner_paddle = null


func _set_current(new_current: Ball) -> void:
	if _current_ball == new_current:
		return
	_current_ball = new_current
	current_ball_changed.emit(new_current)


func _on_ball_missed() -> void:
	ball_missed.emit()


func _on_ball_at_max_speed_changed(is_at_max: bool) -> void:
	ball_at_max_speed_changed.emit(is_at_max)
