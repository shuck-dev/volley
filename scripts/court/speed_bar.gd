@tool
extends Control

const BAR_COLOR := Color(0.4, 0.7, 1.0)
const BAR_OVERFLOW_COLOR := Color(1.0, 0.5, 0.2)
const BAR_BACKGROUND_COLOR := Color(0.15, 0.15, 0.15, 0.6)
const PERMANENT_MAX_MARKER_COLOR := Color(1.0, 1.0, 1.0, 0.4)

@export var court: Court

var current_speed: float = 0.0
var _min_speed: float = 400.0
var _max_speed: float = 700.0
var _permanent_max_speed: float = _max_speed


func _ready() -> void:
	if Engine.is_editor_hint():
		current_speed = 550.0
		return
	_min_speed = GameRules.base_stats[&"ball_speed_min"]
	_max_speed = _min_speed + GameRules.base_stats[&"ball_speed_max_range"]
	_permanent_max_speed = _max_speed
	court.ball_speed_updated.connect(update_speed)


func _draw() -> void:
	_draw_background()

	var speed_range: float = _max_speed - _min_speed
	if speed_range <= 0.0:
		return

	var fill_ratio: float = clampf((current_speed - _min_speed) / speed_range, 0.0, 1.0)
	var permanent_ratio: float = clampf((_permanent_max_speed - _min_speed) / speed_range, 0.0, 1.0)

	_draw_fill(fill_ratio, permanent_ratio)
	_draw_permanent_max_marker(permanent_ratio)


func _draw_background() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), BAR_BACKGROUND_COLOR)


func _draw_fill(fill_ratio: float, permanent_ratio: float) -> void:
	var fill_width: float = size.x * fill_ratio
	if fill_width <= 0.0:
		return

	var ceiling_raised: bool = _max_speed > _permanent_max_speed
	var speed_past_permanent: bool = current_speed > _permanent_max_speed

	if ceiling_raised and speed_past_permanent:
		var permanent_x: float = size.x * permanent_ratio
		_draw_normal_fill(minf(fill_width, permanent_x))
		_draw_overflow_fill(permanent_x, fill_width)
	else:
		_draw_normal_fill(fill_width)


func _draw_normal_fill(width: float) -> void:
	draw_rect(Rect2(0, 0, width, size.y), BAR_COLOR)


func _draw_overflow_fill(permanent_x: float, fill_width: float) -> void:
	if fill_width > permanent_x:
		draw_rect(Rect2(permanent_x, 0, fill_width - permanent_x, size.y), BAR_OVERFLOW_COLOR)


func _draw_permanent_max_marker(permanent_ratio: float) -> void:
	if _max_speed <= _permanent_max_speed:
		return
	var permanent_x: float = size.x * permanent_ratio
	draw_line(
		Vector2(permanent_x, 0), Vector2(permanent_x, size.y), PERMANENT_MAX_MARKER_COLOR, 2.0
	)


func update_speed(
	new_speed: float, min_speed: float, max_speed: float, permanent_max_speed: float
) -> void:
	current_speed = new_speed
	_min_speed = min_speed
	_max_speed = max_speed
	_permanent_max_speed = permanent_max_speed
	queue_redraw()
