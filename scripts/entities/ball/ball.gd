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
## Apex ceiling in pixels above the soul bound; injected by Court at attach time.
@export var arc_height_max: float = 220.0
## Apex-arc threshold y; BallReconciler injects at attach time from the SoulBound marker.
var bound_y: float

var speed := 0.0
var min_speed: float
var max_speed: float
var speed_increment: float
## Speed after the tier clamp and any uncapped scale.
var scaled_speed := 0.0
var is_temporary := false

## Hard speed ceiling no item, effect, or final-consolidation climb may exceed; derived from the court at ready.
var ball_world_max_speed: float
## Current rung of the speed ladder; 0 at rally start, stepped up on each tier completion.
var current_tier := 0
## Accumulated soul multiplier for this ball; incremented by each consolidation event, reset on miss.
var soul_multiplier: float = 1.0

## Entry speed of the current tier, derived from the table fraction of the world max plus any tier-floor lift on tiers above Tier 0.
var tier_floor: float:
	get:
		var base_floor: float = _tier_fraction("floor_fraction") * ball_world_max_speed
		if current_tier == 0:
			return base_floor

		var lift: float = (
			_ball_manager.get_modifier(&"tier_floor_lift", ball_key) * ball_world_max_speed
		)

		return minf(base_floor + lift, tier_ceiling)

## Speed that completes the current tier.
var tier_ceiling: float:
	get:
		return _tier_fraction("ceiling_fraction") * ball_world_max_speed

var play_state: PlayState = PlayState.PLAY_NORMAL

var _ball_manager: BallManager
# Throttle state for speed_changed emission; inlined from the deleted BallSpeedEmitTracker.
var _last_speed := 0.0
var _last_min := 0.0
var _last_max := 0.0
# Zero below the bound; set at the up-cross from the entry speed and the court's arc rule.
var _arc_acceleration: float = 0.0
# HELD suppresses miss-zone routing; cleared on any non-HELD enter_X.
var _suppress_miss_detection: bool = false


## Injects the item manager seam before _ready runs; falls back to the autoload if never called.
func configure(ball_manager: BallManager) -> void:
	_ball_manager = ball_manager


func _ready() -> void:
	if _ball_manager == null:
		_ball_manager = BallManager

	ball_world_max_speed = GameRules.BALL_WORLD_MAX_SPEED
	var stats: BaseBallStats = get_stats()
	min_speed = Stats.resolve(stats.ball_speed_min, &"ball_speed_min", _ball_manager, ball_key)
	max_speed = Stats.resolve(stats.ball_speed_max, &"ball_speed_max", _ball_manager, ball_key)
	speed_increment = Stats.resolve(
		stats.ball_speed_increment, &"ball_speed_increment", _ball_manager, ball_key
	)
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


func _on_body_entered(body: Node) -> void:
	if freeze:
		return

	if body is Paddle:
		hit_by_paddle(body as Paddle)


# Entry point for a paddle hit. Called by the paddle's racket hitbox Area2D on detection,
# now that the ball passes through the character body instead of physically colliding with it.
func hit_by_paddle(paddle: Paddle) -> void:
	if freeze:
		return

	var hit_registered: bool = paddle.on_ball_hit(self)
	if hit_registered:
		increase_speed()
	_process_hit(paddle)
	_ball_manager.process_event(&"on_hit", ball_key)


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


# Crossing a tier ceiling steps up a rung; the top tier has no rung above it, so speed plateaus there.
func advance_tier() -> void:
	var is_top_tier: bool = current_tier >= GameRules.speed_tiers.tier_count() - 1

	if is_top_tier:
		speed = tier_ceiling
	else:
		current_tier += 1
		speed = tier_floor

	_apply_speed()

	tier_advanced.emit(self, current_tier)
	_ball_manager.process_event(&"on_tier_completed", ball_key)


func _tier_fraction(field: String) -> float:
	var tier: SpeedTier = GameRules.speed_tiers.get_tier(current_tier)
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
	var speed_scale: float = (
		1.0 + _ball_manager.get_percentage_offset(&"ball_speed_scale", ball_key)
	)
	scaled_speed = speed * speed_scale


func _process_hit(struck_paddle: Paddle) -> void:
	refresh_scaled_speed()
	_apply_paddle_offset_return(struck_paddle)


# Where on the paddle the ball struck drives the return angle.
func _apply_paddle_offset_return(struck_paddle: Paddle) -> void:
	if struck_paddle == null:
		return

	var direction: Variant = (
		PaddleBounceMath
		. bounce_direction(
			linear_velocity,
			global_position,
			struck_paddle.global_position,
			struck_paddle.get_half_height(),
			(
				Stats
				. resolve(
					GameRules.paddle.paddle_return_angle_max_degrees,
					&"paddle_return_angle_max_degrees",
					_ball_manager,
				)
			),
		)
	)

	if direction == null:
		return

	linear_velocity = (direction as Vector2) * scaled_speed


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
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
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


## Ball-scoped stats when a definition is known (ball_key set); the shared default otherwise
## (unadopted balls, test stubs).
func get_stats() -> BaseBallStats:
	if ball_key == "":
		return GameRules.base
	return _ball_manager.get_item(ball_key).stats
