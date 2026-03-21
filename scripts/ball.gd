extends RigidBody2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	lock_rotation = true
	linear_damp = 0.0
	linear_velocity = Vector2(400.0, 200.0)

func _physics_process(_delta: float) -> void:
	var speed := linear_velocity.length()
	if (speed) < GameRules.BALL_SPEED_MIN:
		linear_velocity = linear_velocity.normalized() * GameRules.BALL_SPEED_MIN
	elif speed > GameRules.BALL_SPEED_MAX:
		linear_velocity = linear_velocity.normalized() * GameRules.BALL_SPEED_MAX
