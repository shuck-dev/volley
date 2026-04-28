@tool
extends Control

const BAR_COLOR := Color(0.4, 0.7, 1.0)
const BAR_OVERFLOW_COLOR := Color(1.0, 0.5, 0.2)
const BAR_BACKGROUND_COLOR := Color(0.15, 0.15, 0.15, 0.6)
const PERMANENT_MAX_MARKER_COLOR := Color(1.0, 1.0, 1.0, 0.4)

@export var ball_system: BallReconciler

## Back-compat seam for tests; production sets this through the reconciler's `ball_added`.
var ball: Ball
var current_speed: float = 0.0

## Multi-ball: bar shows highest live speed across the set, not the most-recently-emitting ball.
var _balls: Array[Ball] = []
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
	if ball_system != null:
		ball_system.ball_added.connect(_attach_ball)
		ball_system.ball_removed.connect(_detach_ball)
	if ball != null and not _balls.has(ball):
		var pre_set: Ball = ball
		ball = null
		_attach_ball(pre_set)
	ItemManager.item_level_changed.connect(_on_item_level_changed.unbind(1))


func _attach_ball(new_ball: Ball) -> void:
	if new_ball == null or _balls.has(new_ball):
		return
	_balls.append(new_ball)
	ball = new_ball
	if not new_ball.speed_changed.is_connected(_on_ball_speed_changed):
		new_ball.speed_changed.connect(_on_ball_speed_changed)


func _detach_ball(old_ball: Ball) -> void:
	if old_ball == null:
		return
	_balls.erase(old_ball)
	if is_instance_valid(old_ball) and old_ball.speed_changed.is_connected(_on_ball_speed_changed):
		old_ball.speed_changed.disconnect(_on_ball_speed_changed)
	if ball == old_ball:
		ball = _balls.back() if not _balls.is_empty() else null
	# A removed ball's speed no longer counts; rebuild the reading from what remains.
	_recompute_from_tracked()


func _on_ball_speed_changed(new_speed: float, min_speed: float, max_speed: float) -> void:
	# Multi-ball: the bar shows the highest live-ball speed; min/max bands track the
	# emitting ball, which is fine because every ball reads the same ItemManager stats.
	var highest: float = new_speed
	for tracked in _balls:
		if is_instance_valid(tracked) and tracked.speed > highest:
			highest = tracked.speed
	if (
		is_equal_approx(highest, current_speed)
		and is_equal_approx(min_speed, _min_speed)
		and is_equal_approx(max_speed, _max_speed)
	):
		return
	current_speed = highest
	_min_speed = min_speed
	_max_speed = max_speed
	queue_redraw()


## Prevents `current_speed` latching on a value the removed ball last emitted.
func _recompute_from_tracked() -> void:
	var highest: float = _min_speed
	for tracked in _balls:
		if is_instance_valid(tracked) and tracked.speed > highest:
			highest = tracked.speed
	if is_equal_approx(highest, current_speed):
		return
	current_speed = highest
	queue_redraw()


func _on_item_level_changed() -> void:
	var base_min: float = ItemManager.get_base_stat(&"ball_speed_min")
	var base_max_range: float = ItemManager.get_base_stat(&"ball_speed_max_range")
	_permanent_max_speed = base_min + base_max_range
	queue_redraw()


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
