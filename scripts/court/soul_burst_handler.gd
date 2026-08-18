class_name SoulBurstHandler
extends Node

## Spawns and delivers the consolidation payout as denomination motes that travel to the player.

const MOTE_SCENE: PackedScene = preload("res://scenes/effects/soul_mote.tscn")

## Delay between each mote's spawn, so the burst streams out rather than popping all at once.
const SPAWN_INTERVAL := 0.02


## Spawns one mote per denomination, fanned out in a star pattern, streamed over time.
func release_burst(ball: Ball, payout: int) -> void:
	if ball == null:
		return

	var values: Array[int] = SoulBurstMath.split(payout)
	if values.is_empty():
		return

	var angle_step := TAU / values.size()

	for i in values.size():
		if not is_inside_tree() or not is_instance_valid(ball):
			return

		var mote: SoulMote = MOTE_SCENE.instantiate()
		mote.soul_value = values[i]
		mote.initial_heading = Vector2.RIGHT.rotated(angle_step * i)
		add_child(mote)
		mote.global_position = ball.global_position

		await get_tree().create_timer(SPAWN_INTERVAL).timeout
