class_name Court
extends Node2D

signal volley_count_changed(count: int)
signal personal_volley_best_changed(best: int)
signal ball_at_max_speed_changed(is_at_max: bool)
signal auto_play_changed(is_active: bool, friendship_point_rate: float)
signal partner_changed

const MissZoneScene: PackedScene = preload("res://scenes/miss_zone.tscn")

@export var ball_system: BallReconciler
@export var player_paddle_scene: PackedScene
@export var player_spawn: Marker2D
@export var autoplay_controller: AutoplayController
@export var right_wall: StaticBody2D
@export var partner_spawn: Marker2D
@export var timeout_controller: TimeoutController

## "Most recent" live ball; kept as a back-compat handle for tests and partner targeting.
## Multi-ball is design intent: every tracked ball is wired in `_balls`, not just this one.
var ball: Ball
var player_paddle: Paddle
var partner_paddle: PartnerPaddle

## Every live ball Court is wired to. Court reacts to `missed`/`at_max_speed_changed` on
## each entry; paddle hits accelerate every tracked ball; misses reset every tracked ball.
var _balls: Array[Ball] = []

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

	if ball_system != null:
		ball_system.ball_added.connect(_attach_ball)
		ball_system.ball_removed.connect(_detach_ball)
	if ball != null and not _balls.has(ball):
		# Test seam / direct pre-set: route the pre-set ball through the same attach path.
		var pre_set: Ball = ball
		ball = null
		_attach_ball(pre_set)

	if ProgressionManager.is_partner_unlocked(_progression.active_partner):
		_activate_partner()

	ProgressionManager.partner_recruited.connect(_on_partner_recruited)

	autoplay_controller.autoplay_toggled.connect(_on_auto_play_changed)

	personal_volley_best_changed.emit(_progression.personal_volley_best)


## Wires Court to a live ball. Called per ball as the reconciler emits `ball_added`, so
## every concurrent ball gets miss/max-speed listeners. The newest ball becomes the
## back-compat `ball` handle and the partner's current target; partner multi-ball
## targeting (nearest projected intercept) is the next layer up; see
## `designs/01-prototype/21-ball-dynamics.md` Q6.
func _attach_ball(new_ball: Ball) -> void:
	if new_ball == null:
		return
	if _balls.has(new_ball):
		return
	_balls.append(new_ball)
	ball = new_ball
	autoplay_controller.ball = ball
	if not new_ball.missed.is_connected(_on_ball_missed):
		new_ball.missed.connect(_on_ball_missed)
	if not new_ball.at_max_speed_changed.is_connected(_on_ball_at_max_speed_changed):
		new_ball.at_max_speed_changed.connect(_on_ball_at_max_speed_changed)
	if new_ball.effect_processor != null:
		var paddles: Array[Node2D] = [player_paddle]
		if partner_paddle != null:
			paddles.append(partner_paddle)
		new_ball.effect_processor.paddles = paddles
	for zone in get_tree().get_nodes_in_group(&"miss_zones"):
		new_ball.register_miss_zone(zone)
	if partner_paddle != null:
		partner_paddle.set_ball(new_ball)


## Detaches Court from a ball that has left the tracked set. Drops the back-compat
## `ball` handle to whichever ball remains, or null if none.
func _detach_ball(old_ball: Ball) -> void:
	if old_ball == null:
		return
	_balls.erase(old_ball)
	if is_instance_valid(old_ball):
		if old_ball.missed.is_connected(_on_ball_missed):
			old_ball.missed.disconnect(_on_ball_missed)
		if old_ball.at_max_speed_changed.is_connected(_on_ball_at_max_speed_changed):
			old_ball.at_max_speed_changed.disconnect(_on_ball_at_max_speed_changed)
	if ball == old_ball:
		ball = _balls.back() if not _balls.is_empty() else null
		autoplay_controller.ball = ball
		if partner_paddle != null and ball != null:
			partner_paddle.set_ball(ball)


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
	# Multi-ball: every live ball shares the rally's friendship energy.
	# Streak is shared, so each tracked ball advances on a paddle hit.
	for tracked in _balls:
		if is_instance_valid(tracked):
			tracked.increase_speed()


func _on_ball_at_max_speed_changed(is_at_max: bool) -> void:
	ball_at_max_speed_changed.emit(is_at_max)
	if is_at_max:
		_item_manager.process_event(&"on_max_speed_reached")


func _on_ball_missed() -> void:
	# process_event before reset_speed: temporary modifiers clear first,
	# then reset uses the post-clear min_speed. Reversing this order would
	# reset to a stale min before modifiers are removed.
	var actions: Array[StringName] = _item_manager.process_event(&"on_miss")
	var should_halve: bool = actions.has(&"halve_streak")

	if should_halve:
		_volley_count = floori(_volley_count / 2.0)
	else:
		_volley_count = 0

	_friendship_point_accumulator = 0.0
	volley_count_changed.emit(_volley_count)

	# Multi-ball: a miss on any ball resets the shared streak's energy across every ball.
	for tracked in _balls:
		if not is_instance_valid(tracked):
			continue
		if should_halve and _volley_count > 0:
			tracked.set_speed_for_streak(_volley_count)
		else:
			tracked.reset_speed()

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
	for tracked in _balls:
		if not is_instance_valid(tracked):
			continue
		if tracked.effect_processor != null:
			tracked.effect_processor.paddles.append(partner_paddle)
	if ball != null:
		partner_paddle.set_ball(ball)

	_item_manager.register_partner(partner_definition)

	if right_wall != null:
		_partner_miss_zone = MissZoneScene.instantiate()
		right_wall.add_child(_partner_miss_zone)
		for tracked in _balls:
			if is_instance_valid(tracked):
				tracked.register_miss_zone(_partner_miss_zone)

	partner_changed.emit()


func _deactivate_partner() -> void:
	if partner_paddle == null:
		return
	if _active_partner_definition != null:
		_item_manager.unregister_partner(_active_partner_definition)

	partner_paddle.paddle_hit.disconnect(_on_paddle_hit)
	for tracked in _balls:
		if is_instance_valid(tracked) and tracked.effect_processor != null:
			tracked.effect_processor.paddles.erase(partner_paddle)
	partner_paddle.queue_free()
	partner_paddle = null
	_active_partner_definition = null

	if _partner_miss_zone != null:
		_partner_miss_zone.queue_free()
		_partner_miss_zone = null

	partner_changed.emit()


## Fractional accumulation;
## remainder from a reduced autoplay rate carries between hits and resets on miss
## a missed rally never pays out
func _accumulate_friendship_points() -> void:
	var rate: float = _progression_config.autoplay_friendship_point_rate
	var base_points: float = _item_manager.get_stat(&"friendship_points_per_hit")
	var points_to_add: float = (base_points * rate) if _is_autoplay_active else base_points
	_friendship_point_accumulator += points_to_add
	var whole_points: int = int(_friendship_point_accumulator)
	if whole_points > 0:
		_item_manager.add_friendship_points(whole_points)
		_friendship_point_accumulator -= float(whole_points)
