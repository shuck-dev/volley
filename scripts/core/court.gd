class_name Court
extends Node2D

signal volley_count_changed(count: int)
signal personal_volley_best_changed(best: int)
signal ball_final_consolidation_changed(in_final: bool)
signal ball_tier_advanced(new_tier: int)
signal auto_play_changed(is_active: bool, friendship_point_rate: float)
signal partner_changed

@export var court_config: CourtConfig

@export_group("Controllers")
@export var ball_system: BallReconciler
@export var ball_tracker: BallTracker
@export var autoplay_controller: AutoplayController
@export var timeout_controller: TimeoutController
@export var drag_controller: BallDragController

@export_group("Bounds")
@export var right_wall: StaticBody2D
@export var soul_bound: Marker2D

@export_group("Spawns")
@export var player_spawn: Marker2D
@export var partner_spawn: Marker2D

@export_group("Scenes")
@export var player_paddle_scene: PackedScene

## Back-compat handle for tests; standard live-ball set lives on `ball_tracker`.
var ball: Ball
var player_paddle: Paddle
var partner_paddle: PartnerPaddle

var _volley_count := 0
var _active_partner_definition: Resource
var _records: RecordsState
var _partners: PartnersState
var _progression_config: ProgressionConfig
var _item_manager: Node
var _is_autoplay_active := false
var _friendship_point_accumulator := 0.0
var _tier_reward_handler: TierRewardHandler

# Ball that triggered the current volley hit; available during the hit-processing window.
var _hitting_ball: Ball


func _ready() -> void:
	add_to_group(&"courts")
	assert(autoplay_controller != null, "court.gd: autoplay_controller export must be assigned")

	_tier_reward_handler = load("res://scripts/court/tier_reward_handler.gd").new()
	add_child(_tier_reward_handler)

	if _records == null:
		_records = SaveManager.records

	if _partners == null:
		_partners = SaveManager.partners

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

	if drag_controller != null:
		var character_area: Area2D = player_paddle.get_node_or_null("CharacterDropTarget")
		if character_area != null:
			drag_controller.set_character_drop_target(character_area)

	if ball_tracker == null:
		ball_tracker = BallTracker.new()
		ball_tracker.ball_system = ball_system
		add_child(ball_tracker)

	if court_config == null:
		court_config = load("res://scripts/core/court_config.gd").new()
	ball_tracker.court_config = court_config
	if soul_bound != null:
		ball_tracker.bound_y = soul_bound.global_position.y
	ball_tracker.configure(player_paddle)
	ball_tracker.current_ball_changed.connect(_on_current_ball_changed)
	ball_tracker.ball_missed.connect(_on_ball_missed)
	autoplay_controller.bind_tracker(ball_tracker)
	ball_tracker.ball_final_consolidation_changed.connect(_on_ball_final_consolidation_changed)
	ball_tracker.ball_tier_advanced.connect(_on_ball_tier_advanced)
	ball_tracker.ball_removed.connect(_tier_reward_handler.on_ball_removed)
	ball_tracker.register_miss_zone_globally()
	if ball != null:
		var pre_set: Ball = ball
		ball = null
		ball_tracker.attach(pre_set)

	if ProgressionManager.is_partner_unlocked(_partners.active_partner):
		_activate_partner()

	ProgressionManager.partner_recruited.connect(_on_partner_recruited)

	autoplay_controller.autoplay_toggled.connect(_on_auto_play_changed)

	personal_volley_best_changed.emit(_records.personal_volley_best)

	_tier_reward_handler.bind(_item_manager)
	ball_tracker.ball_tier_advanced.connect(_tier_reward_handler.on_tier_advanced)


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


func _on_paddle_hit(hitting_ball: Ball) -> void:
	_hitting_ball = hitting_ball
	_volley_count += 1
	_accumulate_friendship_points()

	if _volley_count > _records.personal_volley_best:
		_records.personal_volley_best = _volley_count
		personal_volley_best_changed.emit(_records.personal_volley_best)

	volley_count_changed.emit(_volley_count)

	_hitting_ball = null


func _on_ball_tier_advanced(_ball: Ball, new_tier: int) -> void:
	ball_tier_advanced.emit(new_tier)


# Final-consolidation entry still fires the legacy max-speed event Cadence latches on.
func _on_ball_final_consolidation_changed(in_final: bool) -> void:
	ball_final_consolidation_changed.emit(in_final)
	if in_final:
		_item_manager.process_event(&"on_max_speed_reached")


func _on_ball_missed(missed_ball: Ball) -> void:
	_tier_reward_handler.reset_rally(missed_ball)

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

	var partner_definition: Resource = ProgressionManager.get_partner(_partners.active_partner)
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
		right_wall.process_mode = Node.PROCESS_MODE_DISABLED
		right_wall.visible = false

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

	if right_wall != null:
		right_wall.process_mode = Node.PROCESS_MODE_INHERIT
		right_wall.visible = true

	partner_changed.emit()


## Fractional accumulation; remainder from a reduced autoplay rate carries between hits.
func _accumulate_friendship_points() -> void:
	var rate: float = _progression_config.autoplay_friendship_point_rate
	var base_points: float = Stats.resolve(
		GameRules.base.friendship_points_per_hit, &"friendship_points_per_hit", _item_manager
	)
	var multiplier: float = _hitting_ball.soul_multiplier if _hitting_ball != null else 1.0
	var points_to_add: float = (
		(base_points * multiplier * rate) if _is_autoplay_active else base_points * multiplier
	)
	_friendship_point_accumulator += points_to_add
	var whole_points: int = int(_friendship_point_accumulator)
	if whole_points > 0:
		_item_manager.add_friendship_points(whole_points)
		_friendship_point_accumulator -= float(whole_points)
