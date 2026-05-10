# Wall-less Court Control

Today the rally tops out with a pong-bounce off a screen-edge ceiling, and balls straying past a paddle bounce off invisible walls and stay in play on the partner side (or end the rally on the player side, asymmetric). This spec replaces both with a single rule.

At the top, the ball rises past the friendship-bound, arcs back down under gravity, and the rally continues; the player feels the ball being held in by the friendship rather than rebounding off a ceiling. At either lateral edge, the ball rolls out onto the venue floor and lies among the items the player has placed, to be walked back to the rack.

The top collider goes; gravity engages on every live ball whose y is above a per-Court friendship-bound height, so each ball arcs back into play. The lateral walls go; a ball crossing either lateral edge fires a miss and rolls. The bottom (ground) is unchanged. Drives SH-309. Supersedes the apex-return section of `21-ball-dynamics.md` and the bounds/miss sections of `08-court-bounds.md`.

## Apex return

The bound is a per-Court height. Each live ball is in one of two states; the rule applies per ball, so multi-ball mixed-state is well-defined.

**At or below the bound, in friendship's uplift.** `gravity_scale` is `0` and speed is locked. Friendship's uplift cancels gravity and holds the rally's energy.

**Above the bound, uplift released.** `gravity_scale` rises to `1`, the speed-lock releases, and an additional centripetal force scaled by speed acts perpendicular to the ball's velocity, toward the play volume. The centripetal force rotates velocity without doing work; magnitude follows gravity, direction bends. Gravity decelerates the vertical component; the centripetal force redirects.

The ball tracks its pre-bound entry value: speed at the upward cross. Anything that changes the ball's speed above the bound updates this value, so a paddle hit above the bound or a partner-active arc captures the post-event speed, not the original entry.

Re-crossing below the bound restores the uplift on that ball: `gravity_scale` returns to `0`, the speed-lock relocks, speed ramps back up to the tracked pre-bound entry value. Rally energy is preserved across the apex visit; without the ramp, gravity-bleed above the bound would drain rally speed each visit.

The mechanism is engaged-gravity-with-centripetal-bend, not a vertical-velocity flip. A flip would read as an invisible ceiling (sawtooth ricochet); the engaged form reads as a held arc. The ball stays a live ball throughout; paddle hits register and the volley counter increments above the bound the same as below.

Cross-bound collisions resolve under each body's current physics state. Energy resolution is asymmetric across the bound and that is acceptable: the bound is a state line, not a collision filter.

Implementation should re-project velocity onto its target direction or substep at high speeds so "no work" holds numerically as well as mathematically; per-frame rotation gets sharp at Tier-3 speed ceilings.

This section supersedes the apex-return section of `21-ball-dynamics.md`, which described a velocity flip. The 21 section now redirects here.

## Miss

A miss is the rally-ending event. A ball whose centre crosses either lateral edge of the court fires a miss: friendship's uplift releases on that ball, gravity engages, the speed-lock releases, the rally counter resets. The ball retains its velocity at the moment of the cross, comes to rest on the venue floor where friction or damping stops it, and the player drags it back to the rack to re-serve. Past the side bands there is no centripetal and no relock ramp; the ball is leaving play, not arcing back.

Player-side and partner-side are the same event with the same outcome; both edges are lateral, both end the rally for the same reason (the ball got past a paddle's line). The partner already has its own miss zone in code; the player-side gets the same treatment when its wall is removed.

A live ball pulled to the rack mid-rally is not a miss; the drag controller already replaces the live ball with a held body before any band crossing can fire.

## Open questions

- **Energy loss on the rest-roll.** Should the rolled ball lose energy from the venue floor (grippy surface, ball decelerates by friction), from the ball itself (ball feels heavy, decelerates by damping), or both? The choice changes the feel of "rolls onto the floor".
- **Bound-height data shape.** Does the friendship-bound height live on a `VenueConfig` Resource from day one (clusters with other per-venue tunables, future-proofs multi-venue), or as a loose `@export` on `Court` for now and promoted later?
- **Drag-handoff frame window.** When a player grabs a live ball near a lateral edge while it is travelling outward, the drag controller swaps the live ball for a held body; the swap is deferred a frame, and during that frame the live ball can cross the band. Should the spec mandate that miss does not fire while a grab is in flight, or leave it as an implementer judgement?
