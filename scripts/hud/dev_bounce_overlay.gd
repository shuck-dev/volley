class_name DevBounceOverlay
extends Node2D

## Debug-only overlay: draws the reachable bounce cone on each paddle and a
## post-resolve marker arrow from the last contact point. Subscribes to
## `BallEffectProcessor.bounce_resolved` per ball so the marker echoes the
## resolved direction the ball actually flies.

const MARKER_ARROW_LENGTH := 90.0
const MARKER_ARROW_HEAD := 14.0
const CONE_LENGTH := 140.0
const CONE_EDGE_COLOR := Color(1.0, 1.0, 0.4, 0.55)
const MARKER_DOT_COLOR := Color(1.0, 0.4, 0.4, 0.9)
const MARKER_ARROW_COLOR := Color(0.4, 1.0, 0.6, 0.9)

var dev_visible: bool = false
var follow_last_hit: bool = false

var _tracker: BallTracker
var _ball_subscriptions: Dictionary = {}
# Paddle-relative offset_norm so the marker tracks the paddle: { offset_norm, target_angle, horizontal_sign }.
var _last_hits: Dictionary = {}


func _ready() -> void:
	if not OS.is_debug_build():
		queue_free()
		return

	z_index = 4095
	top_level = true
	visible = false
	add_to_group(&"dev_overlays")

	_tracker = get_tree().get_first_node_in_group(&"ball_trackers") as BallTracker
	if _tracker == null:
		_tracker = await _await_tracker()

	if _tracker == null:
		return

	_tracker.ball_added.connect(_on_ball_added)
	_tracker.ball_removed.connect(_on_ball_removed)
	for ball in _tracker.get_balls():
		_on_ball_added(ball)


func _await_tracker() -> BallTracker:
	while is_inside_tree():
		var found := get_tree().get_first_node_in_group(&"ball_trackers") as BallTracker
		if found != null:
			return found
		await get_tree().process_frame
	return null


func set_dev_visible(value: bool) -> void:
	dev_visible = value
	visible = value
	if value:
		queue_redraw()


func _process(_delta: float) -> void:
	if dev_visible:
		queue_redraw()


func _draw() -> void:
	for paddle: Paddle in get_tree().get_nodes_in_group(&"paddles"):
		if not is_instance_valid(paddle):
			continue
		_draw_cone(paddle)
		_draw_last_hit(paddle)


# Map world to screen via the main canvas (camera applied); overlay's own canvas is the CanvasLayer's, not the world's.
func _project_to_canvas(world_pos: Vector2) -> Vector2:
	return get_viewport().get_canvas_transform() * world_pos


func _draw_cone(paddle: Paddle) -> void:
	var max_degrees: float = Stats.resolve(
		GameRules.paddle.paddle_return_angle_max_degrees, &"paddle_return_angle_max_degrees"
	)
	if max_degrees <= 0.0:
		return

	var half_height: float = paddle.get_half_height()
	if half_height <= 0.0:
		return

	# Cone direction: away from the paddle's lane, toward the centre of the court.
	# Player paddle sits to the right (x>0), bounces left; partner mirrors. Pick by global_position.x sign.
	var return_sign: float = -signf(paddle.global_position.x)
	if return_sign == 0.0:
		return_sign = -1.0

	# Dead-zone floor reads the same tunable as runtime so the inner V tracks the clamp as Josh tunes.
	var min_degrees: float = Stats.resolve(
		GameRules.paddle.paddle_bounce_min_angle_degrees, &"paddle_bounce_min_angle_degrees"
	)
	var floor_rad: float = deg_to_rad(min_degrees)
	var max_degrees_off: float = Stats.resolve(
		GameRules.paddle.paddle_bounce_max_angle_degrees, &"paddle_bounce_max_angle_degrees"
	)
	var ceil_rad: float = deg_to_rad(max_degrees_off)
	var requested_rad: float = deg_to_rad(max_degrees)
	# Reachable cone half-angle is the requested max, clamped by the global floor/ceiling.
	var reachable: float = clampf(requested_rad, floor_rad, ceil_rad)

	# In follow mode the cone slides along the paddle to the last contact offset; falls back to absolute if no hit recorded yet.
	var origin_world: Vector2 = paddle.global_position
	if follow_last_hit and _last_hits.has(paddle):
		var hit: Dictionary = _last_hits[paddle]
		var offset_norm: float = hit["offset_norm"]
		origin_world.y += offset_norm * half_height
	var origin: Vector2 = _project_to_canvas(origin_world)
	var upper := Vector2(return_sign * cos(reachable), -sin(reachable)) * CONE_LENGTH
	var lower := Vector2(return_sign * cos(reachable), sin(reachable)) * CONE_LENGTH
	var floor_upper := Vector2(return_sign * cos(floor_rad), -sin(floor_rad)) * CONE_LENGTH
	var floor_lower := Vector2(return_sign * cos(floor_rad), sin(floor_rad)) * CONE_LENGTH

	# Edge lines mark the ceiling; thin secondary lines mark the floor.
	draw_line(origin, origin + upper, CONE_EDGE_COLOR, 1.5)
	draw_line(origin, origin + lower, CONE_EDGE_COLOR, 1.5)
	draw_line(origin, origin + floor_upper, CONE_EDGE_COLOR * Color(1, 1, 1, 0.5), 1.0)
	draw_line(origin, origin + floor_lower, CONE_EDGE_COLOR * Color(1, 1, 1, 0.5), 1.0)


func _draw_last_hit(paddle: Paddle) -> void:
	if not _last_hits.has(paddle):
		return
	var hit: Dictionary = _last_hits[paddle]
	# Recompute contact world position fresh each frame so the marker stays glued to the paddle.
	var offset_norm: float = hit["offset_norm"]
	var contact_y_world: float = paddle.global_position.y + offset_norm * paddle.get_half_height()
	var world_contact := Vector2(paddle.global_position.x, contact_y_world)
	var contact: Vector2 = _project_to_canvas(world_contact)
	var target_angle: float = hit["target_angle"]
	var horizontal_sign: float = hit["horizontal_sign"]
	var direction := Vector2(horizontal_sign * cos(target_angle), sin(target_angle))
	var tip: Vector2 = contact + direction * MARKER_ARROW_LENGTH

	draw_circle(contact, 4.0, MARKER_DOT_COLOR)
	draw_line(contact, tip, MARKER_ARROW_COLOR, 2.0)
	# Two short barbs forming the arrowhead.
	var back: Vector2 = -direction
	var perp := Vector2(-direction.y, direction.x)
	draw_line(tip, tip + (back + perp) * MARKER_ARROW_HEAD * 0.5, MARKER_ARROW_COLOR, 2.0)
	draw_line(tip, tip + (back - perp) * MARKER_ARROW_HEAD * 0.5, MARKER_ARROW_COLOR, 2.0)


func _on_ball_added(ball: Ball) -> void:
	if ball == null or _ball_subscriptions.has(ball):
		return
	if ball.effect_processor == null:
		# Effect processor spawns in Ball._ready; defer one frame.
		await get_tree().process_frame
		if not is_instance_valid(ball) or ball.effect_processor == null:
			return
	var callable := _on_bounce_resolved
	ball.effect_processor.bounce_resolved.connect(callable)
	_ball_subscriptions[ball] = callable


func _on_ball_removed(ball: Ball) -> void:
	if not _ball_subscriptions.has(ball):
		return
	var callable: Callable = _ball_subscriptions[ball]
	if (
		is_instance_valid(ball)
		and ball.effect_processor != null
		and ball.effect_processor.bounce_resolved.is_connected(callable)
	):
		ball.effect_processor.bounce_resolved.disconnect(callable)
	_ball_subscriptions.erase(ball)


func _on_bounce_resolved(
	struck_paddle: Paddle,
	offset_norm: float,
	target_angle: float,
	_incoming_y_sign: float,
	horizontal_sign: float,
) -> void:
	if not is_instance_valid(struck_paddle):
		return
	_last_hits[struck_paddle] = {
		"offset_norm": offset_norm,
		"target_angle": target_angle,
		"horizontal_sign": horizontal_sign,
	}
