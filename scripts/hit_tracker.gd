class_name HitTracker
extends RefCounted

const COOLDOWN := 0.2

var streak := 0
var _cooldown := 0.0


func process(delta: float) -> void:
	if _cooldown > 0.0:
		_cooldown -= delta


func try_hit() -> bool:
	if _cooldown > 0.0:
		return false
	_cooldown = COOLDOWN
	streak += 1
	return true


func reset() -> void:
	streak = 0
	_cooldown = 0.0
