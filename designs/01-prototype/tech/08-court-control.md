# Wall-less Court Control

Implementation spec for the wall-less court: friendship-bound replaces the top collider, lateral side bands replace the side wall colliders, the ground is unchanged. Drives SH-309. Player-facing design lives in [`../design/08-court-bounds.md`](../design/08-court-bounds.md).

## Per-ball state

Each live ball is in one of two states. The rule applies per ball, so multi-ball mixed-state is well-defined.

**At or below the friendship-bound, in friendship's uplift.** `gravity_scale = 0`, speed is locked, linear damping is off.

**Above the friendship-bound, uplift released.** `gravity_scale = 1`, speed-lock releases, linear damping engages. A centripetal force scaled by speed acts perpendicular to velocity, toward the play volume. The centripetal force rotates velocity without doing work; magnitude follows gravity, direction bends.

The bound is a per-Court height.

## Apex return

A ball crossing upward through the bound has its uplift released. Gravity decelerates the vertical component; the centripetal force redirects.

The ball tracks its pre-bound entry value: speed at the upward cross. Any speed change above the bound updates this value, so a paddle hit above the bound or a partner-active arc captures the post-event speed.

Re-crossing below the bound restores the uplift on that ball: `gravity_scale = 0`, speed-lock relocks, damping disengages, speed ramps back up to the tracked entry value. Rally energy is preserved across the apex visit.

The mechanism is engaged-gravity-with-centripetal-bend, not a vertical-velocity flip. A flip reads as an invisible ceiling; the engaged form reads as a held arc. The ball stays a live ball throughout; paddle hits register and the volley counter increments above the bound the same as below.

## Miss

A ball whose centre crosses either lateral side band fires a miss: uplift releases on that ball, gravity engages, speed-lock releases, damping engages, the rally counter resets. The ball retains its velocity at the moment of the cross, comes to rest on the venue floor, and the player drags it back to the rack via the existing live-ball drag path. Past either side band there is no centripetal and no relock ramp.

Player-side and partner-side are the same event. The partner already has its own miss zone in code; the player-side gets the same treatment when its wall is removed.

A live ball pulled to the rack mid-rally is not a miss; the drag controller replaces the live ball with a held body before any band crossing fires.

## Cross-bound collisions

Collisions between an above-bound ball and a below-bound ball resolve under each body's current physics state. Energy resolution is asymmetric across the bound and that is acceptable. The bound is a state line, not a collision filter.

## Numerical stability

At Tier-3 speeds the per-frame rotation is sharp. Implementation should re-project velocity onto its target direction or substep so "no work" holds numerically as well as mathematically.

## Open questions

- **Energy loss on the rest-roll.** Venue-floor friction, ball damping, or both? Tuning, not correctness.
- **Bound-height data shape.** `VenueConfig` Resource from day one, or a loose `@export` on `Court` promoted later?
- **Drag-handoff frame window.** When the player grabs a live ball near a side band while it is travelling outward, the swap is deferred a frame and the live ball can cross during that frame. Mandate "miss does not fire while a grab is in flight" in spec, or leave to implementer judgement?
