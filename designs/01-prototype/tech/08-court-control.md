# Wall-less Court Control

Implementation spec for the wall-less court: friendship-bound replaces the top collider, lateral side bands replace the side wall colliders, the ground is unchanged. Drives SH-309. Player-facing design lives in [`../design/08-court-bounds.md`](../design/08-court-bounds.md).

## Ball states

Each ball runs an independent state machine. Multi-ball mixed-state is well-defined.

```mermaid
stateDiagram-v2
    [*] --> STORED

    state PLAY {
        NORMAL --> ARC: cross above bound
        ARC --> NORMAL: cross below bound
    }

    state OUT {
        REST
        HELD
    }

    STORED --> PLAY: serve
    PLAY --> REST: miss
    PLAY --> HELD: mid-rally grab
    REST --> HELD: rest pickup
    HELD --> REST: drop on floor
    HELD --> PLAY: release into court
    HELD --> STORED: release into rack
```

**STORED.** On the rack, no body.

**PLAY-NORMAL** (at or below the friendship-bound). `gravity_scale = 0`, speed locked, linear damping off.

**PLAY-ARC** (above the friendship-bound). `gravity_scale = 1`, speed-lock off, linear damping off. Friendship pulls the ball back as engine gravity. The ball follows a parabolic arc: it climbs and decelerates, peaks, and falls back through the bound. Speed varies through the arc as kinetic energy converts to and from height. No centripetal force, no per-tick velocity re-projection.

The ball tracks its pre-bound entry value as a persistent register on the body: the first NORMAL→ARC upward cross sets it; subsequent crosses do not reset it. Speed-change events while in ARC (paddle hit, partner-active return) update the register to the post-event speed. On the downward cross back to NORMAL, speed ramps to the tracked value; rally energy is preserved across the apex visit.

The apex mechanism is engaged-gravity, not a vertical-velocity flip. A flip reads as an invisible ceiling; the engaged form reads as a held arc with weight. The ball stays in PLAY throughout; paddle hits register and the volley counter increments in ARC the same as in NORMAL. Loops are impossible by construction; no radial force acts on the ball.

**OUT-REST.** Out of play, on the venue floor. Includes the rolling-to-rest motion after a miss as well as the settled-and-still phase that follows. The ball waits to be grabbed.

**OUT-HELD.** Drag controller owns; the ball follows the cursor.

**Miss (PLAY → REST).** A ball whose centre crosses either lateral side band fires a miss: speed-lock releases, gravity engages, damping engages, the rally counter resets. The ball keeps its velocity at the moment of the crossing, falls under gravity, and rolls to rest on the venue floor. Past either side band there is no centripetal and no relock ramp. Player-side and partner-side are the same event.

**Mid-rally grab (PLAY → HELD).** The drag controller replaces the live ball with a held body before any side-band miss fires.

**Release into court (HELD → PLAY).** The cursor's Y at release decides the destination sub-state: above the friendship-bound lands in ARC, at or below lands in NORMAL.

**Drop on floor (HELD → REST).** A held ball released outside the court without landing on the rack drops cleanly into REST. No miss event fires; the rally counter is not reset.

The friendship-bound height lives on `CourtConfig`; see Bound-height data shape below.

## Cross-bound collisions

Collisions between an above-bound ball and a below-bound ball resolve under each body's current physics state. The above-bound ball's velocity changes per real physics. The below-bound ball's velocity *direction* changes per the collision; its locked *speed* (magnitude) re-asserts immediately after, since the speed-lock only constrains magnitude. Velocity and speed are distinct: the lock is on speed; direction is free.

The bound is a state line, not a collision filter.

## Bound-height data shape

The friendship-bound height lives on a `CourtConfig` Resource from day one. Per-court tunables cluster on this Resource alongside the bound height; `Court` reads from it. Loose `@export` on `Court` is not the path. The bound may become upgradable later through items or progression.

## Per-court physics seam

The above-bound physics rule lives on a `CourtPhysics` Resource referenced by `CourtConfig.physics`. `Ball._physics_process` calls `court_physics.step(ball, config, delta)` while in PLAY-ARC. Today's implementation is `ParabolicArcPhysics` (engine gravity, no extra force, no relock). Future venues can ship alternative rules without touching `Ball.gd`.

## Drag-handoff frame window

Miss does not fire while a grab is in flight. The drag controller's deferred swap creates a window where the live ball can cross a side band before being replaced by the held body; during that window the side-miss check skips. The check resumes once the swap completes or the gesture cancels.

## Rest-roll energy loss

The rolled ball loses energy to venue-floor friction. Ball damping does not handle the rest-roll.
