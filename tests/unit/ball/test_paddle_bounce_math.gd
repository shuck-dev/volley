extends GutTest

# Tests that paddle-contact offset drives the return angle: centre returns flat, edges steepen.

const PADDLE_HALF_HEIGHT := 27.0
const MAX_DEGREES := 30.0
const MIN_DEGREES := PaddleBounceMath.BOUNCE_MIN_ANGLE_DEGREES


func _resolve(ball_velocity: Vector2, ball_position: Vector2) -> Variant:
	return PaddleBounceMath.bounce_direction(
		ball_velocity, ball_position, Vector2.ZERO, PADDLE_HALF_HEIGHT, MAX_DEGREES
	)


# --- offset-driven angle ---
func test_centre_hit_returns_within_min_angle_band() -> void:
	# Centre hit: the min-angle clamp keeps the bounce off pure horizontal.
	var direction: Vector2 = _resolve(Vector2(100, 60), Vector2(0, 0))

	var angle: float = atan2(absf(direction.y), absf(direction.x))
	assert_almost_eq(rad_to_deg(angle), MIN_DEGREES, 0.01)
	assert_lt(direction.x, 0.0, "rightward incoming returns leftward")


func test_edge_hit_steepens_vs_centre() -> void:
	var centre: Vector2 = _resolve(Vector2(100, 0), Vector2(0, 0))
	var centre_slope: float = absf(centre.y / centre.x)

	# Top-edge hit (ball above paddle centre).
	var edge: Vector2 = _resolve(Vector2(100, 0), Vector2(0, -PADDLE_HALF_HEIGHT))
	var edge_slope: float = absf(edge.y / edge.x)

	assert_gt(edge_slope, centre_slope, "Edge contact should steepen the return angle")


func test_symmetric_edges_mirror() -> void:
	var top: Vector2 = _resolve(Vector2(100, 0), Vector2(0, -PADDLE_HALF_HEIGHT))
	var bottom: Vector2 = _resolve(Vector2(100, 0), Vector2(0, PADDLE_HALF_HEIGHT))

	assert_almost_eq(top.y, -bottom.y, 0.01)


func test_direction_is_unit_length() -> void:
	var direction: Vector2 = _resolve(Vector2(100, 80), Vector2(0, -PADDLE_HALF_HEIGHT))

	assert_almost_eq(direction.length(), 1.0, 0.01)


# --- centre-hit tiebreaker: incoming y-direction carries through ---
func test_descending_ball_centre_hit_returns_downward() -> void:
	# Dead-centre on a still paddle: incoming descending y should keep the bounce descending.
	var direction: Vector2 = _resolve(Vector2(100, 60), Vector2(0, 0))

	assert_gt(direction.y, 0.0, "Descending centre hit should leave descending")
	var angle: float = atan2(direction.y, absf(direction.x))
	assert_almost_eq(rad_to_deg(angle), MIN_DEGREES, 0.01)


func test_ascending_ball_centre_hit_returns_upward() -> void:
	var direction: Vector2 = _resolve(Vector2(100, -60), Vector2(0, 0))

	assert_lt(direction.y, 0.0, "Ascending centre hit should leave ascending")
	var angle: float = atan2(-direction.y, absf(direction.x))
	assert_almost_eq(rad_to_deg(angle), MIN_DEGREES, 0.01)


func test_horizontal_incoming_centre_hit_defaults_downward() -> void:
	# Degenerate case: both target angle and incoming y are zero; default to +min_angle.
	var direction: Vector2 = _resolve(Vector2(100, 0), Vector2(0, 0))

	assert_gt(direction.y, 0.0, "Default tiebreaker should send bounce below horizontal")
	var angle: float = atan2(direction.y, absf(direction.x))
	assert_almost_eq(rad_to_deg(angle), MIN_DEGREES, 0.01)


func test_no_horizontal_motion_returns_null() -> void:
	var direction: Variant = PaddleBounceMath.bounce_direction(
		Vector2(0, 60), Vector2(0, 0), Vector2.ZERO, PADDLE_HALF_HEIGHT, MAX_DEGREES
	)

	assert_null(direction, "A ball with no horizontal velocity has no direction to reverse")
