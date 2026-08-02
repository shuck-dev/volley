class_name GoopBall
extends Ball

signal split(ball: GoopBall)


func _ready() -> void:
	super._ready()


func _on_tier_advanced(_ball: Ball, _tier: int) -> void:
	split.emit(self)
