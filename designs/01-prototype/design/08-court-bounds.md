# Court Bounds and Miss

The court has a friendship-bound at the top, side bands left and right, the ground at the bottom, and the paddle line at the back. No walls.

Implementation spec lives in [`../tech/08-court-control.md`](../tech/08-court-control.md).

**Dependencies:** Venue (`../08-venue.md`), Balls (`../08-balls.md`), Items (`../08-items.md`), Roles (`../08-roles.md`).

---

## The bounds

| Edge | Bound | Behaviour |
|---|---|---|
| Top | The friendship-bound | Below the bound, the ball is weightless. Above the bound, gravity engages and the ball arcs back into play. |
| Bottom | The ground | A pong bounce. Hitting the floor does not end the rally. |
| Back | The paddle line | The miss line. The ball getting past the paddle ends the rally. |
| Sides | Open side bands | A ball crossing sideways rolls onto the venue floor and lies among the items the player has placed. |

No side walls and no ceiling. The court visibly opens onto the rest of the venue.

## The friendship-bound

The top of the play volume is the friendship-bound. Below it the ball is weightless. Above it gravity engages and the ball bends back into play; faster balls turn tighter, slower balls trace wider loops. Either way the ball returns and the weightless state resumes.

The bound height is per-venue. Small venues have a tighter ceiling, large venues breathe.

## Miss

A miss ends the rally. Two ways:

- The ball gets past the paddle's miss line (back-miss).
- The ball strays past either side band (side-miss).

Both reset the counter. Both fire the same gravity-and-roll behaviour: the ball carries its rally momentum onto the floor, then loses it to gravity and the floor, and comes to rest. The player drags it back to the rack to re-serve.

Player-side and partner-side share the same event. The ball got past a paddle's line, regardless of whose paddle.

### Cue layering

Bounces and misses read distinctly:

- **Bounce off the ground.** A short tick and a small squash on the floor. No camera impact.
- **Back-miss.** The existing miss beat plus a flash on the player paddle's edge. Rally counter resets with its current audio.
- **Side-miss.** A softer, lower-pitched variant of the miss beat. The ball is visibly still alive and rolling; the cue acknowledges the rally ended without pretending the ball is gone.

All cues are audio plus world-space. No screen-space banners.

## Resting balls

A ball rolled out of the court sits visibly on the venue floor wherever it stopped. The player can't serve from a rested ball; serves come from the rack. Rested balls stay put across rallies, saves, and scene reloads.

Balls can rest anywhere on the venue floor. The shop, workshop, and kit zones absorb them and let them roll to a stop like any other patch. Rack footprints are drop targets, not rest surfaces; a ball that enters one snaps into the rack instead.

If the player owns exactly one permanent ball and it is resting, the rack is empty and the main character idles. The player drags the resting ball back to the rack to re-enter the loop. This is intentional friction: a miss has a cost beyond the counter reset, and it teaches the rack gesture before the helper takes it away.

## Drag-out distinguished from miss

A live ball pulled mid-rally back onto the rack is not a miss. The ball enters the inactive state cleanly and the rally continues with whatever balls remain. A live ball dropped outside the court without landing on the rack counts as a miss.

## Temporary balls

Temporary balls (frenzy and similar) clear on their authored expiry regardless of where they land. A missed temporary ball despawns on miss; it does not roll out to rest. This keeps the on-floor population bounded to owned balls only.

## Helper upgrade (future)

A court-role item, a dog that fetches rested balls and returns them to the rack. Reuses the existing court-role plumbing; whether it ships as a fixture or a lighter behavioural item is an implementation choice for its own ticket.
