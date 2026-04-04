class_name Ball
extends RigidBody2D

signal missed
signal at_max_speed_changed(is_at_max: bool)

var speed: float = 0.0
var paddles: Array[Node2D] = []

var _item_manager: Node
var _min_speed: float
var _max_speed: float
var _speed_increment: float
var _was_at_max_speed := false
var _effect_processor: BallEffectProcessor


func _ready() -> void:
	if _item_manager == null:
		_item_manager = ItemManager
	_min_speed = _item_manager.get_stat(&"ball_speed_min")
	_max_speed = _min_speed + _item_manager.get_stat(&"ball_speed_max_range")
	_speed_increment = _item_manager.get_stat(&"ball_speed_increment")
	_setup_effect_processor()
	_ball_setup()


func _physics_process(delta: float) -> void:
	if linear_velocity == Vector2.ZERO:
		return
	if _effect_processor != null:
		_effect_processor.process_frame(delta)
		_emit_max_speed_if_changed()
	linear_velocity = linear_velocity.normalized() * speed


func _on_body_entered(body: Node) -> void:
	if body.has_method("on_ball_missed"):
		missed.emit()
	elif body.has_method("on_ball_hit"):
		body.on_ball_hit()
		if _effect_processor != null:
			_effect_processor.process_hit()


func increase_speed() -> void:
	if speed >= _max_speed:
		return
	speed = min(speed + _speed_increment, _max_speed)
	_apply_speed()


func reset_speed() -> void:
	speed = _min_speed
	_apply_speed()


func _apply_speed() -> void:
	linear_velocity = linear_velocity.normalized() * speed
	_emit_max_speed_if_changed()


func _emit_max_speed_if_changed() -> void:
	var is_at_max: bool = speed >= _max_speed
	if is_at_max != _was_at_max_speed:
		_was_at_max_speed = is_at_max
		at_max_speed_changed.emit(is_at_max)


func _setup_effect_processor() -> void:
	_effect_processor = BallEffectProcessor.new()
	_effect_processor.name = "BallEffectProcessor"
	_effect_processor._item_manager = _item_manager
	add_child(_effect_processor)


func _ball_setup() -> void:
	speed = _min_speed
	lock_rotation = true
	linear_damp = 0.0
	linear_velocity = Vector2(_min_speed, _min_speed * 0.5).normalized() * speed
	contact_monitor = true
	max_contacts_reported = 1
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
