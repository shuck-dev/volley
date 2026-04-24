class_name TimeoutConfig
extends Resource

## Tunables for TimeoutController: how long the walk takes and where the equip pose sits.

## Seconds to walk from the lane to the equip pose (and back).
@export var walk_duration_seconds: float = 0.6
## Horizontal offset from lane x to equip pose, away from the court on the player's side.
@export var equip_pose_offset_x: float = -320.0
## World y of the venue floor where the main character lands before walking off.
@export var floor_y: float = 600.0
