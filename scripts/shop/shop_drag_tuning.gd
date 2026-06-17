class_name ShopDragTuning
extends Resource

## Knobs for the shop press-drag-release feel: distinguishes click from drag, governs how a falling body decides it has come to rest.

## Cursor travel below this distance treats the gesture as a pure click; at or above, the inside-shop drag spawns a falling body.
@export var drag_threshold_px: float = 2.0

## Linear-velocity ceiling that counts as a "slow frame" toward settling.
@export var settle_velocity_threshold: float = 4.0

## Consecutive slow frames required before notify_body_settled fires.
@export var settle_frames_required: int = 12

## Hard time cap; a runaway body resolves on this even if velocity never falls below the threshold.
@export var max_lifetime_s: float = 4.0
