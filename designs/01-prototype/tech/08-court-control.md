# Wall-less Court Control

Implementation spec for the wall-less court: friendship-bound replaces the top collider, lateral side bands replace the side wall colliders, the ground is unchanged. Drives SH-309. Player-facing design lives in [`../design/08-court-bounds.md`](../design/08-court-bounds.md).

## Per-ball state

Each live ball is in one of two states. The rule applies per ball, so multi-ball mixed-state is well-defined.

**At or below the friendship-bound (held state).** `gravity_scale = 0`, speed is locked, linear damping is off.

**Above the friendship-bound (released state).** `gravity_scale = 1`, speed-lock releases, linear damping engages. A centripetal force scaled by speed acts perpendicular to velocity, toward the play area. The centripetal force rotates velocity without doing work; magnitude follows gravity, direction bends.

The bound is a per-Court height.

## Apex return

A ball that arcs above the bound moves into the released state. Gravity decelerates the vertical component; the centripetal force redirects.

The ball tracks its pre-bound entry value: speed at the moment it arcs above the bound. Any speed change above the bound updates this value, so a paddle hit above the bound or a partner-active arc captures the post-event speed.

Returning below the bound returns the ball to the held state: `gravity_scale = 0`, speed-lock relocks, damping disengages, speed ramps back up to the tracked entry value. Rally energy is preserved across the apex visit.

The mechanism is engaged-gravity-with-centripetal-bend, not a vertical-velocity flip. A flip reads as an invisible ceiling; the engaged form reads as a held arc. The ball stays a live ball throughout; paddle hits register and the volley counter increments above the bound the same as below.

## Miss

A ball whose centre arcs past either lateral side band fires a miss: the held state releases, gravity engages, speed-lock releases, damping engages, the rally counter resets. The ball keeps its velocity at the moment it arcs past, falls under gravity, and rolls to rest on the venue floor. The player drags it back to the rack via the existing live-ball drag path. Past either side band there is no centripetal and no relock ramp.

Player-side and partner-side are the same event. The partner already has its own miss zone in code; the player-side gets the same treatment when its wall is removed.

A live ball pulled to the rack mid-rally is not a miss; the drag controller replaces the live ball with a held body before any side-band miss fires.

## Cross-bound collisions

Collisions between an above-bound ball and a below-bound ball resolve under each body's current physics state. The above-bound ball's velocity changes per real physics. The below-bound ball's velocity *direction* changes per the collision; its locked *speed* (magnitude) re-asserts immediately after, since the speed-lock only constrains magnitude. Velocity and speed are distinct: the lock is on speed; direction is free.

The bound is a state line, not a collision filter.

## Keeping the speed steady above the bound

The centripetal force above the friendship-bound bends velocity in theory without changing its magnitude. In practice, integrating it tick by tick drifts the magnitude up or down over time. Re-project velocity onto its tracked magnitude after each tick that applied the force to cancel the drift. Below the bound, the speed-lock already does this.

## Bound-height data shape

The friendship-bound height lives on a `CourtConfig` Resource from day one. Per-court tunables cluster on this Resource alongside the bound height; `Court` reads from it. Loose `@export` on `Court` is not the path. The bound may become upgradable later through items or progression.

## Drag-handoff frame window

Miss does not fire while a grab is in flight. The drag controller's deferred swap creates a window where the live ball can arc past a side band before being replaced by the held body; during that window the side-miss check skips. The check resumes once the swap completes or the gesture cancels.

## Rest-roll energy loss

The rolled ball loses energy to venue-floor friction. Ball damping does not handle the rest-roll.
