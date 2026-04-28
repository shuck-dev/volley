extends GutTest

# Tests that PaddleAIController self-wires to a BallTracker:
# - ball_added attaches the controller's ball ref
# - ball_removed detaches and disables when no balls remain
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


func test_ball_removed_clears_ball_and_disables_when_tracker_empties() -> void:
	_controller.bind_tracker(_tracker)
	var ball: Ball = _spawn_ball()
	_tracker.attach(ball)
	_controller.set_enabled(true)
	assert_true(_controller.is_enabled(), "precondition: controller enabled with ball")

	_tracker.detach(ball)

	assert_null(_controller.ball, "controller drops its ball ref when tracker empties")
	assert_false(_controller.is_enabled(), "controller auto-disables when the last ball departs")


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
