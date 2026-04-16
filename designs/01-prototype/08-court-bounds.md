# Court Bounds and Miss

The court is not a closed box. It sits inside the venue, bounded on three sides and open on one; missed balls leave the court and rest on the venue floor until the player puts them back.

**Dependencies:** Venue (`08-venue.md`), Balls (`08-balls.md`), Items (`08-items.md`), Roles (`08-roles.md`).

---

## Bounds

| Edge | Bound | Behaviour |
|---|---|---|
| Top | The screen edge | The camera never scrolls up; the top of the frame is a hard ceiling the ball bounces off. |
| Bottom | The ground | Physical floor; existing ball-ground behaviour is unchanged. |
| Back | The main character's wall | The goal line. Ball crossing this is a miss. |
| Sides | Open | The ball can leave the court sideways; leaving this way is also a miss. |

No side walls. The court visibly opens onto the rest of the venue.

---

## Miss

A miss ends the current rally. It fires when either:

- The ball crosses the main character's goal line (existing miss condition).
- The ball leaves the court sideways without first landing back in play.

On miss, the rally counter resets to zero (existing behaviour). The ball does not despawn; it keeps its velocity, rolls out of the court, loses energy on the venue floor, and comes to rest.

---

## Resting balls in the venue

A ball that has rolled out of the court sits visibly on the venue floor wherever it stopped. The player can't serve from a rested ball; serves come from the ball rack.

To bring the ball back into play, the player drags it from the venue floor onto the `BallRack`. The ball becomes inactive and is available to drag back onto the court for the next rally.

Rested balls stay put across rallies, saves, and scene reloads.

---

## Helper upgrade (future)

A helper is a `court` role item that automatically fetches rested balls and returns them to the rack. Same authoring shape as the bot (item + fixture + prop scene): it walks to each rested ball, picks it up, and drops it onto the rack. Without a helper, the player does this themselves.

Not in prototype scope; flagged here so the ball-fetch behaviour has an obvious upgrade path. Sits alongside the bot in later projects.

---

## Drag-out distinguished from miss

The player can drag a live ball off the court back onto the ball rack mid-rally (see `08-balls.md`). That is not a miss: the ball enters the inactive state cleanly and the rally continues with whatever balls remain.

If the player drops the ball outside the court bounds without landing on the rack, it counts as a miss. The ball rolls to rest on the venue floor; the rally ends if it was the last live ball.

---

## Temporary balls

Temporary balls (frenzy, etc.) clear on their authored expiry regardless of where they land. A missed temporary ball despawns on miss like any other; it does not roll out to rest.

---

## Resolved questions

1. **Ball-ground interaction during play.** The ball bounces off the ground (pong-style). Hitting the floor does not end the rally.
2. **Visual density with many rested balls.** The player will never own enough balls for visual clutter to become a problem. No cap or decay needed.
3. **Where rested balls can legally sit.** Balls can go anywhere in the venue. They always render in the mid or foreground relative to the shop background, so they stay visible regardless of where they land.

---

## Out of scope

Not in this project, called out so they don't leak:

- Helper upgrade item and its prop scene.
- Ball-fetch animation tuning.
- Miss-ending-the-rally vs miss-ending-this-ball distinction for multiball (handled in `08-balls.md`).
