class_name Upgrade
extends Resource

@export var display_name: String
@export var description: String
@export var effect_key: String  # "paddle_speed", "paddle_size", "ball_speed_min"
@export var effect_per_level: float
@export var max_level: int = 5
@export var base_value: float
@export var base_cost: int
@export var cost_scaling: float = 1.6  # cost = base_cost * scaling^current_level
