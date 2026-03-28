extends RigidBody2D

signal missed

var speed := GameRules.BALL_SPEED_MIN


func _ready() -> void:
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
	if speed >= GameRules.BALL_SPEED_MAX:
		return
	speed = min(speed + GameRules.BALL_SPEED_INCREMENT, GameRules.BALL_SPEED_MAX)
	linear_velocity = linear_velocity.normalized() * speed


func reset_speed() -> void:
	speed = GameRules.BALL_SPEED_MIN
	linear_velocity = linear_velocity.normalized() * speed


func _ball_setup() -> void:
	lock_rotation = true
	linear_damp = 0.0
	linear_velocity = Vector2(400.0, 200.0).normalized() * speed
	contact_monitor = true
	max_contacts_reported = 1
	body_entered.connect(_on_body_entered)
