class_name Ball
extends RigidBody2D

signal missed
signal at_max_speed_changed(is_at_max: bool)

var speed: float = 0.0

var _item_manager
var _min_speed: float
var _max_speed: float
var _was_at_max_speed := false


func _ready() -> void:
	if _item_manager == null:
		_item_manager = ItemManager
	_min_speed = _item_manager.get_stat(&"ball_speed_min")
	_max_speed = _item_manager.get_stat(&"ball_speed_max")
	_item_manager.item_level_changed.connect(_on_item_level_changed)
	_ball_setup()


func _physics_process(_delta: float) -> void:
	# Enforce tracked speed every frame to resist physics drift.
	if linear_velocity != Vector2.ZERO:
		linear_velocity = linear_velocity.normalized() * speed


func _on_body_entered(body: Node) -> void:
	if body.has_method("on_ball_missed"):
		missed.emit()
	elif body.has_method("on_ball_hit"):
		body.on_ball_hit()


func increase_speed() -> void:
	if speed >= _max_speed:
		return
	speed = min(speed + GameRules.BALL_SPEED_INCREMENT, _max_speed)
	_apply_speed()


func reset_speed() -> void:
	speed = _min_speed
	_apply_speed()


func _on_item_level_changed(item_key: String) -> void:
	if item_key == "ball_speed_min":
		var previous_min_speed := _min_speed
		_min_speed = _item_manager.get_stat(&"ball_speed_min")
		_max_speed = _item_manager.get_stat(&"ball_speed_max")
		speed += _min_speed - previous_min_speed
		_apply_speed()
	elif item_key == "ball_speed_max":
		_max_speed = _item_manager.get_stat(&"ball_speed_max")
		speed = minf(speed, _max_speed)
		_apply_speed()


func _apply_speed() -> void:
	# If the ball is stationary (pre-launch), normalized() returns Vector2.ZERO
	# and velocity stays zero. Speed is still updated and takes effect on launch.
	linear_velocity = linear_velocity.normalized() * speed
	_emit_max_speed_if_changed()


func _emit_max_speed_if_changed() -> void:
	var is_at_max: bool = speed >= _max_speed
	if is_at_max != _was_at_max_speed:
		_was_at_max_speed = is_at_max
		at_max_speed_changed.emit(is_at_max)


func _ball_setup() -> void:
	speed = _min_speed
	lock_rotation = true
	linear_damp = 0.0
	linear_velocity = Vector2(400.0, 200.0).normalized() * speed
	contact_monitor = true
	max_contacts_reported = 1
	body_entered.connect(_on_body_entered)
