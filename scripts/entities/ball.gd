class_name Ball
extends RigidBody2D

signal missed
signal at_max_speed_changed(is_at_max: bool)
signal speed_changed(speed: float, min_speed: float, max_speed: float)
## Mid-rally grab entry: emitted when the player presses the live ball.
signal pressed(ball: Ball)

const SPEED_EMIT_THRESHOLD := 10.0

var speed: float = 0.0
var min_speed: float
var max_speed: float
var speed_increment: float
var effect_processor: BallEffectProcessor
var is_temporary: bool = false
var _dragging: bool = false
var _item_art: Node2D = null

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
	if _dragging:
		return
	if body.has_method("on_ball_hit"):
		body.on_ball_hit()
		effect_processor.process_hit()


## Suppresses hit processing while a drag gesture owns this ball; BallDragController toggles it on mid-rally grabs before the ball is freed.
func set_dragging(value: bool) -> void:
	_dragging = value


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
	input_pickable = true
	if not input_event.is_connected(_on_input_event):
		input_event.connect(_on_input_event)


## Press on the live ball routes through here and surfaces as the `pressed` signal so the drag controller can flip into mid-rally grab mode.
func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if _dragging:
		return
	if not (event is InputEventMouseButton):
		return
	var mouse_button: InputEventMouseButton = event
	if mouse_button.button_index != MOUSE_BUTTON_LEFT:
		return
	if not mouse_button.pressed:
		return
	pressed.emit(self)


## Replaces the default sprite with the item's authored art so the live ball reads as the same object the player grabbed.
## The art is parented under a scaled holder so the live ball matches the canonical token size (SH-261).
func apply_item_art(art_scene: PackedScene, token_scale: Vector2 = Vector2.ONE) -> void:
	if art_scene == null:
		return
	if _item_art != null and is_instance_valid(_item_art):
		_item_art.queue_free()
	var holder: Node2D = Node2D.new()
	holder.name = "ItemArtHolder"
	holder.scale = token_scale
	var instance: Node = art_scene.instantiate()
	holder.add_child(instance)
	if instance is Node2D:
		_item_art = instance
	add_child(holder)
	var default_sprite: Node = get_node_or_null("Sprite")
	if default_sprite != null:
		default_sprite.visible = false


func has_item_art() -> bool:
	return _item_art != null and is_instance_valid(_item_art)
