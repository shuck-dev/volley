# Wall-less Court Control

Implementation spec for the wall-less court: friendship-bound replaces the top collider, lateral side bands replace the side wall colliders, the ground is unchanged. Drives SH-309.

## Ball states

Ball lifecycle and the per-state physics rules live in [`02-ball-lifecycle.md`](02-ball-lifecycle.md). This doc covers only the court-control mechanics that drive transitions: the friendship-bound crossing, the side-band miss, and the apex return.

## Friendship-bound apex return

Both PLAY states run `gravity_scale = 0` with the speed locked: the magnitude is held at `speed` every tick, so the ball never gains or loses pace from the arc. PLAY-NORMAL (at or below the friendship-bound) flies straight. PLAY-ARC (above the bound) adds a computed downward acceleration to the velocity each tick; the speed-lock then re-asserts the magnitude, so the bend turns the direction without touching the speed. The path is a parabola, but it is shaped, not integrated: there is no engine gravity above the bound.

The arc is determined at the upward cross by the entry's upward speed and the court's arc rule. The apex emerges from how fast the ball entered (a steeper, faster entry arcs higher) and is capped so a hard entry cannot loft the ball off-screen. The descent mirrors the climb, so the ball crosses back down through the bound at the mirrored angle with its speed intact. No entry register, no relock ramp: there is nothing to restore because the speed never left.

The apex mechanism is a shaped bend, not a vertical-velocity flip. A flip reads as an invisible ceiling; the shaped form reads as a held arc. The ball stays in PLAY throughout; paddle hits register and the volley counter increments in ARC the same as in NORMAL. Loops are impossible by construction; no radial force acts on the ball.

## Side-band miss

A ball whose centre crosses either lateral side band fires a miss: speed-lock releases, gravity engages, damping engages, the rally counter resets. The ball keeps its velocity at the moment of the crossing, falls under gravity, and rolls to rest on the venue floor. Past either side band there is no centripetal force, and player-side and partner-side are the same event. The miss is the only place engine gravity acts on the ball.

The miss transitions the ball PLAY → OUT-REST; the state-transition handling itself lives in [`02-ball-lifecycle.md`](02-ball-lifecycle.md).

The friendship-bound height lives on `CourtConfig`; see Bound-height data shape below.

## Cross-bound collisions

Collisions between an above-bound ball and a below-bound ball resolve under each body's current physics state. The above-bound ball's velocity changes per real physics. The below-bound ball's velocity *direction* changes per the collision; its locked *speed* (magnitude) re-asserts immediately after, since the speed-lock only constrains magnitude. Velocity and speed are distinct: the lock is on speed; direction is free.

The bound is a state line, not a collision filter.

## Bound-height data shape

The friendship-bound height lives on a `CourtConfig` Resource from day one. Per-court tunables cluster on this Resource alongside the bound height; `Court` reads from it. Loose `@export` on `Court` is not the path. The bound may become upgradable later through items or progression.

## Per-court physics seam

The above-bound arc rule lives on a `CourtPhysics` Resource referenced by `CourtConfig.physics`. At the upward cross `Ball` asks it for the downward acceleration to apply this visit, given the entry's upward speed (`arc_acceleration`); the rule's `arc_gravity` and `arc_height_max` tunables set the arc shape and its ceiling. Future venues can ship alternative rules without touching `Ball.gd`.

## Drag-handoff frame window

Miss does not fire while a grab is in flight. The drag controller's deferred swap creates a window where the live ball can cross a side band before being replaced by the held body; during that window the side-miss check skips. The check resumes once the swap completes or the gesture cancels.

## Rest-roll energy loss

The rolled ball loses energy to venue-floor friction. Ball damping does not handle the rest-roll.
