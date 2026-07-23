class_name ItemArt
extends Node2D

## Local-space rect of the visible art. Consumers size to `size` and shift by `-position`.
@export var bounding_rect: Rect2 = Rect2(-20, -20, 40, 40)


## Called once by the owning ball after this art is attached. Override for art that
## reacts to the ball's own state (e.g. a particle cue on a stat shift).
func watch_ball(_ball: Ball) -> void:
	pass
