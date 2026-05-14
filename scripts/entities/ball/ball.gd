class_name Ball
extends RigidBody2D

signal missed
signal at_max_speed_changed(is_at_max: bool)
signal speed_changed(speed: float, min_speed: float, max_speed: float)
signal grabbed(ball: Ball)
signal play_state_changed(state: PlayState)

enum PlayState {
	STORED,
	PLAY_NORMAL,
	PLAY_ARC,
	OUT_REST,
	OUT_HELD,
}

const PLAY_MATERIAL: PhysicsMaterial = preload("res://resources/ball/play.tres")
const REST_MATERIAL: PhysicsMaterial = preload("res://resources/ball/rest.tres")

# Per-state configs; ordering-sensitive steps stay imperative around apply().
# STORED and OUT_HELD share the same physics setup (frozen, no-collide); one .tres covers both.
# PLAY_NORMAL and PLAY_ARC share PLAY_ACTIVE_CONFIG; only gravity_scale differs, set imperatively after apply.
const STORED_CONFIG: BallStateConfig = preload("res://resources/ball/states/stored.tres")
const PLAY_ACTIVE_CONFIG: BallStateConfig = preload("res://resources/ball/states/play_active.tres")
const OUT_REST_CONFIG: BallStateConfig = preload("res://resources/ball/states/out_rest.tres")

## Item key this ball represents; the system reads this on adoption to find the matching ItemDefinition.
@export var item_key: String = ""
## Authored Area2D that routes pointer presses to the grab hit-box; wired from the scene so the grab hit-box stays scene-based.
@export var grab_area: GrabArea
## Per-court tunables; injected by Court at attach time. Falls back to a default at construction.
@export var court_config: CourtConfig

var speed := 0.0
var min_speed: float
var max_speed: float
var speed_increment: float
var effect_processor: BallEffectProcessor
var is_temporary := false

var play_state: PlayState = PlayState.PLAY_NORMAL

# Persistent register: first NORMAL->ARC cross sets it; in-ARC speed events update it; relock targets it.
var entry_speed: float:
	get:
		return _relock.entry_speed

var _item_manager: Node
var _emit_tracker: BallSpeedEmitTracker = BallSpeedEmitTracker.new()
var _relock: BallRelockState = BallRelockState.new()
# HELD suppresses miss-zone routing; cleared on any non-HELD enter_X.
var _suppress_miss_detection: bool = false


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

	if _emit_tracker.should_emit_speed(speed, min_speed, max_speed):
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

	if play_state != PlayState.PLAY_ARC and _relock.is_ramping():
		_advance_relock_ramp(delta)


func _enter_arc() -> void:
	_relock.enter_arc(speed)
	# Hot path: only NORMAL/ARC delta. Direct write here goes stale if a second property starts differing between NORMAL and ARC.
	gravity_scale = 1.0
	set_play_state(PlayState.PLAY_ARC)


func _enter_normal() -> void:
	# See _enter_arc above for the staleness warning.
	gravity_scale = 0.0
	var should_snap: bool = _relock.enter_normal(
		linear_velocity.length(), court_config.relock_ramp_seconds
	)

	if should_snap:
		speed = _relock.entry_speed
		linear_velocity = linear_velocity.normalized() * speed

	set_play_state(PlayState.PLAY_NORMAL)


func _advance_relock_ramp(delta: float) -> void:
	var ramped_speed: float = _relock.advance_ramp(delta, court_config.relock_ramp_seconds)
	speed = ramped_speed
	linear_velocity = linear_velocity.normalized() * ramped_speed


func _emit_speed_changed() -> void:
	_emit_tracker.record_speed(speed, min_speed, max_speed)
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
	if _suppress_miss_detection:
		return
	if body == self:
		missed.emit()


func _on_missed() -> void:
	enter_out_rest()


# Single funnel for play_state writes. Idempotent: a same-state call is a no-op.
func set_play_state(new_state: PlayState) -> void:
	if play_state == new_state:
		return

	play_state = new_state
	_apply_grab_area_pickable()
	play_state_changed.emit(new_state)


# Grab area swallows clicks even while frozen; disable it when the ball isn't grabbable so the rack slot below stays reachable.
func _apply_grab_area_pickable() -> void:
	if grab_area == null:
		return

	grab_area.input_pickable = (
		play_state == PlayState.PLAY_NORMAL
		or play_state == PlayState.PLAY_ARC
		or play_state == PlayState.OUT_REST
	)


# STORED: body frozen, collision off. Position handled by the caller (rack slot).
func enter_stored() -> void:
	_suppress_miss_detection = false
	STORED_CONFIG.apply(self)
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	set_play_state(PlayState.STORED)


# PLAY: selects NORMAL or ARC by current Y vs the friendship bound. NORMAL/ARC share the active
# config and differ only by gravity_scale, which is set after apply().
func enter_play() -> void:
	_suppress_miss_detection = false
	PLAY_ACTIVE_CONFIG.apply(self)
	var bound_y: float = court_config.friendship_bound_y if court_config != null else 0.0
	var above_bound: bool = global_position.y < bound_y

	if above_bound:
		gravity_scale = 1.0
		set_play_state(PlayState.PLAY_ARC)
	else:
		gravity_scale = 0.0
		set_play_state(PlayState.PLAY_NORMAL)


# OUT_REST: gravity on, REST material, damping engaged. Body keeps its current velocity.
func enter_out_rest() -> void:
	_suppress_miss_detection = false
	OUT_REST_CONFIG.apply(self)
	# Damping is a court-tunable, not a ball-state-tunable; override the .tres default with the court value.
	linear_damp = court_config.rest_roll_damping
	speed = min_speed
	effect_processor.sync_base_speed()
	_emit_max_speed_if_changed()
	_emit_speed_changed()
	set_play_state(PlayState.OUT_REST)


# OUT_HELD: body frozen, collision and miss-detection suppressed. Drag controller drives position.
func enter_out_held() -> void:
	_suppress_miss_detection = true
	STORED_CONFIG.apply(self)
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	set_play_state(PlayState.OUT_HELD)


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
		_relock.track_speed_change(speed)


func _apply_speed() -> void:
	effect_processor.sync_base_speed()
	linear_velocity = linear_velocity.normalized() * speed
	_emit_max_speed_if_changed()
	_emit_speed_changed()


func _emit_max_speed_if_changed() -> void:
	var is_at_max: bool = speed >= max_speed
	if _emit_tracker.consume_max_change(is_at_max):
		at_max_speed_changed.emit(is_at_max)


func _setup_effect_processor() -> void:
	effect_processor = BallEffectProcessor.new()
	effect_processor.name = "BallEffectProcessor"
	effect_processor.ball = self
	effect_processor.item_manager = _item_manager
	add_child(effect_processor)


func _wire_grab_area() -> void:
	if grab_area == null:
		return
	grab_area.inflate_to(_baseline_collision_radius())
	if not grab_area.grabbed.is_connected(_on_grab_area_grabbed):
		grab_area.grabbed.connect(_on_grab_area_grabbed)


# Reads the visible sprite so the grab area tracks what the player sees, not the physics shape.
func _baseline_collision_radius() -> float:
	var sprite: Sprite2D = get_node_or_null("Sprite") as Sprite2D
	if sprite == null or sprite.texture == null:
		return 0.0
	var texture_size: Vector2 = sprite.texture.get_size()
	var max_axis: float = maxf(texture_size.x, texture_size.y)
	var max_scale: float = maxf(absf(sprite.scale.x), absf(sprite.scale.y))
	return (max_axis * 0.5) * maxf(max_scale, 0.001)


func _ball_setup() -> void:
	speed = min_speed
	effect_processor.sync_base_speed()
	lock_rotation = true

	# Reset relock register so a pooled ball doesn't read its previous run's tracked value.
	_relock.reset()
	enter_play()
	linear_velocity = Vector2(min_speed, min_speed * 0.5).normalized() * speed

	contact_monitor = true
	max_contacts_reported = 1

	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not missed.is_connected(_on_missed):
		missed.connect(_on_missed)

	input_pickable = false
	_wire_grab_area()


func _on_grab_area_grabbed(_area: GrabArea) -> void:
	if freeze:
		return
	grabbed.emit(self)


func has_item_art() -> bool:
	var holder: Node = get_node_or_null("ItemArtHolder")
	return holder != null and is_instance_valid(holder)
