class_name UpgradeDefinition
extends Resource

@export var id: String
@export var display_name: String
@export var description: String
@export var effect_key: String  # "paddle_speed", "paddle_size", "ball_speed_min"
@export var effect_per_level: float
@export var max_level: int = 5
@export var base_cost: int = 25
@export var cost_scaling: float = 1.6  # cost = base_cost * scaling^current_level
