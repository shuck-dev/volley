class_name Court
extends Node2D

signal volley_count_changed(count: int)
signal personal_volley_best_changed(best: int)
signal ball_tier_advanced(new_tier: int)
signal auto_play_changed(is_active: bool, soul_rate: float)
signal partner_changed

## Apex ceiling in pixels above the soul bound; passed to every ball this court spawns.
@export var arc_height_max: float = 220.0

@export_group("Controllers")
@export var autoplay_controller: AutoplayController
@export var drag_controller: ItemDragController
@export var ball_rack: RackDisplay

@export_group("Bounds")
@export var right_wall: StaticBody2D
@export var soul_bound: Marker2D

@export_group("Spawns")
@export var player_spawn: Marker2D
@export var partner_spawn: Marker2D

@export_group("Scenes")
@export var player_paddle_scene: PackedScene

## Back-compat handle for tests; standard live-ball set lives on `BallReconciler`.
var ball: Ball
var player_paddle: Paddle
var partner_paddle: PartnerPaddle

var _records: RecordsState
var _partners: PartnersState
var _progression_config: ProgressionConfig
var _ball_manager: BallManager
var _is_autoplay_active := false
var _tier_reward_handler: TierRewardHandler
var _volley_streak_tracker: VolleyStreakTracker

# Ball that triggered the current volley hit; available during the hit-processing window.
var _hitting_ball: Ball


func _ready() -> void:
	add_to_group(&"courts")
	assert(autoplay_controller != null, "court.gd: autoplay_controller export must be assigned")

	_tier_reward_handler = TierRewardHandler.new()
	add_child(_tier_reward_handler)

	_volley_streak_tracker = VolleyStreakTracker.new()
	_volley_streak_tracker.volley_count_changed.connect(volley_count_changed.emit)

	if _records == null:
		_records = SaveManager.records

	if _partners == null:
		_partners = SaveManager.partners

	if _progression_config == null:
		_progression_config = ProgressionManager.get_config()

	if _ball_manager == null:
		_ball_manager = BallManager

	if player_paddle == null:
		player_paddle = player_paddle_scene.instantiate()
		player_paddle.position = player_spawn.position
		add_child(player_paddle)

	autoplay_controller.paddle = player_paddle
	player_paddle.paddle_hit.connect(_on_paddle_hit)

	BallReconciler.spawn_origin = global_position
	BallReconciler.arc_height_max = arc_height_max
	BallReconciler.ball_rack = ball_rack
	if soul_bound != null:
		BallReconciler.bound_y = soul_bound.global_position.y
	BallReconciler.player_paddle = player_paddle
	BallReconciler.current_ball_changed.connect(_on_current_ball_changed)
	BallReconciler.ball_missed.connect(_on_ball_missed)
	BallReconciler.ball_tier_advanced.connect(_on_ball_tier_advanced)
	BallReconciler.register_miss_zone_globally()
	if ball != null:
		var pre_set: Ball = ball
		ball = null
		BallReconciler.attach(pre_set)

	if ProgressionManager.is_partner_unlocked(_partners.active_partner):
		_activate_partner()

	ProgressionManager.partner_recruited.connect(_on_partner_recruited)

	autoplay_controller.autoplay_toggled.connect(_on_auto_play_changed)

	personal_volley_best_changed.emit(_records.personal_volley_best)

	BallReconciler.ball_tier_advanced.connect(_tier_reward_handler.on_tier_advanced)


func _on_current_ball_changed(new_ball: Ball) -> void:
	ball = new_ball

	if partner_paddle != null and new_ball != null and partner_paddle.has_method("set_ball"):
		partner_paddle.set_ball(new_ball)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_autoplay"):
		autoplay_controller.toggle()


func _on_paddle_hit(hitting_ball: Ball) -> void:
	_hitting_ball = hitting_ball
	_volley_streak_tracker.record_hit()
	_accumulate_soul()

	if _volley_streak_tracker.count > _records.personal_volley_best:
		_records.personal_volley_best = _volley_streak_tracker.count
		personal_volley_best_changed.emit(_records.personal_volley_best)

	_hitting_ball = null


func _on_ball_tier_advanced(_ball: Ball, new_tier: int) -> void:
	ball_tier_advanced.emit(new_tier)


func _on_ball_missed(_missed_ball: Ball) -> void:
	_volley_streak_tracker.record_miss(BallReconciler.has_ball_in_play())


func _on_auto_play_changed(is_active: bool) -> void:
	_is_autoplay_active = is_active
	auto_play_changed.emit(is_active, _progression_config.autoplay_soul_rate)


func _on_partner_recruited(_partner_key: StringName) -> void:
	_activate_partner()


func _activate_partner() -> void:
	if partner_spawn == null:
		return
	if partner_paddle != null:
		_deactivate_partner()

	var partner_definition: Resource = ProgressionManager.get_partner(_partners.active_partner)
	if partner_definition == null or partner_definition.paddle_scene == null:
		return

	partner_paddle = partner_definition.paddle_scene.instantiate()
	partner_paddle.position = partner_spawn.position
	add_child(partner_paddle)

	partner_paddle.paddle_hit.connect(_on_paddle_hit)

	var current: Ball = BallReconciler.get_current_ball()
	if current != null and partner_paddle.has_method("set_ball"):
		partner_paddle.set_ball(current)

	BallReconciler.ball_added.connect(_on_partner_ball_added)

	if right_wall != null:
		right_wall.process_mode = Node.PROCESS_MODE_DISABLED
		right_wall.visible = false

	partner_changed.emit()


func _deactivate_partner() -> void:
	if partner_paddle == null:
		return

	partner_paddle.paddle_hit.disconnect(_on_paddle_hit)
	BallReconciler.ball_added.disconnect(_on_partner_ball_added)

	partner_paddle.queue_free()
	partner_paddle = null

	if right_wall != null:
		right_wall.process_mode = Node.PROCESS_MODE_INHERIT
		right_wall.visible = true

	partner_changed.emit()


func _on_partner_ball_added(incoming_ball: Ball) -> void:
	if partner_paddle == null:
		return

	if partner_paddle.has_method("set_ball"):
		partner_paddle.set_ball(incoming_ball)


func _accumulate_soul() -> void:
	var rate: float = _progression_config.autoplay_soul_rate
	var base_points: float = GameRules.base.soul_per_hit
	var multiplier: float = _hitting_ball.soul_multiplier if _hitting_ball != null else 1.0
	var points_to_add: float = (
		(base_points * multiplier * rate) if _is_autoplay_active else base_points * multiplier
	)
	_ball_manager.add_soul_fractional(points_to_add)
