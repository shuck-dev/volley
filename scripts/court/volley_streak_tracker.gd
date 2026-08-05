class_name VolleyStreakTracker
extends RefCounted

## Owns the shared volley-count streak: increments on every hit, resets on a miss
## that leaves no ball in play.

signal volley_count_changed(count: int)

var count := 0


func record_hit() -> void:
	count += 1
	volley_count_changed.emit(count)


## has_ball_in_play: true when another ball is still live; the streak survives a
## miss until the last ball in play is gone.
func record_miss(has_ball_in_play: bool) -> void:
	if has_ball_in_play:
		return

	count = 0
	volley_count_changed.emit(count)
