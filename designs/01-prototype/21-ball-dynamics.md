# Ball Dynamics

The ball-feel decisions. Implementation detail is deliberately thin; the ideas are the canon.

**Dependencies:** [Balls on the Court](08-balls.md), [Partner AI](17-partner-ai.md), [Make Fun Pass](16-make-fun.md), [Effect System](07-effect-system.md).

---

## Return angle

The paddle's hit offset drives the return angle. Centre hits go flat, edge hits go steep, up to roughly a sixty-degree ceiling at full influence. The placeholder "bias toward horizontal" behaviour is removed because it fights the player's intent.

## Speed curve

Speed climbs linearly per paddle hit, from a per-tier floor to a per-tier ceiling. A diminishing curve makes the top end feel like a wall the rally can never cross; that undercuts the moment a long rally caps. Tuning lives in the base-stats config and the speed-tier table, never as a curve type baked into code.

## Spin and curve

Out of scope as a baseline ball behaviour. Curve ships only through items as local fields (gravity wells, deflectors), not as a global ball trait. A constant curve makes every miss feel like the game's fault; a local field reads as a chosen risk.

## Physics model

`RigidBody2D` with a per-frame speed clamp. A kinematic rewrite would cost more than it saves: walls, paddles, and future static fixtures all reflect for free under the existing material. Tunnelling at the current top speed is well within the physics tick; if items push the cap higher, switch the body to shape-cast continuous collision rather than rewrite.

## Item compatibility

The planned ball-affecting items (gravity well, deflection, multi-ball, speed oscillation) all slot into the processor-plus-stats model without touching `Ball` itself. Each is a one-line addition on top of the baseline.

## AI prediction

Linear with reflections, exact for the baseline rally. Local curve fields are designed to break it: a partner that misses more under a gravity well is correct partner feel, not a bug. Multi-ball picks the nearest projected intercept.

## Bounce variance

No random noise on bounces. Variance is systemic, from paddle offset and the speed climb; random noise reads as the game being inconsistent rather than the player being good.

---

## Regime: three shapes

A ball appears in three places: a rack token at rest, a held token under the cursor, a live rally body. Three node types, one per shape. Held is never physics; live always is.

Transitions swap shape rather than mutate one body. A rack click spawns a held token. A mid-rally grab destroys the live ball and spawns a held token in its place. Release over the court spawns a live ball. Release over the rack destroys the held token and the rack regrows its slot.

Single-ball-on-court was an accidental constraint, not a rule. The reconciler tracks every live ball; consumers subscribe per-ball. Each ball carries its own speed; the streak counter is shared rally state.

## Three states (across all draggable items)

Every item lives in one of three states:

- **Token.** No physics body; sits in its container's slot, sized by the item definition.
- **Dragged-gravity.** A physics body, frozen while the cursor pins it, gravity engaged once released without a target. Stray balls that have left the court also live in this state.
- **Active-movement.** A physics body with gravity off and frictionless momentum. Only ball-role items enter this state, and only when the court owns them.

Transitions between states ease, never snap. Position, scale, and modulation read as continuous through the state change. The exception is the release-onto-court transition, where the body's velocity itself is the continuity; no tween needed.

## Speed is friendship

Rally speed carries through grab-and-release: a mid-rally grab is a redirect, not a reset. The magnitude survives the held-token detour; the gesture chooses only the direction. Speed only resets on miss.

## Drop validation

Release polls every drop target on the held position each physics frame; the first target that accepts wins. For containers that respawn a non-physics token (shop, rack), validation is a bounds check. For the court, validation is a body projection: query the rally space with the body's at-rest collision shape and reject any overlap. The body never spawns inside another body.

## No restore on invalid release

The held token does not teleport home on a bad release. Teleport-restore is non-diegetic. The gesture stays open until a target accepts; mouse-up is a hint, not a gate. The source container is always a valid target, so the player always has a way to put the thing back.

## Press without movement

A press lifts the preview but does not drop. The drop gate opens only past a movement threshold. Press-and-release on any container is a no-op; the player has to commit to the gesture.

---

## Friendship-bound apex return

See [`08-court-control.md`](08-court-control.md) § Apex return.
