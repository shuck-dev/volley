class_name Game
extends Node2D

signal volley_count_changed(count: int)
signal personal_volley_best_changed(best: int)
signal ball_at_max_speed_changed(is_at_max: bool)
signal ball_speed_updated(
	current_speed: float, min_speed: float, max_speed: float, base_max_speed: float
)
signal auto_play_changed(is_active: bool, friendship_point_rate: float)
signal partner_changed

@export var ball: Ball
@export var player_paddle_scene: PackedScene
@export var player_spawn: Marker2D
@export var autoplay_controller: AutoplayController
@export var right_wall: MissZone
@export var partner_spawn: Marker2D

var player_paddle: Paddle
var partner_paddle: PartnerPaddle

var _volley_count := 0
var _active_partner_definition: Resource
var _progression: ProgressionData
var _progression_config: ProgressionConfig
var _item_manager: Node
var _is_autoplay_active := false
var _friendship_point_accumulator := 0.0


func _ready() -> void:
	assert(autoplay_controller != null, "game.gd: autoplay_controller export must be assigned")
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

	autoplay_controller.ball = ball
	autoplay_controller.paddle = player_paddle
	player_paddle.paddle_hit.connect(_on_paddle_hit)
	ball.effect_processor.paddles = [player_paddle]

	if _progression.active_partner != &"":
		_activate_partner()

	ProgressionManager.partner_recruited.connect(_on_partner_recruited)

	ball.missed.connect(_on_ball_missed)
	ball.at_max_speed_changed.connect(_on_ball_at_max_speed_changed)

	autoplay_controller.autoplay_toggled.connect(_on_auto_play_changed)

	personal_volley_best_changed.emit(_progression.personal_volley_best)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_autoplay"):
		autoplay_controller.toggle()


func _physics_process(delta: float) -> void:
	_item_manager.process_frame(delta)
	var base_min: float = _item_manager.get_base_stat(&"ball_speed_min")
	var base_max_range: float = _item_manager.get_base_stat(&"ball_speed_max_range")
	ball_speed_updated.emit(ball.speed, ball.min_speed, ball.max_speed, base_min + base_max_range)


func _on_paddle_hit() -> void:
	_volley_count += 1
	_accumulate_friendship_points()

	if _volley_count > _progression.personal_volley_best:
		_progression.personal_volley_best = _volley_count
		personal_volley_best_changed.emit(_progression.personal_volley_best)

	volley_count_changed.emit(_volley_count)
	ball.increase_speed()


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
		_volley_count = _volley_count / 2
	else:
		_volley_count = 0

	_friendship_point_accumulator = 0.0
	volley_count_changed.emit(_volley_count)

	if should_halve and _volley_count > 0:
		ball.set_speed_for_streak(_volley_count)
	else:
		ball.reset_speed()

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
	ball.effect_processor.paddles.append(partner_paddle)
	partner_paddle.set_ball(ball)

	_item_manager.register_partner(partner_definition)

	if right_wall != null:
		right_wall.active = true

	partner_changed.emit()


func _deactivate_partner() -> void:
	if partner_paddle == null:
		return
	if _active_partner_definition != null:
		_item_manager.unregister_partner(_active_partner_definition)

	partner_paddle.paddle_hit.disconnect(_on_paddle_hit)
	ball.effect_processor.paddles.erase(partner_paddle)
	partner_paddle.queue_free()
	partner_paddle = null
	_active_partner_definition = null

	if right_wall != null:
		right_wall.active = false

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
