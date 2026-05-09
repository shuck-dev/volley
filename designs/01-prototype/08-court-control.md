# Wall-less Court Control

Today the rally tops out with a pong-bounce off a screen-edge ceiling, and balls straying sideways bounce off invisible walls and stay in play. This spec replaces both.

At the top, the ball rises past the friendship-bound, arcs back down under gravity, and the rally continues; the player feels the ball being held in by the friendship rather than rebounding off a ceiling. At the sides, the ball rolls out onto the venue floor and lies among the items the player has placed, to be walked back to the rack.

The top collider goes; gravity engages while the ball is above a per-venue friendship-bound height, so the ball arcs back into play. The side walls go; a ball crossing either lateral edge fires a side-miss before its body unfreezes and rolls. Paddle line and ground unchanged. Drives SH-309.

## Apex return

The friendship-bound is a per-venue height authored on `Court` as `@export var friendship_bound_height: float`. Today's `Top Wall` StaticBody2D under `Bounds` is removed.

The active-ball state already runs at `gravity_scale = 0` for frictionless rally physics. The Court watches the ball's `y` position. While the ball is above the bound, the Court sets the ball's `gravity_scale` to its normal value; the ball arcs naturally and falls back. Once it re-enters the bound, `gravity_scale` returns to `0` and rally physics resume.

The ball does not change state machine during the arc. It stays in active-movement; paddle hits and friendship-bound are valid throughout. The arc is a sub-state of in-play, not a state transition. The rally counter does not pause. A ball is only out of play when it is held (dragged-gravity), at rest on the venue floor (after a miss), or stashed in the rack.

The bound is one number per Court instance. No horizontal restoring force, no centre-pull, no directional shaping; gravity alone returns the ball, and the ball's own momentum carries it where it goes. A hard reflect at the bound would read as an invisible ceiling; a soft arc reads as something holding the ball in.

## Side miss

The court's `Right Wall` and (currently un-authored) left side both become side-miss zones. The existing `Right Wall` StaticBody2D is removed; an `Area2D` band replaces it, mirrored on the left.

A ball whose centre crosses either band fires the existing `ball_missed` path in `BallTracker`. The body's `gravity_scale` rises to its normal value (same flip the back-miss line already does today), velocity at the crossing is preserved, and the body rolls out onto `VenueFloor`. The ball comes to rest where friction stops it. The player drags it back to the `BallRack` to re-serve, per the existing flow in `08-court-bounds.md`.

The partner-side miss zone, currently parented under `Right Wall`, re-parents to the new right `Area2D` band. The `BallTracker` registration remains.

The back-miss line behind the player paddle and the bottom ground are unchanged.
