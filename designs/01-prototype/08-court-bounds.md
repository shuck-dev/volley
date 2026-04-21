# Court Bounds and Miss

The court is not a closed box. It sits inside the venue, bounded on three sides and open on one; missed balls leave the court and rest on the venue floor until the player puts them back.

**Dependencies:** Venue (`08-venue.md`), Balls (`08-balls.md`), Kit (`08-kit.md`), Items (`08-items.md`), Roles (`08-roles.md`), Fixtures (`08-fixtures.md`).

---

## Bounds

| Edge | Bound | Behaviour |
|---|---|---|
| Top | The screen edge | The camera never scrolls up; the top of the frame is a hard ceiling the ball bounces off. |
| Bottom | The ground | Physical floor; ball bounces off (pong-style). Hitting the floor does not end the rally. |
| Back | The main character's wall | The goal line. Ball crossing this is a miss. |
| Sides | Open | The ball can leave the court sideways; leaving this way is also a miss. |

No side walls. The court visibly opens onto the rest of the venue.

### Miss-detection regions

Two bands along the court sides detect sideways exits. Both run the full height of the play area.

```
  ┌──────────── top (ceiling, bounce) ─────────────┐
  │                                                │
  │  miss-out                              miss-out │
  │  ┌──┐                                    ┌──┐  │
  │  │  │          in-play court             │  │  │
  │  │  │                                    │  │  │
  │  │  │ main character's goal line (back)  │  │  │
  │  │  │ ┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄ │  │  │
  │  │  │          ground (bounce)           │  │  │
  │  └──┘                                    └──┘  │
  └────────────── venue floor ─────────────────────┘
```

- **In-play region:** bounded by the top (ceiling), the ground (bounce floor), and the goal line at the back. A ball inside this region is live.
- **Goal-line band:** a thin trigger just behind the main character. Crossing it fires a back-miss.
- **Side miss bands:** one on each side, just outside the court's lateral extent. Crossing either fires a side-miss.

Detection uses `Area2D` triggers rather than tight collider math: the ball's centre entering a band is the event. This keeps the signal independent of ball radius or rotation quirks.

---

## Miss

A miss ends the current rally. It fires when either:

- The ball crosses the main character's goal line (back-miss, existing miss condition).
- The ball leaves the court sideways without first landing back in play (side-miss).

On miss, the rally counter resets to zero (existing behaviour). The ball does not despawn; it keeps its velocity, rolls out of the court, loses energy on the venue floor, and comes to rest.

### Cue layering

Bounces and misses read distinctly:

- **Bounce off a bound** (top ceiling, ground): a short tick and a small squash on the bound itself. No camera impact.
- **Back-miss:** the existing miss beat plays; the main character's wall flashes. Rally counter resets with its current audio.
- **Side-miss:** a softer, lower-pitched variant of the miss beat. The ball is visibly still alive and rolling; the cue acknowledges the rally ended without pretending the ball is gone.

All three are audio + world-space only. No screen-space banners (per venue diegetic rule).

---

## Resting balls in the venue

A ball that has rolled out of the court sits visibly on the venue floor wherever it stopped. The player can't serve from a rested ball; serves come from the ball rack.

To bring the ball back into play, the player drags it from the venue floor onto the `BallRack`. The ball becomes inactive and is available to drag back onto the court for the next rally, or the auto-serve picks it up when the rack's turn comes round (see `08-balls.md`).

Rested balls stay put across rallies, saves, and scene reloads. Persistence lives alongside the ball's own state: position on the venue floor, last velocity (zero at rest), and the `resting` flag.

### Where balls can legally rest

Balls can come to rest anywhere on the venue floor. They always render in the mid or foreground relative to the shop/workshop backgrounds, so they stay visible regardless of where they land. No invisible barriers around the shop, workshop, or kit areas; those zones absorb the ball and let it roll to a stop like any other floor patch.

One exception: the ball rack and gear rack themselves are drop targets, not rest surfaces. A ball that enters the rack's footprint snaps into the rack (racked, not resting). This matches the existing drag-to-rack gesture.

### Auto-serve interaction with a resting ball

If the player owns exactly one permanent ball and it is resting on the venue floor at the moment the rally needs a serve:

- The ball rack is empty (the ball is not racked), and the court is empty (the ball is not in play).
- The main character walks to the rack, finds it empty, and idles.
- The player must drag the resting ball onto the rack to re-enter the loop.

This is intentional friction. The main character does not fetch rested balls in the prototype; that job belongs to the future helper (below). Making the player re-rack reinforces that a miss has a cost beyond the rally counter reset, and it teaches the rack gesture before the helper takes it away.

If the player owns multiple permanent balls, the auto-serve picks whichever is racked. Rested balls sit out of rotation until re-racked.

---

## Drag-out distinguished from miss

The player can drag a live ball off the court back onto the ball rack mid-rally (see `08-balls.md`). That is not a miss: the ball enters the inactive state cleanly and the rally continues with whatever balls remain.

If the player drops the ball outside the court bounds without landing on the rack, it counts as a miss. The ball rolls to rest on the venue floor; the rally ends if it was the last live ball.

---

## Temporary balls

Temporary balls (frenzy, etc.) clear on their authored expiry regardless of where they land. A missed temporary ball despawns on miss like any other; it does not roll out to rest. A temporary ball that leaves sideways triggers a side-miss the same way a permanent one does, then despawns instead of resting.

This keeps the on-floor population bounded to owned balls only.

---

## Visual clutter

The player will never own enough balls for visual clutter to become a problem at prototype scale. No cap, decay, or cleanup pass is in scope. If later content expands the owned-ball count dramatically, the helper item (below) absorbs the clutter naturally.

---

## Helper upgrade (future, not in prototype scope)

A `court` role item that automatically fetches rested balls and returns them to the rack. Authoring follows the existing court-item shape:

- `role = &"court"` so it snaps to a `Roles/Court` marker on drag-in.
- Acts as a fixture (see `08-fixtures.md`) if its prop needs to sit in the venue; if a simple behavioural item is enough, it skips the fixture scene and just attaches a controller script.
- Behaviour: scans for balls with the `resting` flag, walks or teleports a small animated helper to each, returns them to the rack one at a time on an authored cadence.

The helper reuses the bot's `court` role plumbing; it does not need a new role. Whether it uses the bot's fixture shape or a lighter behavioural item is an implementation choice for its own ticket.

---

## Resolved questions

From the spike:

1. **Ball-ground interaction.** Pong-style bounce. Hitting the floor does not end the rally.
2. **Rally-ending condition.** Back-miss (goal line) or side-miss (lateral exit). Both reset the counter.
3. **Clutter.** Not a real problem at prototype scale. No cap or decay.
4. **Where rested balls can sit.** Anywhere on the venue floor. No invisible barriers. Rack footprints snap-to-rack instead of resting.
5. **Auto-serve with one ball resting.** Main character idles; player must re-rack. The helper fixes this later.
6. **Temporary balls.** Despawn on miss as before, regardless of where they land.
7. **Cues.** Three distinct audio/world beats: bounce, back-miss, side-miss. All diegetic.
8. **Helper authoring.** `court` role item. Fixture or behavioural controller is its own ticket's call.

---

## Out of scope

Called out so they don't leak into implementation:

- Helper upgrade item, its prop scene, and its fetch cadence tuning.
- Miss-ending-the-rally vs miss-ending-this-ball distinction for multiball (handled in `08-balls.md`).
- Visual polish on the rest-roll deceleration curve; tuned during implementation.

---

## Implementation ticket outline

Not filing yet. Rough split, each intended to land independently:

1. **Court bounds geometry.** Top ceiling collider, ground collider, goal-line trigger, two side-miss triggers. Hook the side triggers to the existing miss path. Ceiling bounce + ground bounce behaviour verified.
2. **Ball rest state.** `resting` flag, deceleration on the venue floor, persistence of rest position and flag across saves and scene reloads.
3. **Drag rested ball to rack.** Reuse the existing drag-to-rack handler; accept `resting` balls as a valid source. Live rally handling unchanged.
4. **Side-miss cue.** Audio variant + wall flash on the relevant side. Back-miss cue unchanged.
5. **Auto-serve when rack is empty.** Idle the main character; no fetch in prototype. (Confirms the friction beat behaves as designed.)

Helper upgrade is its own later ticket and is not part of this prototype slice.
