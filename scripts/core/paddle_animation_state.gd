class_name PaddleAnimationState
extends RefCounted

## Pure resolver for paddle animation state from motion and swing status.


## Resolves the animation state from grounded, vertical motion, and swing pending.
## Swing wins; else grounded plays ready_grounded; else motion > 0 plays flying_down/flying_up; else ready_flying.
static func resolve_state(
	grounded: bool, vertical_motion: float, swing_pending: bool
) -> StringName:
	if swing_pending:
		return &"swing_grounded" if grounded else &"swing_flying"

	if grounded:
		return &"ready_grounded"

	if not is_zero_approx(vertical_motion):
		return &"flying_up" if vertical_motion < 0.0 else &"flying_down"

	return &"ready_flying"
