extends GutTest

## Previews are stored before they enter the tree; _ready must not serve them out from under the caller.

const BallScene: PackedScene = preload("res://scenes/balls/standard_ball.tscn")
const CadenceScene: PackedScene = preload("res://scenes/balls/cadence_ball.tscn")


func _store_detached(scene: PackedScene) -> Ball:
	var holder := Node2D.new()
	var ball: Ball = scene.instantiate() as Ball
	holder.add_child(ball)
	ball.enter_stored()
	add_child_autofree(holder)
	return ball


func test_stored_preview_stays_stored_after_entering_tree() -> void:
	var ball: Ball = _store_detached(BallScene)

	await wait_physics_frames(2)

	assert_eq(ball.play_state, Ball.PlayState.STORED)
	assert_eq(ball.linear_velocity, Vector2.ZERO)


func test_stored_cadence_preview_does_not_run_its_cycle() -> void:
	var ball: CadenceBall = _store_detached(CadenceScene) as CadenceBall

	await wait_physics_frames(2)

	assert_eq(ball.play_state, Ball.PlayState.STORED)
	assert_false(ball.shift_cue.emitting, "a stored preview should not fire its shift cue")


func test_ball_left_at_its_default_serves_itself() -> void:
	var ball: Ball = BallScene.instantiate() as Ball
	add_child_autofree(ball)

	await wait_physics_frames(2)

	assert_eq(ball.play_state, Ball.PlayState.PLAY_NORMAL)
	assert_ne(ball.linear_velocity, Vector2.ZERO)
