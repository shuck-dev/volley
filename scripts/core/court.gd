class_name Court
extends Node2D

signal volley_count_changed(count: int)
signal personal_volley_best_changed(best: int)
signal ball_at_max_speed_changed(is_at_max: bool)
signal auto_play_changed(is_active: bool, friendship_point_rate: float)
signal partner_changed

const MissZoneScene: PackedScene = preload("res://scenes/miss_zone.tscn")

@export var ball_system: BallReconciler
@export var ball_tracker: BallTracker
@export var player_paddle_scene: PackedScene
@export var player_spawn: Marker2D
@export var autoplay_controller: AutoplayController
@export var right_wall: StaticBody2D
@export var partner_spawn: Marker2D
@export var timeout_controller: TimeoutController

## Back-compat handle for tests; canonical live-ball set lives on `ball_tracker`.
var ball: Ball
var player_paddle: Paddle
var partner_paddle: PartnerPaddle

var _volley_count := 0
var _active_partner_definition: Resource
var _partner_miss_zone: MissZone
var _progression: ProgressionData
var _progression_config: ProgressionConfig
var _item_manager: Node
var _is_autoplay_active := false
var _friendship_point_accumulator := 0.0


func _ready() -> void:
	assert(autoplay_controller != null, "court.gd: autoplay_controller export must be assigned")
	if _progression == null:
		_progression = SaveManager.get_progression_data()
	if _progression_config == null:
		_progression_config = ProgressionManager.get_config()
	if _item_manager == null:
		_item_manager = ItemManager

	if player_paddle == null:
		player_paddle = player_paddle_scene.instantiate()
		player_paddle.position = player_spawn.position
		add_child(player_paddle)

	autoplay_controller.paddle = player_paddle
	player_paddle.paddle_hit.connect(_on_paddle_hit)

	if timeout_controller != null:
		timeout_controller.configure(player_paddle)

	if ball_tracker == null:
		ball_tracker = BallTracker.new()
		ball_tracker.ball_system = ball_system
		add_child(ball_tracker)
	ball_tracker.configure(player_paddle)
	ball_tracker.current_ball_changed.connect(_on_current_ball_changed)
	ball_tracker.ball_missed.connect(_on_ball_missed)
	autoplay_controller.bind_tracker(ball_tracker)
	ball_tracker.ball_at_max_speed_changed.connect(_on_ball_at_max_speed_changed)
	ball_tracker.register_miss_zone_globally()
	if ball != null:
		var pre_set: Ball = ball
		ball = null
		ball_tracker.attach(pre_set)

	if ProgressionManager.is_partner_unlocked(_progression.active_partner):
		_activate_partner()

	ProgressionManager.partner_recruited.connect(_on_partner_recruited)

	autoplay_controller.autoplay_toggled.connect(_on_auto_play_changed)

	personal_volley_best_changed.emit(_progression.personal_volley_best)


func _on_current_ball_changed(new_ball: Ball) -> void:
	ball = new_ball


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_autoplay"):
		autoplay_controller.toggle()
	if event.is_action_pressed("call_timeout") and timeout_controller != null:
		if timeout_controller.can_call_timeout():
			timeout_controller.call_timeout()
		else:
			timeout_controller.end_timeout()


func _physics_process(delta: float) -> void:
	_item_manager.process_frame(delta)


func _on_paddle_hit() -> void:
	_volley_count += 1
	_accumulate_friendship_points()

	if _volley_count > _progression.personal_volley_best:
		_progression.personal_volley_best = _volley_count
		personal_volley_best_changed.emit(_progression.personal_volley_best)

	volley_count_changed.emit(_volley_count)


func _on_ball_at_max_speed_changed(is_at_max: bool) -> void:
	ball_at_max_speed_changed.emit(is_at_max)
	if is_at_max:
		_item_manager.process_event(&"on_max_speed_reached")


func _on_ball_missed() -> void:
	# Each ball owns its speed: it resets itself off its own `missed` signal.
	# Court still owns the shared streak counter and resets the paddles' hit-cooldown trackers.
	var actions: Array[StringName] = _item_manager.process_event(&"on_miss")
	var should_halve: bool = actions.has(&"halve_streak")

	if should_halve:
		_volley_count = floori(_volley_count / 2.0)
	else:
		_volley_count = 0

	_friendship_point_accumulator = 0.0
	volley_count_changed.emit(_volley_count)

	player_paddle.reset_streak()
	if partner_paddle != null:
		partner_paddle.reset_streak()


func _on_auto_play_changed(is_active: bool) -> void:
	_is_autoplay_active = is_active
	auto_play_changed.emit(is_active, _progression_config.autoplay_friendship_point_rate)


func _on_partner_recruited(_partner_key: StringName) -> void:
	_activate_partner()


func _activate_partner() -> void:
	if partner_spawn == null:
		return
	if partner_paddle != null:
		_deactivate_partner()

	var partner_definition: Resource = ProgressionManager.get_partner(_progression.active_partner)
	if partner_definition == null or partner_definition.paddle_scene == null:
		return

	_active_partner_definition = partner_definition
	partner_paddle = partner_definition.paddle_scene.instantiate()
	partner_paddle.position = partner_spawn.position
	add_child(partner_paddle)

	partner_paddle.paddle_hit.connect(_on_paddle_hit)
	ball_tracker.set_partner_paddle(partner_paddle)
	if partner_paddle.controller != null:
		partner_paddle.controller.bind_tracker(ball_tracker)

	_item_manager.register_partner(partner_definition)

	if right_wall != null:
		_partner_miss_zone = MissZoneScene.instantiate()
		right_wall.add_child(_partner_miss_zone)
		ball_tracker.register_miss_zone(_partner_miss_zone)

	partner_changed.emit()


func _deactivate_partner() -> void:
	if partner_paddle == null:
		return
	if _active_partner_definition != null:
		_item_manager.unregister_partner(_active_partner_definition)

	partner_paddle.paddle_hit.disconnect(_on_paddle_hit)
	if partner_paddle.controller != null:
		partner_paddle.controller.bind_tracker(null)
	ball_tracker.clear_partner_paddle(partner_paddle)
	partner_paddle.queue_free()
	partner_paddle = null
	_active_partner_definition = null

	if _partner_miss_zone != null:
		ball_tracker.unregister_miss_zone(_partner_miss_zone)
		_partner_miss_zone.queue_free()
		_partner_miss_zone = null

	partner_changed.emit()


## Fractional accumulation; remainder from a reduced autoplay rate carries between hits.
func _accumulate_friendship_points() -> void:
	var rate: float = _progression_config.autoplay_friendship_point_rate
	var base_points: float = _item_manager.get_stat(&"friendship_points_per_hit")
	var points_to_add: float = (base_points * rate) if _is_autoplay_active else base_points
	_friendship_point_accumulator += points_to_add
	var whole_points: int = int(_friendship_point_accumulator)
	if whole_points > 0:
		_item_manager.add_friendship_points(whole_points)
		_friendship_point_accumulator -= float(whole_points)
