class_name DropTarget
extends RefCounted

## Abstract drop target consulted by BallDragController each physics frame.
##
## SH-287 (designs/01-prototype/21-ball-dynamics.md, "Drop validation by body projection"):
## the drag controller polls every registered target on the held token's world position; the
## first target whose `can_accept` returns true takes the drop. `accept` performs the side
## effect (spawning a ball, returning to a slot, completing a purchase, etc.). Subclasses
## override both methods.


## Returns true when this target would accept `item_key` at `position` right now.
## Targets that are role-restricted (e.g. ball rack only takes ball-role items) gate here.
## Court projection runs `intersect_shape` here against the item's `at_rest_shape`.
func can_accept(_item_key: String, _position: Vector2, _scale_factor: float = 1.0) -> bool:
	return false


## Side-effect: commit the drop. Caller has already gated on `can_accept`.
func accept(_item_key: String, _position: Vector2, _gesture_velocity: Vector2) -> void:
	pass
