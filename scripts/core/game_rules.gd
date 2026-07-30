class_name GameRules
extends RefCounted

const BASE_CONFIG: BaseBallStats = preload("res://resources/base_ball_stats.tres")
const PADDLE_CONFIG: PaddleConfig = preload("res://resources/paddle_stats.tres")
const SPEED_TIER_TABLE: SpeedTierTable = preload("res://resources/speed_tier_table.tres")

## Full paddle-to-paddle court span in pixels, for the soul-bound line width.
const COURT_WIDTH: float = 1500.0
## Top speed any ball may reach: COURT_WIDTH divided by the fair-crossing time (2.083333s).
const BALL_WORLD_MAX_SPEED: float = 720.0

## Typed base-stats config. Read fields directly; combine modifiers via `Stats.resolve`.
static var base: BaseBallStats = BASE_CONFIG
## Typed paddle-stats config. Read fields directly; combine modifiers via `Stats.resolve`.
static var paddle: PaddleConfig = PADDLE_CONFIG
## Ball-speed ladder. Tier bounds are fractions of the court-derived world max; read via `get_tier`.
static var speed_tiers: SpeedTierTable = SPEED_TIER_TABLE
