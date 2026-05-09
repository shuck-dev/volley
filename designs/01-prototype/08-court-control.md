# Wall-less Court Control

Today the rally tops out with a pong-bounce off a screen-edge ceiling, and balls straying past a paddle bounce off invisible walls and stay in play on the partner side (or end the rally on the player side, asymmetric). This spec replaces both with a single rule.

At the top, the ball rises past the friendship-bound, arcs back down under gravity, and the rally continues; the player feels the ball being held in by the friendship rather than rebounding off a ceiling. At either lateral edge, the ball rolls out onto the venue floor and lies among the items the player has placed, to be walked back to the rack.

The top collider goes; gravity engages on every live ball whose y is above a per-Court friendship-bound height, so each ball arcs back into play. The lateral walls go; a ball crossing either lateral edge fires a miss and rolls. The bottom (ground) is unchanged. Drives SH-309. Supersedes the apex-return section of `21-ball-dynamics.md` and the bounds/miss sections of `08-court-bounds.md`.

## Apex return

The bound is a per-Court height. Each live ball whose y is above the bound has gravity on; each at or below has gravity off. The ball arcs naturally above the bound and rally physics resume on re-entry. Multi-ball is supported by construction; the rule applies per ball.

The mechanism is gravity-toggling, not a vertical-velocity flip. A flip would read as an invisible ceiling (sawtooth ricochet); the toggle reads as a held arc. The ball stays a live ball throughout the arc; paddle hits register and the volley counter increments above the bound the same as below.

This section supersedes the apex-return section of `21-ball-dynamics.md`, which described a velocity flip. The 21 section is retired or rewritten as part of the apex-return implementation.

## Miss

A miss is the rally-ending event. A ball whose centre crosses either lateral edge of the court fires a miss: gravity engages, the rally counter resets, the ball comes to rest on the venue floor where friction or damping stops it, and the player drags it back to the rack to re-serve.

Player-side and partner-side are the same event with the same outcome; both edges are lateral, both end the rally for the same reason (the ball got past a paddle's line). The partner already has its own miss zone in code; the player-side gets the same treatment when its wall is removed.

A live ball pulled to the rack mid-rally is not a miss; the drag controller already replaces the live ball with a held body before any band crossing can fire.

## Open questions

- **Energy loss on the rest-roll.** Should the rolled ball lose energy from the venue floor (grippy surface, ball decelerates by friction), from the ball itself (ball feels heavy, decelerates by damping), or both? The choice changes the feel of "rolls onto the floor".
- **Bound-height data shape.** Does the friendship-bound height live on a `VenueConfig` Resource from day one (clusters with other per-venue tunables, future-proofs multi-venue), or as a loose `@export` on `Court` for now and promoted later?
- **Drag-handoff frame window.** When a player grabs a live ball near a lateral edge while it is travelling outward, the drag controller swaps the live ball for a held body; the swap is deferred a frame, and during that frame the live ball can cross the band. Should the spec mandate that miss does not fire while a grab is in flight, or leave it as an implementer judgement?
