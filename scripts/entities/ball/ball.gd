class_name Ball
extends RigidBody2D

signal missed(ball: Ball)
## Fires only on final-consolidation entry (true) and exit (false), not on every tier ceiling touch.
signal at_max_speed_changed(is_at_max: bool)
## Carries the current tier's floor and ceiling so a listener can render the active band.
signal speed_changed(speed: float, tier_floor: float, tier_ceiling: float)
## Fires when the rally crosses a tier ceiling and steps up to the next tier.
signal tier_advanced(ball: Ball, new_tier: int)
signal grabbed(ball: Ball)
signal play_state_changed(state: PlayState)

enum PlayState {
	STORED,
	PLAY_NORMAL,
	PLAY_ARC,
	OUT_REST,
	OUT_HELD,
}

const STORED_CONFIG: BallStateConfig = preload("res://resources/ball/states/stored.tres")
const PLAY_ACTIVE_CONFIG: BallStateConfig = preload("res://resources/ball/states/play_active.tres")
const OUT_REST_CONFIG: BallStateConfig = preload("res://resources/ball/states/out_rest.tres")

## Item key this ball represents; the system reads this on adoption to find the matching ItemDefinition.
@export var item_key: String = ""
## Authored Area2D that routes pointer presses to the grab hit-box; wired from the scene so the grab hit-box stays scene-based.
@export var grab_area: GrabArea
## Per-court tunables; injected by Court at attach time. Falls back to a default at construction.
@export var court_config: CourtConfig
## Apex-arc threshold y; BallTracker injects at attach time from the SoulBound marker.
var bound_y: float

var speed := 0.0
var min_speed: float
var max_speed: float
var speed_increment: float
var effect_processor: BallEffectProcessor
var is_temporary := false

## Hard speed ceiling no item, effect, or final-consolidation climb may exceed; derived from the court at ready.
var ball_world_max_speed: float
## Current rung of the speed ladder; 0 at rally start, stepped up on each tier completion.
var current_tier := 0
## True while the top tier's final-consolidation window is open; the ball climbs above max_speed up to the world max.
var in_final := false
## Accumulated soul multiplier for this ball; incremented by each consolidation event, reset on miss.
var soul_multiplier: float = 1.0

## Entry speed of the current tier, derived from the table fraction of the world max plus any tier-floor lift on tiers above Tier 0.
var tier_floor: float:
	get:
		var base_floor: float = _tier_fraction("floor_fraction") * ball_world_max_speed
		if current_tier == 0:
			return base_floor

		var lift: float = _item_manager.get_modifier(&"tier_floor_lift") * ball_world_max_speed

		return minf(base_floor + lift, tier_ceiling)

## Speed that completes the current tier; the world max while the final-consolidation window is open.
var tier_ceiling: float:
	get:
		if in_final:
			return ball_world_max_speed
		return _tier_fraction("ceiling_fraction") * ball_world_max_speed

var play_state: PlayState = PlayState.PLAY_NORMAL

var _item_manager: Node
var _emit_tracker: BallSpeedEmitTracker = BallSpeedEmitTracker.new()
# Zero below the bound; set at the up-cross from the entry speed and the court's arc rule.
var _arc_acceleration: float = 0.0
# HELD suppresses miss-zone routing; cleared on any non-HELD enter_X.
var _suppress_miss_detection: bool = false


func _ready() -> void:
	if _item_manager == null:
		_item_manager = ItemManager
	if court_config == null:
		court_config = load("res://scripts/core/court_config.gd").new()

	ball_world_max_speed = court_config.world_max_speed()
	min_speed = Stats.resolve(GameRules.base.ball_speed_min, &"ball_speed_min", _item_manager)
	max_speed = (
		min_speed
		+ Stats.resolve(GameRules.base.ball_speed_max_range, &"ball_speed_max_range", _item_manager)
	)
	speed_increment = Stats.resolve(
		GameRules.base.ball_speed_increment, &"ball_speed_increment", _item_manager
	)

	_setup_effect_processor()
	_ball_setup()


func _physics_process(delta: float) -> void:
	if linear_velocity == Vector2.ZERO:
		return

	effect_processor.process_frame(delta)
	_update_play_state()
	_emit_max_speed_if_changed()

	if _emit_tracker.should_emit_speed(speed, tier_floor, tier_ceiling):
		_emit_speed_changed()

	if play_state == PlayState.PLAY_ARC:
		linear_velocity.y += _arc_acceleration * delta

	# Renormalise in ARC as well as NORMAL: the bend turns direction, the magnitude stays at speed.
	if play_state == PlayState.PLAY_NORMAL or play_state == PlayState.PLAY_ARC:
		linear_velocity = linear_velocity.normalized() * speed


# NORMAL <-> ARC crossing, read off the body's current Y vs the soul bound.
func _update_play_state() -> void:
	if play_state != PlayState.PLAY_NORMAL and play_state != PlayState.PLAY_ARC:
		return

	var above_bound: bool = global_position.y < bound_y

	if above_bound and play_state == PlayState.PLAY_NORMAL:
		_enter_arc()
	elif not above_bound and play_state == PlayState.PLAY_ARC:
		_enter_normal()


func _enter_arc() -> void:
	# No engine gravity above the bound; the court's arc rule supplies the downward bend instead.
	gravity_scale = 0.0
	_arc_acceleration = court_config.physics.arc_acceleration(-linear_velocity.y)
	set_play_state(PlayState.PLAY_ARC)


func _enter_normal() -> void:
	_arc_acceleration = 0.0
	set_play_state(PlayState.PLAY_NORMAL)


func _emit_speed_changed() -> void:
	_emit_tracker.record_speed(speed, tier_floor, tier_ceiling)
	speed_changed.emit(speed, tier_floor, tier_ceiling)


func _on_body_entered(body: Node) -> void:
	if freeze:
		return

	if body.has_method("on_ball_hit"):
		var hit_registered: bool = body.on_ball_hit(self)
		if hit_registered:
			increase_speed()
		effect_processor.process_hit(body as Paddle)


func register_miss_zone(zone: MissZone) -> void:
	if not zone.body_entered.is_connected(_on_miss_zone_body_entered):
		zone.body_entered.connect(_on_miss_zone_body_entered)


func _on_miss_zone_body_entered(body: Node) -> void:
	if _suppress_miss_detection:
		return
	if body == self:
		missed.emit(self)


func _on_missed(_ball: Ball) -> void:
	reset_soul_multiplier()
	enter_out_rest()


## Resets this ball's soul multiplier to the base value.
func reset_soul_multiplier() -> void:
	soul_multiplier = 1.0


## Adds amount to this ball's soul multiplier.
func increment_soul_multiplier(amount: float) -> void:
	soul_multiplier += amount


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


# Both PLAY states run gravity-free; ARC adds the bend (see _enter_arc), NORMAL flies straight.
func enter_play() -> void:
	_suppress_miss_detection = false
	PLAY_ACTIVE_CONFIG.apply(self)
	var above_bound: bool = global_position.y < bound_y

	if above_bound:
		_enter_arc()
	else:
		gravity_scale = 0.0
		_arc_acceleration = 0.0
		set_play_state(PlayState.PLAY_NORMAL)


# OUT_REST: gravity on, REST material, damping engaged. Body keeps its current velocity.
func enter_out_rest() -> void:
	_suppress_miss_detection = false
	OUT_REST_CONFIG.apply(self)

	current_tier = 0
	in_final = false
	speed = tier_floor
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
	if in_final:
		if speed >= ball_world_max_speed:
			return

		speed = minf(speed + speed_increment, ball_world_max_speed)
		_apply_speed()
		return

	if speed + speed_increment >= tier_ceiling:
		advance_tier()
		return

	speed = speed + speed_increment
	_apply_speed()


# Crossing a tier ceiling steps up a rung, or opens the final-consolidation window when the top tier completes.
func advance_tier() -> void:
	var is_top_tier: bool = current_tier >= GameRules.speed_tiers.tier_count() - 1

	if is_top_tier:
		in_final = true
		speed = max_speed
	else:
		current_tier += 1
		speed = tier_floor

	_apply_speed()

	tier_advanced.emit(self, current_tier)
	_item_manager.process_event(&"on_tier_completed")


func _tier_fraction(field: String) -> float:
	var tier: SpeedTier = GameRules.speed_tiers.get_tier(current_tier)
	if tier == null:
		return 0.0

	return tier.get(field)


func _apply_speed() -> void:
	effect_processor.sync_base_speed()
	linear_velocity = linear_velocity.normalized() * speed
	_emit_max_speed_if_changed()
	_emit_speed_changed()


func _emit_max_speed_if_changed() -> void:
	if _emit_tracker.consume_max_change(in_final):
		at_max_speed_changed.emit(in_final)


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
	current_tier = 0
	in_final = false
	speed = tier_floor
	effect_processor.sync_base_speed()
	lock_rotation = true

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
