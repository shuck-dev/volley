class_name Ball
extends RigidBody2D

signal missed(ball: Ball)
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

## Item key this ball represents; the system reads this on adoption to find the matching BallDefinition.
@export var ball_key: String = ""

## Authored Area2D that routes pointer presses to the grab hit-box; wired from the scene so the grab hit-box stays scene-based.
@export var grab_area: GrabArea

## Apex ceiling in pixels above the soul bound; BallTracker injects at attach time from Court.
var arc_height_max: float

## Apex-arc threshold y; BallTracker injects at attach time from the SoulBound marker.
var bound_y: float

var speed := 0.0
var min_speed: float
var max_speed: float
var speed_increment: float

## Speed after the tier clamp and any uncapped scale.
var scaled_speed := 0.0

## A temporary ball is untracked by BallManager and the save file.
var is_temporary := false

## Hard speed ceiling no item, effect, or final-consolidation climb may exceed; derived from the court at ready.
var ball_world_max_speed: float

## Current rung of the speed ladder; 0 at rally start, stepped up on each tier completion.
var current_tier := 0

## Accumulated soul multiplier for this ball; incremented by each consolidation event, reset on miss.
var soul_multiplier: float = 1.0

## Soul counter for this ball, released on consolidation, reset on miss.
var accumulated_soul: float = 0.0

## Entry speed of the current tier, derived from the table fraction of the world max.
var tier_floor: float:
	get:
		var base_floor: float = _tier_fraction("floor_fraction") * ball_world_max_speed
		if current_tier == 0:
			return base_floor

		return minf(base_floor, tier_ceiling)

## Speed that completes the current tier.
var tier_ceiling: float:
	get:
		return _tier_fraction("ceiling_fraction") * ball_world_max_speed

var play_state: PlayState = PlayState.PLAY_NORMAL

## Stats snapshot from the BallDefinition the tracker spawned this ball from; unset for a keyless ball.
var stats: BaseBallStats

## Speed-tier ladder defining the ball's speed progression
var speed_tiers: SpeedTierTable

# Throttle state for speed_changed emission; inlined from the deleted BallSpeedEmitTracker.
var _last_speed := 0.0
var _last_min := 0.0
var _last_max := 0.0

# Zero below the bound; set at the up-cross from the entry speed and the court's arc rule.
var _arc_acceleration: float = 0.0

# HELD suppresses miss-zone routing; cleared on any non-HELD enter_X.
var _suppress_miss_detection: bool = false


func _ready() -> void:
	var resolved_stats: BaseBallStats = get_stats()
	min_speed = resolved_stats.ball_speed_min
	max_speed = resolved_stats.ball_speed_max
	speed_increment = resolved_stats.ball_speed_increment
	ball_world_max_speed = minf(max_speed, GameRules.BALL_WORLD_MAX_SPEED)
	speed = clampf(speed, tier_floor, tier_ceiling)
	refresh_scaled_speed()

	_configure_physics_body()
	_connect_ball_signals()
	_wire_grab_area()
	# A caller that stored the ball before it entered the tree keeps that state; only a
	# ball that is still at its default serves itself on ready.
	if play_state != PlayState.STORED:
		_serve()


func _physics_process(delta: float) -> void:
	if linear_velocity == Vector2.ZERO:
		return

	_update_play_state()

	if (
		absf(speed - _last_speed) >= 10.0
		or not is_equal_approx(tier_floor, _last_min)
		or not is_equal_approx(tier_ceiling, _last_max)
	):
		_emit_speed_changed()

	if play_state == PlayState.PLAY_ARC:
		linear_velocity.y += _arc_acceleration * delta

	# Renormalise in ARC as well as NORMAL: the bend turns direction, the magnitude stays at speed.
	if play_state == PlayState.PLAY_NORMAL or play_state == PlayState.PLAY_ARC:
		linear_velocity = linear_velocity.normalized() * scaled_speed


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
	_arc_acceleration = ArcMath.arc_acceleration(-linear_velocity.y, arc_height_max)
	set_play_state(PlayState.PLAY_ARC)


func _enter_normal() -> void:
	_arc_acceleration = 0.0
	set_play_state(PlayState.PLAY_NORMAL)


func _emit_speed_changed() -> void:
	_last_speed = speed
	_last_min = tier_floor
	_last_max = tier_ceiling
	speed_changed.emit(speed, tier_floor, tier_ceiling)


## Bumps speed and accumulates soul.
func hit() -> void:
	increase_speed()
	accumulated_soul += soul_multiplier


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
	reset_accumulated_soul()
	enter_out_rest()


## Resets this ball's soul multiplier to the base value.
func reset_soul_multiplier() -> void:
	soul_multiplier = 1.0


## Adds amount to this ball's soul multiplier.
func increment_soul_multiplier(amount: float) -> void:
	soul_multiplier += amount


## Resets accumulated soul count to zero.
func reset_accumulated_soul() -> void:
	accumulated_soul = 0.0


# Single funnel for play_state writes. Idempotent: a same-state call is a no-op.
func set_play_state(new_state: PlayState) -> void:
	if play_state == new_state:
		return

	play_state = new_state
	_apply_grab_area_pickable()
	play_state_changed.emit(new_state)


# Grab area swallows clicks even while frozen; disable it when the ball isn't grabbable so the slot below stays reachable.
func _apply_grab_area_pickable() -> void:
	if grab_area == null:
		return

	grab_area.input_pickable = (
		play_state == PlayState.PLAY_NORMAL
		or play_state == PlayState.PLAY_ARC
		or play_state == PlayState.OUT_REST
	)


# STORED: body frozen, collision off. Position handled by the caller.
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
	speed = tier_floor
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
	if speed + speed_increment >= tier_ceiling:
		advance_tier()
		return

	speed = speed + speed_increment
	_apply_speed()


# Crossing a tier ceiling advances to the next tier, or repeats the top tier's range.
func advance_tier() -> void:
	var is_top_tier: bool = current_tier >= get_speed_tiers().tier_count() - 1

	if not is_top_tier:
		current_tier += 1

	speed = tier_floor
	_apply_speed()

	tier_advanced.emit(self, current_tier)


func _tier_fraction(field: String) -> float:
	var tier: SpeedTier = get_speed_tiers().get_tier(current_tier)
	if tier == null:
		return 0.0

	return tier.get(field)


func _apply_speed() -> void:
	refresh_scaled_speed()
	linear_velocity = linear_velocity.normalized() * scaled_speed
	# A mid-arc speed change reshapes the rest of the bend so the apex still honours the new speed.
	if play_state == PlayState.PLAY_ARC:
		_arc_acceleration = ArcMath.arc_acceleration(-linear_velocity.y, arc_height_max)
	_emit_speed_changed()


func refresh_scaled_speed() -> void:
	scaled_speed = speed


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


func _configure_physics_body() -> void:
	lock_rotation = true
	contact_monitor = true
	max_contacts_reported = 1
	input_pickable = false


func _connect_ball_signals() -> void:
	if not missed.is_connected(_on_missed):
		missed.connect(_on_missed)


func _serve() -> void:
	current_tier = 0
	speed = tier_floor
	enter_play()
	linear_velocity = Vector2(min_speed, min_speed * 0.5).normalized() * speed


func _on_grab_area_grabbed(_area: GrabArea) -> void:
	if freeze:
		return
	grabbed.emit(self)


# Get stats or base stats if not defined.
func get_stats() -> BaseBallStats:
	return stats if stats != null else GameRules.base


# Get speed tiers or base tiers if not defined.
func get_speed_tiers() -> SpeedTierTable:
	return speed_tiers if speed_tiers != null else GameRules.speed_tiers
