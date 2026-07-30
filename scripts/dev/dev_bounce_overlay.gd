class_name DevBounceOverlay
extends Node2D

## Debug overlay: paddle bounce cones and a resolved-direction marker per last hit.

const MARKER_ARROW_LENGTH := 90.0
const MARKER_ARROW_HEAD := 14.0
const CONE_LENGTH := 140.0
const CONE_EDGE_COLOR := Color(1.0, 1.0, 0.4, 0.55)
const MARKER_DOT_COLOR := Color(1.0, 0.4, 0.4, 0.9)
const MARKER_ARROW_COLOR := Color(0.4, 1.0, 0.6, 0.9)

var dev_visible: bool = false
var follow_last_hit: bool = false

var _paddles: Array[Paddle] = []
var _paddle_subscriptions: Dictionary = {}
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


## Pushed by DevHud whenever the active paddle roster changes.
func set_paddles(paddles: Array[Paddle]) -> void:
	for paddle in _paddle_subscriptions.keys():
		var callable: Callable = _paddle_subscriptions[paddle]
		if is_instance_valid(paddle) and paddle.paddle_hit.is_connected(callable):
			paddle.paddle_hit.disconnect(callable)
	_paddle_subscriptions.clear()

	_paddles = paddles
	for paddle in paddles:
		if paddle == null or _paddle_subscriptions.has(paddle):
			continue
		var callable := _on_paddle_hit.bind(paddle)
		paddle.paddle_hit.connect(callable)
		_paddle_subscriptions[paddle] = callable


func set_dev_visible(value: bool) -> void:
	dev_visible = value
	visible = value

	if value:
		queue_redraw()


func _process(_delta: float) -> void:
	if dev_visible:
		queue_redraw()


func _draw() -> void:
	for paddle in _paddles:
		if not is_instance_valid(paddle):
			continue
		_draw_cone(paddle)
		_draw_last_hit(paddle)


# Map world to screen via the main canvas (camera applied); overlay's own canvas is the CanvasLayer's, not the world's.
func _project_to_canvas(world_pos: Vector2) -> Vector2:
	return get_viewport().get_canvas_transform() * world_pos


func _draw_cone(paddle: Paddle) -> void:
	var max_degrees: float = GameRules.paddle.paddle_return_angle_max_degrees

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

	var floor_rad: float = deg_to_rad(PaddleBounceMath.BOUNCE_MIN_ANGLE_DEGREES)
	var ceil_rad: float = deg_to_rad(PaddleBounceMath.BOUNCE_MAX_ANGLE_DEGREES)
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


## Independently recomputes the bounce Ball just resolved, rather than Ball reporting it back.
func _on_paddle_hit(ball: Ball, struck_paddle: Paddle) -> void:
	if ball == null or not is_instance_valid(struck_paddle):
		return

	var horizontal_sign: float = PaddleBounceMath.reverse_incoming_direction(ball.linear_velocity)
	if horizontal_sign == 0.0:
		return

	var return_angle_max_degrees: float = GameRules.paddle.paddle_return_angle_max_degrees
	var offset_norm: float = (
		PaddleBounceMath
		. contact_placement(
			ball.global_position,
			struck_paddle.global_position,
			struck_paddle.get_half_height(),
			return_angle_max_degrees,
		)
	)
	var placement_angle: float = offset_norm * deg_to_rad(return_angle_max_degrees)
	var target_angle: float = (
		PaddleBounceMath
		. clamp_to_legal_bounce_range(
			placement_angle,
			signf(ball.linear_velocity.y),
			PaddleBounceMath.BOUNCE_MIN_ANGLE_DEGREES,
			PaddleBounceMath.BOUNCE_MAX_ANGLE_DEGREES,
		)
	)

	_last_hits[struck_paddle] = {
		"offset_norm": offset_norm,
		"target_angle": target_angle,
		"horizontal_sign": horizontal_sign,
	}
