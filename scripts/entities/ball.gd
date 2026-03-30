extends RigidBody2D

signal missed
signal at_max_speed_changed(is_at_max: bool)

var speed: float = 0.0

var _upgrade_manager: Node
var _min_speed: float
var _max_speed: float
var _was_at_max_speed := false


func _ready() -> void:
	if _upgrade_manager == null:
		_upgrade_manager = UpgradeManager
	_min_speed = _upgrade_manager.get_value(UpgradeManager.BALL_SPEED_MIN_KEY)
	_max_speed = _upgrade_manager.get_value(UpgradeManager.BALL_SPEED_MAX_KEY)
	_upgrade_manager.upgrade_level_changed.connect(_on_upgrade_level_changed)
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


func _on_upgrade_level_changed(upgrade_key: String) -> void:
	if upgrade_key == UpgradeManager.BALL_SPEED_MIN_KEY:
		_min_speed = _upgrade_manager.get_value(UpgradeManager.BALL_SPEED_MIN_KEY)
		speed = maxf(speed, _min_speed)
		_apply_speed()
	elif upgrade_key == UpgradeManager.BALL_SPEED_MAX_KEY:
		_max_speed = _upgrade_manager.get_value(UpgradeManager.BALL_SPEED_MAX_KEY)
		speed = minf(speed, _max_speed)
		_apply_speed()


func _apply_speed() -> void:
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
