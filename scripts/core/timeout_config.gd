class_name TimeoutConfig
extends Resource

## Tunables for TimeoutController: how long the walk takes and where the equip pose sits.

## Seconds to walk from the lane to the equip pose (and back).
@export var walk_duration_seconds: float = 0.6
## Horizontal offset from lane x to equip pose, away from the court on the player's side.
@export var equip_pose_offset_x: float = -192.0
## Downward velocity (px/s) applied during the descent phase until the body lands.
@export var descent_speed: float = 1200.0
