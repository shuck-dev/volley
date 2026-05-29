extends GutTest

# Tests that PaddleAIController self-wires to a BallTracker:
# - ball_added attaches the controller's ball ref
# - ball_removed clears the ball ref but preserves the autoplay toggle
# - set_enabled(true) is a silent no-op when no ball is bound

const BallTrackerScript: GDScript = preload("res://scripts/court/ball_tracker.gd")
const PaddleAIControllerScript: GDScript = preload("res://scripts/core/paddle_ai_controller.gd")

var _tracker: BallTracker
var _controller: PaddleAIController
var _paddle: Paddle
var _config: PaddleAIConfig


func before_each() -> void:
	_tracker = BallTrackerScript.new()
	add_child_autofree(_tracker)

	_paddle = load("res://scripts/entities/paddle.gd").new()
	var sound := AudioStreamPlayer.new()
	_paddle.add_child(sound)
	_paddle.hit_sound = sound
	var hit_tracker: HitTracker = load("res://scripts/core/hit_tracker.gd").new()
	_paddle.tracker = hit_tracker
	_paddle.add_child(hit_tracker)
	add_child_autofree(_paddle)

	_config = PaddleAIConfig.new()
	_config.reaction_delay_frames = 1

	# Use AutoplayController as a concrete subclass; the binding behaviour
	# under test lives on the abstract base, so the choice of subclass is
	# incidental.
	_controller = load("res://scripts/core/autoplay_controller.gd").new()
	_controller.paddle = _paddle
	_controller.config = _config
	add_child_autofree(_controller)


func _spawn_ball() -> Ball:
	var ball: Ball = load("res://tests/stubs/ball_stub.gd").new()
	add_child_autofree(ball)
	return ball


func test_set_enabled_true_is_noop_when_no_ball_bound() -> void:
	_controller.bind_tracker(_tracker)
	assert_null(_controller.ball, "precondition: tracker is empty")

	_controller.set_enabled(true)

	assert_false(_controller.is_enabled(), "set_enabled(true) must refuse with no ball bound")


func test_ball_added_through_tracker_populates_controller_ball() -> void:
	_controller.bind_tracker(_tracker)
	var ball: Ball = _spawn_ball()

	_tracker.attach(ball)

	assert_eq(_controller.ball, ball, "controller picks up the freshly-attached ball")


func test_ball_removed_clears_ball_ref_but_preserves_autoplay_toggle() -> void:
	# Grab + drop replaces the live Ball instance: ball_removed fires for the
	# old ball, ball_added fires for the new one. The autoplay toggle is a
	# player intent that must survive that transient gap.
	_controller.bind_tracker(_tracker)
	var ball: Ball = _spawn_ball()
	_tracker.attach(ball)
	_controller.set_enabled(true)
	assert_true(_controller.is_enabled(), "precondition: controller enabled with ball")

	_tracker.detach(ball)

	assert_null(_controller.ball, "controller drops its ball ref when tracker empties")
	assert_true(_controller.is_enabled(), "autoplay toggle survives transient ball removal")


func test_autoplay_resumes_on_replacement_ball_after_grab_drop_cycle() -> void:
	# Models the grab-drop lifecycle: old Ball detaches, new Ball attaches.
	# The controller must end up bound to the new ball, still enabled.
	_controller.bind_tracker(_tracker)
	var first: Ball = _spawn_ball()
	_tracker.attach(first)
	_controller.set_enabled(true)

	_tracker.detach(first)
	var replacement: Ball = _spawn_ball()
	_tracker.attach(replacement)

	assert_eq(_controller.ball, replacement, "controller rebinds to the replacement ball")
	assert_true(_controller.is_enabled(), "autoplay continues across the grab-drop boundary")


func test_bind_tracker_inherits_already_attached_ball() -> void:
	# A late-bound controller should still see the ball that arrived first.
	var ball: Ball = _spawn_ball()
	_tracker.attach(ball)

	_controller.bind_tracker(_tracker)

	assert_eq(_controller.ball, ball, "binding inherits the tracker's current ball")


func test_partner_bind_to_already_attached_ball_auto_enables() -> void:
	# Mid-rally partner recruitment: Court attaches the ball, then spawns the
	# partner and binds. The partner subclass must auto-enable.
	var ball: Ball = _spawn_ball()
	_tracker.attach(ball)

	var partner: PartnerAIController = load("res://scripts/core/partner_ai_controller.gd").new()
	partner.paddle = _paddle
	partner.config = _config
	add_child_autofree(partner)

	partner.bind_tracker(_tracker)

	assert_true(
		partner.is_enabled(), "partner auto-enables when bound to a tracker that already has a ball"
	)


func test_rebind_to_null_disconnects_prior_signals() -> void:
	_controller.bind_tracker(_tracker)
	_controller.bind_tracker(null)
	var ball: Ball = _spawn_ball()

	_tracker.attach(ball)

	assert_null(_controller.ball, "after unbind, tracker emissions no longer reach controller")


# Autoplay under multi-ball locks onto the soonest-arriving ball it should cover, not the current one.
func test_autoplay_selects_soonest_arriving_ball_under_multiball() -> void:
	_paddle.position = Vector2(0.0, 0.0)
	_controller.bind_tracker(_tracker)

	var far_ball: Ball = _spawn_ball()
	far_ball.position = Vector2(300.0, 0.0)
	far_ball.linear_velocity = Vector2(-100.0, 0.0)
	var near_ball: Ball = _spawn_ball()
	near_ball.position = Vector2(50.0, 0.0)
	near_ball.linear_velocity = Vector2(-200.0, 0.0)
	# Attach far last so the signal-bound ball is far_ball; selection must override it.
	_tracker.attach(near_ball)
	_tracker.attach(far_ball)
	_controller.set_enabled(true)
	assert_eq(
		_controller.ball, far_ball, "precondition: signal-bound ball is the last-attached far ball"
	)

	_controller._physics_process(0.016)

	assert_eq(_controller.ball, near_ball, "autoplay covers the soonest-arriving approaching ball")
