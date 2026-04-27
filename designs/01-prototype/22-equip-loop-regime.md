# Equip-Loop Regime

Adversarial review of the homes-and-loose model proposed for item movement across the venue. The aim is to settle the regime before another impl round commits to a moving target. The model under challenge sits in [21-ball-dynamics.md](21-ball-dynamics.md) under "Containers and the swap pattern"; this doc steel-mans it, attacks it, names where it breaks, sketches alternatives, and lands a recommendation.

**Points:** Spike
**Surfaced by:** Bedtime Story churn around Challenge #403, three rounds of impl chasing an unspecified design.

---

## The model under challenge

Restated cleanly so the attack has a clear target.

Every item has a **rest home** and an **active home**. The rest home is the slot in a container (rack, shop, workshop). The active home is the place the item does its job: court for ball-role items, paddle for equipment, fixture marker for fixtures, applied-to-ball for effects. The court is one active home among several, not a catch-all release destination.

A drag is a non-physics preview. The held token is a `Node2D` riding the cursor; no body, no collisions, no solver cost. Three states bracket it: **token** at rest in a container, **dragged-gravity** during the gesture, **active-movement** when a ball-role item is on the court. A release into a valid home eases the body into that home. A release into the venue but outside any home spawns the item as a `RigidBody2D` with gravity on, the body falls, the body lands, the body stays. The player can grab a loose item with the same gesture they grab a live ball. Fixed venue spots (fixture markers, character positions) anchor specific items and characters.

The starter ball stops being a scene-authored fixture and becomes an owned item with a rest home in the rack, replacing the ad-hoc adoption SH-262 had to do.

## Steel-man

The strongest case for this model is that it collapses several special cases into one rule. A ball, an equipment item, a fixture, and an effect each look the same to the drag controller: pick up, preview, ask containers for accept, drop into the first that says yes, otherwise let physics own it. The court stops being a privileged target and becomes one of several owners with its own `can_accept`. Stray balls already work this way in the prototype; the model just generalises what is already true for one class to every class.

Diegesis is the second pillar. A held thing is a thing in the world. It went somewhere. If no slot took it, the world keeps it where the player left it. Teleport-restore on invalid release is the alternative, and teleport-restore is the move every shop UI does because it does not have a venue to fall into. Volley has a venue. The model uses the venue.

The third pillar is that the cost has already been paid. The body projection (`intersect_shape` against the at-rest collision shape at the candidate position) prevents bodies from spawning inside walls or partners. The container summary already exists. The drag flow is already symmetric across item classes by design. What is missing is the one rule that says **what happens when no container takes the drop**, and "loose physics body in the venue" answers that question with the same vocabulary the rest of the model already speaks.

## Steel-man of the opposing position

The court-as-default position: the venue is not a stockroom. A ball released anywhere except a slot belongs on the court, because the only thing a player does with a ball is play with it. Equipment released anywhere except a slot belongs back where it came from, because equipment off the paddle has no semantic. Fixtures released anywhere except their fixture marker are a category error; fixtures are placed, not held. Loose-in-venue is a clever uniformity that buys nothing the player asked for and costs floor clutter, save shape, performance, and a tidy affordance the player now has to learn.

The simpler rule: every item has a rest home and an active home, and an invalid release goes to whichever is more recent. No third state. No physics for items that are not currently doing their job. The drag controller's job is to find a home; if it cannot, it returns the item, and the gesture ends.

This position is not weak. It is what most games do, and the reason is that most games do not benefit from a venue that holds ambient objects.

---

## Adversarial questions

### 1. Does loose-in-venue make the game better, or just add clutter?

It makes the game better only if the venue is somewhere the player wants to spend time. Volley's venues are the rally surface plus a small amount of surrounding space. A ball that has rolled off the court onto the venue floor reads as "stray", and stray reads as the kind of cosy texture the game wants. An equipment item lying on the floor reads differently: it reads as something the player forgot to put away. The model wins when the loose object is a ball; it loses when the loose object is anything else.

The fix is to scope loose to ball-role items only. Equipment, fixtures, and effects do not get a loose state. An invalid release for those classes returns to the rest home directly, with the same eased tween the model already specifies.

### 2. What happens at save / load? Does state grow unbounded?

Bounded by the player's behaviour. A player who never tidies accumulates loose balls until the venue floor stops accepting more, at which point the floor's geometry is the cap. The save shape persists each loose ball's position and `linear_velocity`. Restore is the same as the rally case in [21-ball-dynamics.md](21-ball-dynamics.md): reconstruct at persisted state, advance physics from there.

The unbounded case the question worries about is "a player who plays for a thousand rounds and now has a hundred loose balls". A hundred `RigidBody2D` instances at rest is not a performance problem (Box2D sleeps them), and a hundred bodies' worth of save shape is bytes, not megabytes. The cap is a soft one: if the loose count crosses a threshold (rough budget: 64), the oldest loose ball despawns the next time the player leaves the venue, with a small diegetic excuse (the dog took it, the tide came in for the underwater venue). The threshold is a tuning surface, not a load-bearing rule.

### 3. Performance: how many loose physics bodies before the solver chokes?

Box2D in Godot 4 sleeps bodies that have been at rest for ~0.5 s. A sleeping body costs roughly nothing per tick. The solver's working set is awake bodies, not total bodies. A venue with 64 loose balls at rest plus a live rally of 1 to 3 balls is well under any practical limit. The risk case is a transient where many loose balls are shoved at once (a ball rolls into a stack), which spikes awake count for a frame or two; this is fine for the game's pacing.

The hard cap from the engine's side is not the relevant cap. The relevant cap is visual: a venue floor cluttered with sixty balls reads as broken, not cosy. The visual cap (around 8 to 12 visible loose balls before the floor reads as overrun) is below the engine's cap by an order of magnitude. The despawn rule above keeps the visual cap, the engine cap takes care of itself.

### 4. Tidy-up affordance, or drift?

A dedicated tidy button is bad: it is a chore the player has to remember, and the game has no other chores. Drift is good: balls disappear gradually as the threshold despawn fires between sessions, the player notices the floor stays roughly clear, and no UI was added.

The diegetic excuse is the lever. Different venues retire loose balls differently. A pet brings them back to the rack in V1, the tide claims them in V2, and so on. The retirement is part of the venue's character, not a system the player operates.

### 5. Effect items: what does loose mean?

Nothing. Effects have no physical form. The model excludes them: effects only ever have a rest home (the rack slot) and an active home (the applied-to-ball state). An invalid release for an effect returns to the rest home with the model's standard eased tween. This is consistent with the steel-man's "loose-in-venue is for ball-role items only" scope.

### 6. Drag-and-drop precision: how forgiving is home-detection?

The body-projection rule already handles wall-edge cases for the court. For the rack and shop, slot acceptance is a bounds check inflated by a forgiveness margin (rough budget: half a slot's width). The held token's hover feedback (slight lift, modulation, scale bump) tells the player which positions accept. A "near miss" on a rack that lands inside the forgiveness margin snaps to the slot. A miss outside the margin is loose, for ball-role items, or returns to the rest home, for everything else.

The forgiveness margin is a tuning surface. Too generous and the player feels they cannot place a ball loose deliberately; too tight and minor cursor jitter throws the ball on the floor. Calibrate against the smallest authored rack slot.

### 7. Loose state across venue leaps?

The narrative says venue leaps are diegetic transitions, not save/load events. A loose ball in V1 does not appear in V2; the leap is a fresh venue with its own ambient state. The retirement rule (Q4) covers the disappearance: V2 does not hold V1's strays because V1's pet kept them.

The mechanical answer: serialise loose state per-venue, restore per-venue. Loose balls are venue-local. This is one extra dimension on the save shape, no other model change.

### 8. Does the rack become optional once loose-in-venue is the default?

Only if loose-in-venue is the default for everything, which it isn't. The model scopes loose to ball-role items, and even there, the rack is the rest home. Loose-in-venue is the **failure case** for an invalid release of a ball-role item, not the default state. The rack stays the canonical home for any ball not currently in play.

The question's worry is real for one edge: a player who learns that loose works as well as racked might stop using the rack. The answer is friction. The rack is faster to read (the count is visible at a glance), and a ball in the rack does not consume venue floor space the player might want to use for other things. The rack is the convenient option; loose is the option that exists because the world is a world.

### 9. Released-ball case: does loose-but-not-in-play feel coherent?

This is the question that earns the model. A ball that has rolled off the court is the canonical loose case, and it is already coherent: the rally moved the ball, the ball left the rally, the ball is on the floor, the player picks it up and serves it again. A ball **released** loose by the player (drag from rack, release on the venue floor) reads the same way: the player chose not to put the ball into play right now, and the world honours that choice.

The risk is that the player releases a ball loose by accident, missing the court, and reads the result as an error. The fix is the hover feedback at release: the held token communicates which position will go to court, which to rack, and which is loose, and the player's release is informed.

### 10. Is "court is just a ball-application state" actually true?

Mostly. The court owns ball-role items in active-movement. Partner paddle position is owned by the partner, not the court. Miss zones are court geometry, not ball state. Ball physics material is a property of the court's `PhysicsMaterial`, applied at collision time. The leak the question worries about is: when the court owns the ball's physics material, the court is more than a state. True, but the leak is small. The court is **a state plus a small amount of context** (the wall geometry, the physics material, the spawn rules). That is the same shape every container has: a state plus context.

The honest answer is that the court is not radically symmetric with the rack; the court has more behaviour. The model's claim is that the **drag controller's view** of the court is symmetric with its view of any other container. The controller asks `can_accept`, hands off the body, and forgets. What the court does internally is its own concern. This is the level of symmetry the model needs.

---

## Failure modes

### Cluttered floor as a mood

The model assumes loose balls read as cosy texture. They might not. A venue floor with eight balls scattered across it is the sort of background detail that one player reads as "lived-in" and another reads as "I should clean this". The model has no answer for the second player except the despawn rule (Q4), which is slow. If playtest shows the cosy read fails, the fallback is to scope loose even further: only the most recent loose ball persists, older ones retire on the next round boundary. This trades the model's "world keeps what you left" promise for visual cleanliness; the trade is acceptable if the cosy read fails, and the lever is one threshold value.

### Body projection holes for moving obstacles

The drop validation uses `intersect_shape` against current geometry. If a partner is mid-stride and the projection sees the partner's collision body at frame N but the partner has moved by frame N+1, the body could spawn inside the partner anyway. The model's defence is the projection runs every physics frame on the held position, not on mouse-up; a release lands the first frame the projection passes. But if no frame passes (the partner is dancing across the only valid spot), the gesture stays open indefinitely. The player feels the held thing is sticky.

The fix is a small expansion ring around the projection shape during release: if the strict projection fails for more than ~250 ms, retry with a 1.5x scaled shape. If that still fails, the gesture cancels back to the source. This trades model purity for player tolerance. The trade is cheap.

---

## Alternatives

### Alternative A: court-as-default, no loose state

Every release inside the venue but outside a recognised home goes to the court at the nearest valid play point. No loose floor balls, no third state, no body projection on the venue floor. Equipment off-paddle returns to its rack. Fixtures off-marker return to their rack. Balls off-court go to court.

**Trade-offs.** Simpler model, smaller save shape, no clutter risk, no despawn rule. Loses the diegetic feel of "the world keeps what you left there". Loses the symmetry with stray balls; strays still need a treatment, and now they are the special case the model does not handle. The starter ball still gets owned-as-item, which was the original SH-262 driver. This alternative is the conservative ship.

### Alternative B: physics always, no Node2D held state

Drop the held-as-`Node2D` step. The body spawns as a `RigidBody2D` immediately on grab, with gravity off and a per-frame steer toward the cursor. Release is just the steer turning off. The body always has a physical existence; the only difference between held, loose, and active is which forces and rules are applied to it.

**Trade-offs.** Physically pure: one body type, one lifecycle, no swap pattern. The grab feels heavier (the body has weight even in the air; the cursor is dragging a thing, not previewing one), which might match Volley's tactile aim. Costs solver work during the drag (the steer is a constraint solve every frame, multiplied by held items, which is rarely more than one but adds up if a future feature allows multi-grab). Costs the freedom to make the held visual cheaper or more stylised than the body (the held thing IS the body, so it has to look like the body). Forces the body-projection rule to run continuously during the gesture rather than only at release, which is more solver work.

This alternative is the radical ship. It is more coherent than the proposed model on one axis (body identity is constant) and less coherent on another (held is not preview, the player is fighting solver state during the gesture).

---

## Recommendation

Ship the model as proposed in [21-ball-dynamics.md](21-ball-dynamics.md), with three scoped amendments:

1. Loose state applies only to ball-role items. Equipment, fixtures, and effects return to their rest home on invalid release.
2. Loose balls retire diegetically per venue, with a soft cap around 8 to 12 visible. The cap is a tuning surface.
3. Body projection on release uses an expansion-ring fallback after a short hold, then cancels to source if even the expanded shape fails.

The model is the right shape because the venue is part of the game's character, not just a backdrop. Volley's cosy register earns the loose-in-venue rule; a less ambient game would not. The amendments narrow the model to where it pays back and away from where it costs floor clutter, save shape, or solver work for no benefit.

## Follow-ups

If the recommendation lands, file:

- **Impl ticket.** Wire the regime into the drag controller, the rack, the shop, the court, and the held-token visual. Body projection with the expansion-ring fallback. Loose state for ball-role items.
- **Save shape ticket.** Persist loose balls per-venue with position and `linear_velocity`. Restore on load. Soft cap retirement on next venue exit.
- **Performance bounds ticket.** Define the soft cap (8 to 12 visible) as a tuning constant, profile a worst-case venue with 64 loose bodies, confirm the engine cap is well above the visual cap.
- **Narrative-leap handling ticket.** Per-venue serialisation, diegetic retirement excuse per venue (V1 pet, V2 tide).
- **Starter ball ticket.** Convert the scene-authored Ball (the one SH-262 adopted) into an owned starter item with a rack rest home.
