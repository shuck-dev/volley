class_name Ball
extends RigidBody2D

signal missed
signal at_max_speed_changed(is_at_max: bool)
signal speed_changed(speed: float, min_speed: float, max_speed: float)
## Mid-rally grab entry: emitted when the player presses the live ball.
signal pressed(ball: Ball)

const SPEED_EMIT_THRESHOLD := 10.0

## Item key this ball represents; the system reads this on adoption to find the matching ItemDefinition.
@export var item_key: String = ""

var speed: float = 0.0
var min_speed: float
var max_speed: float
var speed_increment: float
var effect_processor: BallEffectProcessor
var is_temporary: bool = false

var _item_manager: Node
var _was_at_max_speed := false
var _last_emitted_speed: float = 0.0
var _last_emitted_min: float = 0.0
var _last_emitted_max: float = 0.0


func _ready() -> void:
	if _item_manager == null:
		_item_manager = ItemManager
	min_speed = _item_manager.get_stat(&"ball_speed_min")
	max_speed = min_speed + _item_manager.get_stat(&"ball_speed_max_range")
	speed_increment = _item_manager.get_stat(&"ball_speed_increment")
	_setup_effect_processor()
	_ball_setup()


func _physics_process(delta: float) -> void:
	if linear_velocity == Vector2.ZERO:
		return
	effect_processor.process_frame(delta)
	_emit_max_speed_if_changed()
	if _should_emit_speed_changed():
		_emit_speed_changed()
	linear_velocity = linear_velocity.normalized() * speed


func _should_emit_speed_changed() -> bool:
	if absf(speed - _last_emitted_speed) >= SPEED_EMIT_THRESHOLD:
		return true
	if not is_equal_approx(min_speed, _last_emitted_min):
		return true
	if not is_equal_approx(max_speed, _last_emitted_max):
		return true
	return false


func _emit_speed_changed() -> void:
	_last_emitted_speed = speed
	_last_emitted_min = min_speed
	_last_emitted_max = max_speed
	speed_changed.emit(speed, min_speed, max_speed)


func _on_body_entered(body: Node) -> void:
	if freeze:
		return
	if body.has_method("on_ball_hit"):
		var hit_registered: bool = body.on_ball_hit()
		if hit_registered:
			increase_speed()
		effect_processor.process_hit()


func register_miss_zone(zone: MissZone) -> void:
	if not zone.body_entered.is_connected(_on_miss_zone_body_entered):
		zone.body_entered.connect(_on_miss_zone_body_entered)


func _on_miss_zone_body_entered(body: Node) -> void:
	if body == self:
		missed.emit()


func increase_speed() -> void:
	if speed >= max_speed:
		return
	speed = min(speed + speed_increment, max_speed)
	_apply_speed()


func reset_speed() -> void:
	speed = min_speed
	_apply_speed()


func set_speed_for_streak(count: int) -> void:
	speed = min(min_speed + count * speed_increment, max_speed)
	_apply_speed()


func _apply_speed() -> void:
	effect_processor.sync_base_speed()
	linear_velocity = linear_velocity.normalized() * speed
	_emit_max_speed_if_changed()
	_emit_speed_changed()


func _emit_max_speed_if_changed() -> void:
	var is_at_max: bool = speed >= max_speed
	if is_at_max != _was_at_max_speed:
		_was_at_max_speed = is_at_max
		at_max_speed_changed.emit(is_at_max)


func _setup_effect_processor() -> void:
	effect_processor = BallEffectProcessor.new()
	effect_processor.name = "BallEffectProcessor"
	effect_processor.ball = self
	effect_processor.item_manager = _item_manager
	add_child(effect_processor)


func _ball_setup() -> void:
	speed = min_speed
	effect_processor.sync_base_speed()
	lock_rotation = true
	linear_damp = 0.0
	linear_velocity = Vector2(min_speed, min_speed * 0.5).normalized() * speed
	contact_monitor = true
	max_contacts_reported = 1
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not missed.is_connected(reset_speed):
		missed.connect(reset_speed)
	input_pickable = true
	if not input_event.is_connected(_on_input_event):
		input_event.connect(_on_input_event)


## Press on the live ball routes through here and surfaces as the `pressed` signal so the drag controller can flip into mid-rally grab mode.
func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if freeze:
		return
	if not (event is InputEventMouseButton):
		return
	var mouse_button: InputEventMouseButton = event
	if mouse_button.button_index != MOUSE_BUTTON_LEFT:
		return
	if not mouse_button.pressed:
		return
	pressed.emit(self)


func has_item_art() -> bool:
	var holder: Node = get_node_or_null("ItemArtHolder")
	return holder != null and is_instance_valid(holder)
