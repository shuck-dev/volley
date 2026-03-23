extends RigidBody2D

signal missed


func _ready() -> void:
	lock_rotation = true
	linear_damp = 0.0
	linear_velocity = Vector2(400.0, 200.0)
	contact_monitor = true
	max_contacts_reported = 1
	body_entered.connect(_on_body_entered)


func _physics_process(_delta: float) -> void:
	# Bounce
	var speed := linear_velocity.length()
	if speed < GameRules.BALL_SPEED_MIN:
		linear_velocity = linear_velocity.normalized() * GameRules.BALL_SPEED_MIN
	elif speed > GameRules.BALL_SPEED_MAX:
		linear_velocity = linear_velocity.normalized() * GameRules.BALL_SPEED_MAX


func _on_body_entered(body: Node) -> void:
	if body.has_method("on_ball_missed"):
		missed.emit()
	elif body.has_method("on_ball_hit"):
		body.on_ball_hit()


func increase_speed() -> void:
	var speed := linear_velocity.length()
	if speed >= GameRules.BALL_SPEED_MAX:
		return
	speed += GameRules.BALL_SPEED_INCREMENT
	linear_velocity = linear_velocity.normalized() * min(speed, GameRules.BALL_SPEED_MAX)


func reset_speed() -> void:
	linear_velocity = linear_velocity.normalized() * GameRules.BALL_SPEED_MIN
