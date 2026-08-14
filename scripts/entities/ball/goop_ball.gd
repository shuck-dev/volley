class_name GoopBall
extends Ball

const MERGE_GRACE_SECONDS: float = 0.5

var goop_ball_child: PackedScene = load("res://scenes/balls/goop_ball_child.tscn")

var _ball_tracker: Node
var _merge_grace_seconds_left: float = 0.0


func _ready() -> void:
	super._ready()
	_ball_tracker = get_parent()


func _physics_process(delta: float) -> void:
	super._physics_process(delta)

	if _merge_grace_seconds_left > 0.0:
		_merge_grace_seconds_left -= delta


func _on_tier_advanced(_ball: Ball, _tier: int) -> void:
	if _ball_tracker == null:
		return

	_merge_grace_seconds_left = MERGE_GRACE_SECONDS

	var spawn_velocity: Vector2 = linear_velocity.bounce(linear_velocity.orthogonal().normalized())
	_spawn_child.call_deferred(spawn_velocity)


func _spawn_child(spawn_velocity: Vector2) -> void:
	var child: GoopBall = _ball_tracker.spawn_temporary(
		goop_ball_child, global_position, spawn_velocity
	)
	child._merge_grace_seconds_left = MERGE_GRACE_SECONDS


func _on_body_entered(body: Node) -> void:
	super._on_body_entered(body)

	if freeze:
		return

	if body is GoopBall and _ball_tracker != null:
		_merge(body)


func _merge(other: GoopBall) -> void:
	if not is_temporary or other.is_temporary:
		return

	if _merge_grace_seconds_left > 0.0:
		return

	_ball_tracker.free_temporary.call_deferred(self)
