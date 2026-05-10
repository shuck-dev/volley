class_name Ball
extends RigidBody2D

signal missed
signal at_max_speed_changed(is_at_max: bool)
signal speed_changed(speed: float, min_speed: float, max_speed: float)
signal pressed(ball: Ball)
signal play_state_changed(state: PlayState)

enum PlayState {
	STORED,
	PLAY_NORMAL,
	PLAY_ARC,
	OUT_REST,
	OUT_HELD,
}

const SPEED_EMIT_THRESHOLD := 10.0

## Item key this ball represents; the system reads this on adoption to find the matching ItemDefinition.
@export var item_key: String = ""
## Press hit-box radius multiplier on the authored collider; tunable per-instance for forgiving grabs.
@export_range(1.0, 4.0, 0.1) var press_hitbox_inflation: float = 2.4
## Authored Area2D that routes pointer presses; wired from the scene so the press hit-box stays scene-based.
@export var press_area: Area2D
## Per-court tunables; injected by Court at attach time. Falls back to a default at construction.
@export var court_config: CourtConfig

var speed: float = 0.0
var min_speed: float
var max_speed: float
var speed_increment: float
var effect_processor: BallEffectProcessor
var is_temporary: bool = false

var play_state: PlayState = PlayState.PLAY_NORMAL
# Persistent register: first NORMAL->ARC cross sets it; in-ARC speed events update it; relock targets it.
var entry_speed: float = 0.0

var _item_manager: Node
var _was_at_max_speed := false
var _last_emitted_speed: float = 0.0
var _last_emitted_min: float = 0.0
var _last_emitted_max: float = 0.0
var _entry_speed_initialised: bool = false
var _relock_remaining: float = 0.0
var _relock_from_speed: float = 0.0


func _ready() -> void:
	if _item_manager == null:
		_item_manager = ItemManager
	if court_config == null:
		court_config = load("res://scripts/core/court_config.gd").new()
	min_speed = _item_manager.get_stat(&"ball_speed_min")
	max_speed = min_speed + _item_manager.get_stat(&"ball_speed_max_range")
	speed_increment = _item_manager.get_stat(&"ball_speed_increment")
	_setup_effect_processor()
	_ball_setup()


func _physics_process(delta: float) -> void:
	if linear_velocity == Vector2.ZERO:
		return
	effect_processor.process_frame(delta)
	_update_play_state(delta)
	_emit_max_speed_if_changed()
	if _should_emit_speed_changed():
		_emit_speed_changed()
	if play_state == PlayState.PLAY_NORMAL:
		linear_velocity = linear_velocity.normalized() * speed


# State transitions and per-state physics. Crossing is read off the body's current Y vs the bound.
func _update_play_state(delta: float) -> void:
	if play_state != PlayState.PLAY_NORMAL and play_state != PlayState.PLAY_ARC:
		return
	var bound_y: float = court_config.friendship_bound_y
	var above_bound: bool = global_position.y < bound_y
	if above_bound and play_state == PlayState.PLAY_NORMAL:
		_enter_arc()
	elif not above_bound and play_state == PlayState.PLAY_ARC:
		_enter_normal()
	if play_state == PlayState.PLAY_ARC:
		_apply_arc_physics(delta)
	elif _relock_remaining > 0.0:
		_advance_relock_ramp(delta)


func _enter_arc() -> void:
	if not _entry_speed_initialised:
		entry_speed = speed
		_entry_speed_initialised = true
	gravity_scale = 1.0
	play_state = PlayState.PLAY_ARC
	play_state_changed.emit(play_state)


func _enter_normal() -> void:
	gravity_scale = 0.0
	play_state = PlayState.PLAY_NORMAL
	_relock_remaining = 0.0
	if _entry_speed_initialised and court_config.relock_ramp_seconds > 0.0:
		_relock_remaining = court_config.relock_ramp_seconds
		_relock_from_speed = linear_velocity.length()
	elif _entry_speed_initialised:
		speed = entry_speed
		linear_velocity = linear_velocity.normalized() * speed
	play_state_changed.emit(play_state)


## Centripetal bend perpendicular to velocity, X-component toward court centre, magnitude held by re-projection to entry_speed.
func _apply_arc_physics(delta: float) -> void:
	var velocity: Vector2 = linear_velocity
	var current_speed: float = velocity.length()
	if current_speed <= 0.0:
		return
	var direction: Vector2 = velocity / current_speed
	var perpendicular: Vector2 = Vector2(-direction.y, direction.x)
	# Tie-break assumes court centred on world x=0; off-centre venues will need a different reference point.
	# Pick the perpendicular whose X points toward court centre (X=0). Degenerate at pos.x==0: fall back to +Y.
	var pos_x: float = global_position.x
	var wants_negative_x: bool = pos_x > 0.0
	var wants_positive_x: bool = pos_x < 0.0
	if (wants_negative_x and perpendicular.x > 0.0) or (wants_positive_x and perpendicular.x < 0.0):
		perpendicular = -perpendicular
	elif pos_x == 0.0 and perpendicular.y < 0.0:
		perpendicular = -perpendicular
	var bend: Vector2 = (
		perpendicular * (current_speed * court_config.arc_centripetal_coefficient * delta)
	)
	var bent: Vector2 = velocity + bend
	var target_speed: float = entry_speed if _entry_speed_initialised else current_speed
	if bent.length() > 0.0:
		linear_velocity = bent.normalized() * target_speed


func _advance_relock_ramp(delta: float) -> void:
	_relock_remaining = maxf(_relock_remaining - delta, 0.0)
	var ramp_total: float = court_config.relock_ramp_seconds
	var ramp_progress: float = 1.0
	if ramp_total > 0.0:
		ramp_progress = clampf(1.0 - (_relock_remaining / ramp_total), 0.0, 1.0)
	var ramped_speed: float = lerpf(_relock_from_speed, entry_speed, ramp_progress)
	speed = ramped_speed
	linear_velocity = linear_velocity.normalized() * ramped_speed


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
	_track_arc_speed_change()


func reset_speed() -> void:
	speed = min_speed
	_apply_speed()
	_track_arc_speed_change()


func set_speed_for_streak(count: int) -> void:
	speed = min(min_speed + count * speed_increment, max_speed)
	_apply_speed()
	_track_arc_speed_change()


# In ARC, the entry-value register tracks any speed-change event so the post-apex relock
# lands at the post-event speed rather than the pre-apex value.
func _track_arc_speed_change() -> void:
	if play_state == PlayState.PLAY_ARC:
		entry_speed = speed
		_entry_speed_initialised = true


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


func _wire_press_area() -> void:
	if press_area == null:
		return
	var press_shape: CollisionShape2D = null
	for child in press_area.get_children():
		if child is CollisionShape2D:
			press_shape = child
			break
	if press_shape != null:
		var circle: CircleShape2D = press_shape.shape as CircleShape2D
		if circle != null:
			var authored_radius: float = _baseline_collision_radius()
			if authored_radius > 0.0:
				# Duplicate so per-instance inflation does not mutate the shared sub-resource.
				var local_circle: CircleShape2D = circle.duplicate() as CircleShape2D
				local_circle.radius = authored_radius * press_hitbox_inflation
				press_shape.shape = local_circle
	if not press_area.input_event.is_connected(_on_input_event):
		press_area.input_event.connect(_on_input_event)


func _baseline_collision_radius() -> float:
	for child in get_children():
		if child is CollisionShape2D:
			var shape_node: CollisionShape2D = child
			var circle: CircleShape2D = shape_node.shape as CircleShape2D
			if circle == null:
				continue
			var axis_scale: float = maxf(absf(shape_node.scale.x), absf(shape_node.scale.y))
			return circle.radius * maxf(axis_scale, 0.001)
	return 0.0


func _ball_setup() -> void:
	speed = min_speed
	effect_processor.sync_base_speed()
	lock_rotation = true
	gravity_scale = 0.0
	linear_damp = 0.0
	play_state = PlayState.PLAY_NORMAL
	# Reset entry-speed register so a pooled ball doesn't read its previous run's tracked value.
	entry_speed = 0.0
	_entry_speed_initialised = false
	_relock_remaining = 0.0
	_relock_from_speed = 0.0
	linear_velocity = Vector2(min_speed, min_speed * 0.5).normalized() * speed
	contact_monitor = true
	max_contacts_reported = 1
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	# Footgun: a miss firing from PLAY-ARC overwrites the entry-speed register via reset_speed.
	if not missed.is_connected(reset_speed):
		missed.connect(reset_speed)
	# Press routing lives on PressArea; the rigid body stops accepting pointer events.
	input_pickable = false
	if input_event.is_connected(_on_input_event):
		input_event.disconnect(_on_input_event)
	_wire_press_area()


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
