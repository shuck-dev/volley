class_name GoopBall
extends Ball

const MERGE_GRACE_SECONDS: float = 0.5

var _reconciler: BallReconciler
var _merge_grace_seconds_left: float = 0.0


func _ready() -> void:
	super._ready()
	_reconciler = get_parent() as BallReconciler


func _physics_process(delta: float) -> void:
	super._physics_process(delta)

	if _merge_grace_seconds_left > 0.0:
		_merge_grace_seconds_left -= delta


func _on_tier_advanced(_ball: Ball, _tier: int) -> void:
	if _reconciler == null:
		return

	_merge_grace_seconds_left = MERGE_GRACE_SECONDS

	var spawn_velocity: Vector2 = linear_velocity.bounce(linear_velocity.orthogonal().normalized())
	_reconciler.spawn_sibling.call_deferred(
		BallKey.base_key(ball_key), global_position, spawn_velocity
	)


func _on_body_entered(body: Node) -> void:
	super._on_body_entered(body)

	if freeze:
		return

	if body is GoopBall and _reconciler != null:
		if _merge_grace_seconds_left > 0.0 or body._merge_grace_seconds_left > 0.0:
			return

		_reconciler.free_ball.call_deferred(ball_key)
