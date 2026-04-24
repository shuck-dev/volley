class_name BallReconciler
extends Node

## Owns live Ball instances for permanent on-court ball items.
## Listens to ItemManager.court_changed and reconciles the live set to on_court[&ball].

const BallScene: PackedScene = preload("res://scenes/ball.tscn")

@export var ball_scene: PackedScene = BallScene
@export var spawn_for_existing_on_load: bool = false

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


func get_ball_for_key(item_key: String) -> Ball:
	if not _balls_by_key.has(item_key):
		return null
	var raw: Variant = _balls_by_key[item_key]
	if not is_instance_valid(raw):
		_balls_by_key.erase(item_key)
		return null
	return raw


func spawn_for_key(item_key: String, spawn_position: Vector2, initial_velocity: Vector2) -> Ball:
	var existing: Ball = get_ball_for_key(item_key)
	if existing != null:
		existing.global_position = spawn_position
		existing.linear_velocity = initial_velocity
		return existing
	var ball: Ball = ball_scene.instantiate()
	_ball_host.add_child(ball)
	ball.global_position = spawn_position
	ball.linear_velocity = initial_velocity
	_balls_by_key[item_key] = ball
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
		spawn_for_key(item_key, _default_spawn_position(), _default_velocity())
	else:
		var ball: Ball = get_ball_for_key(item_key)
		if ball == null:
			return
		_balls_by_key.erase(item_key)
		ball.call_deferred("queue_free")


func _reconcile_initial_state() -> void:
	for key in _item_manager.get_court_items():
		if get_ball_for_key(key) == null:
			spawn_for_key(key, _default_spawn_position(), _default_velocity())


func _default_spawn_position() -> Vector2:
	if _ball_host is Node2D:
		return (_ball_host as Node2D).global_position
	return Vector2.ZERO


func _default_velocity() -> Vector2:
	var min_speed: float = _item_manager.get_stat(&"ball_speed_min")
	return Vector2(min_speed, min_speed * 0.5).normalized() * min_speed
