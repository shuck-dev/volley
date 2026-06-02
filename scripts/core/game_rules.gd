class_name GameRules
extends RefCounted

const BASE_CONFIG: BaseStatsConfig = preload("res://resources/base_stats.tres")
const PADDLE_CONFIG: PaddleConfig = preload("res://resources/paddle_stats.tres")
const SPEED_TIER_TABLE: SpeedTierTable = preload("res://resources/speed_tier_table.tres")

## Typed base-stats config. Read fields directly; combine modifiers via `Stats.resolve`.
static var base: BaseStatsConfig = BASE_CONFIG
## Typed paddle-stats config. Read fields directly; combine modifiers via `Stats.resolve`.
static var paddle: PaddleConfig = PADDLE_CONFIG
## Ball-speed ladder. Tier bounds are fractions of the court-derived world max; read via `get_tier`.
static var speed_tiers: SpeedTierTable = SPEED_TIER_TABLE
