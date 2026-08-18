class_name SoulBurstHandler
extends Node

## Spawns and delivers the consolidation payout as denomination motes that travel to the player.

const MOTE_SCENE: PackedScene = preload("res://scenes/effects/soul_mote.tscn")


## Spawns one mote per denomination, fanned out in a star pattern.
func release_burst(ball: Ball, payout: int) -> void:
	if ball == null:
		return

	var values: Array[int] = SoulBurstMath.split(payout)
	if values.is_empty():
		return

	var angle_step: float = TAU / values.size()

	for i in values.size():
		var mote: SoulMote = MOTE_SCENE.instantiate()
		mote.soul_value = values[i]
		mote.initial_heading = Vector2.RIGHT.rotated(angle_step * i)
		add_child(mote)
		mote.global_position = ball.global_position
