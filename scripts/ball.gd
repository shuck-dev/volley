extends RigidBody2D

signal paddle_hit

var _hit_cooldown := 0.0


func _ready() -> void:
	lock_rotation = true
	linear_damp = 0.0
	linear_velocity = Vector2(400.0, 200.0)
	contact_monitor = true
	max_contacts_reported = 1
	body_entered.connect(_on_body_entered)


func _physics_process(_delta: float) -> void:
	if _hit_cooldown > 0.0:
		_hit_cooldown -= _delta

	# Bounce
	var speed := linear_velocity.length()
	if speed < GameRules.BALL_SPEED_MIN:
		linear_velocity = linear_velocity.normalized() * GameRules.BALL_SPEED_MIN
	elif speed > GameRules.BALL_SPEED_MAX:
		linear_velocity = linear_velocity.normalized() * GameRules.BALL_SPEED_MAX


func _on_body_entered(body: Node) -> void:
	if body.name == "Paddle" and _hit_cooldown <= 0.0:
		_hit_cooldown = 0.2
		paddle_hit.emit()
