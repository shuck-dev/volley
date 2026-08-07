class_name BallDefinition
extends Resource

@export var key: String
@export var display_name: String
## The ball's own inherited scene (ball.tscn root script or subclass); BallReconciler spawns it
## live, and previews instantiate it frozen via Ball.enter_stored().
@export var scene: PackedScene
@export var base_cost: int
@export var cost_scaling := 1.6
@export var max_level := 3
## Static art for Control-based UI (e.g. KitSlot) that cannot host a live scene instance.
@export var icon: Texture2D
## Falls back to the shared global default; give a ball its own resource instance to diverge.
@export var stats: BaseBallStats = load("res://resources/base_ball_stats.tres")
