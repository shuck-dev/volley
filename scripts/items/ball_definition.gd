class_name BallDefinition
extends Resource

@export var key: String
@export var display_name: String
@export var scene: PackedScene
@export var base_cost: int
@export var cost_scaling := 1.6
@export var max_level := 3
@export var stats: BaseBallStats = load("res://resources/base_ball_stats.tres")
@export var speed_tiers: SpeedTierTable = load("res://resources/speed_tier_table.tres")
