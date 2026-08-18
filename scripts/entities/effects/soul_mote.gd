class_name SoulMote
extends Area2D

## Color per denomination.
const DENOMINATION_COLORS: Dictionary[int, Color] = {
	100: Color(0.6, 0.2, 0.9),
	1: Color(1.0, 1.0, 1.0),
}

## How fast the mote's heading turns toward the player.
@export var turn_degrees_per_second: float = 240.0

## Speed the mote travels at.
@export var speed: float = 500.0

@export var sprite: Sprite2D

## Soul carried by this individual mote
var soul_value: int = 0

## Direction this mote first travels before steering kicks in; set by SoulBurstHandler so a
## burst's motes fan out in a star pattern instead of overlapping on one heading.
var initial_heading: Vector2 = Vector2.RIGHT

var _heading: Vector2


func _ready() -> void:
	_heading = initial_heading
	body_entered.connect(_on_body_entered)
	if sprite != null:
		sprite.modulate = DENOMINATION_COLORS.get(soul_value, Color.WHITE)


func _physics_process(delta: float) -> void:
	_steer(delta)
	global_position += _heading * speed * delta


func _steer(delta: float) -> void:
	var paddle_position: Variant = BallTracker.get_player_paddle_position()
	if paddle_position == null:
		return

	var target_direction: Vector2 = (paddle_position - global_position).normalized()
	if target_direction == Vector2.ZERO:
		return

	var max_turn_radians: float = deg_to_rad(turn_degrees_per_second) * delta
	var turn_radians: float = clampf(
		_heading.angle_to(target_direction), -max_turn_radians, max_turn_radians
	)
	_heading = _heading.rotated(turn_radians)


func _on_body_entered(body: Node) -> void:
	if not (body is Paddle):
		return

	BallManager.add_soul(soul_value)
	queue_free()
