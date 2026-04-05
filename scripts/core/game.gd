class_name Game
extends Node2D

signal volley_count_changed(count: int)
signal personal_volley_best_changed(best: int)
signal ball_at_max_speed_changed(is_at_max: bool)
signal ball_speed_updated(
	current_speed: float, min_speed: float, max_speed: float, base_max_speed: float
)
signal auto_play_changed(is_active: bool, friendship_point_rate: float)

@export var ball: Ball
@export var paddle: Paddle
@export var autoplay_controller: AutoplayController
@export var autoplay_config: AutoPlayConfig

var _volley_count := 0
var _progression: ProgressionData
var _item_manager: Node
var _is_autoplay_active := false
var _friendship_point_accumulator := 0.0


func _ready() -> void:
	assert(autoplay_controller != null, "game.gd: autoplay_controller export must be assigned")
	assert(autoplay_config != null, "game.gd: autoplay_config export must be assigned")
	if _progression == null:
		_progression = SaveManager.get_progression_data()
	if _item_manager == null:
		_item_manager = ItemManager

	ball.effect_processor.paddles = [paddle]
	paddle.paddle_hit.connect(_on_paddle_hit)
	ball.missed.connect(_on_ball_missed)
	ball.at_max_speed_changed.connect(_on_ball_at_max_speed_changed)

	autoplay_controller.autoplay_toggled.connect(_on_auto_play_changed)

	personal_volley_best_changed.emit(_progression.personal_volley_best)


func _process(delta: float) -> void:
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
	_item_manager.process_event(&"on_miss")
	_volley_count = 0
	_friendship_point_accumulator = 0.0
	volley_count_changed.emit(_volley_count)
	ball.reset_speed()
	paddle.reset_streak()


func _on_auto_play_changed(is_active: bool) -> void:
	_is_autoplay_active = is_active
	auto_play_changed.emit(is_active, autoplay_config.friendship_point_rate)


## Fractional accumulation;
## remainder from a reduced autoplay rate carries between hits and resets on miss
## a missed rally never pays out
func _accumulate_friendship_points() -> void:
	var points_to_add: float = autoplay_config.friendship_point_rate if _is_autoplay_active else 1.0
	_friendship_point_accumulator += points_to_add
	var whole_points: int = int(_friendship_point_accumulator)
	if whole_points > 0:
		_item_manager.add_friendship_points(whole_points)
		_friendship_point_accumulator -= float(whole_points)
