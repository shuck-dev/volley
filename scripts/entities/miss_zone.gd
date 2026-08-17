class_name MissZone
extends Area2D

## Area that fires body_entered on overlap; the ball hooks in via register_miss_zone().


func _ready() -> void:
	BallTracker.register_miss_zone(self)


func _exit_tree() -> void:
	BallTracker.unregister_miss_zone(self)
