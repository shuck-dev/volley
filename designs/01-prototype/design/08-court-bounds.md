# Court Bounds and Miss

The court has a friendship-bound at the top, the ground at the bottom, and open sides left and right. The paddles sit on the sides; a ball that arcs past a paddle on either side ends the rally. No walls.

Implementation spec lives in [`../tech/08-court-control.md`](../tech/08-court-control.md).

**Dependencies:** Venue (`../08-venue.md`), Balls (`../08-balls.md`), Items (`../08-items.md`), Roles (`../08-roles.md`).

---

## The bounds

| Edge | Bound | Behaviour |
|---|---|---|
| Top | The friendship-bound | Below the bound, the ball is weightless. Above the bound, gravity engages and the ball arcs back into play. |
| Bottom | The ground | A pong bounce. Hitting the floor does not end the rally. |
| Sides | Open side bands | The paddles sit here. A ball that arcs past a paddle ends the rally; gravity carries it onto the venue floor among the items the player has placed. |

No walls and no ceiling. The court visibly opens onto the rest of the venue.

## The friendship-bound

The top of the play area is the friendship-bound. Below it the ball is weightless. Above it gravity engages and the ball bends back into play; faster balls turn tighter, slower balls trace wider loops. Either way the ball returns and the weightless state resumes.

The bound height is set on the court. Later it may be upgradable.

## Miss

A miss is one event: the ball arcs past a paddle on either side. The counter resets, the ball keeps its velocity, falls under gravity, and rolls to rest on the venue floor.

Player-side and partner-side share the same event. The ball got past a paddle, regardless of whose paddle.

## Resting balls

A ball rolled out of the court sits visibly on the venue floor wherever it stopped. Rested balls stay put across rallies, saves, and scene reloads.

To put a rested ball back into play, the player drags it onto the court for a manual serve, or drags it onto the rack to re-enter the auto-serve loop. Either path is supported and already implemented.

Balls can rest anywhere on the venue floor. The shop, workshop, and kit zones absorb them and let them roll to a stop like any other patch. The floor under a rack is a drop target, not a rest surface; a ball that enters it snaps into the rack instead.

## Drag-out distinguished from miss

A live ball pulled mid-rally back onto the rack is not a miss. The ball enters the inactive state cleanly and the rally continues with whatever balls remain. A live ball dropped outside the court without landing on the rack counts as a miss.

## Temporary balls

Temporary balls clear on their authored expiry regardless of where they land. A missed temporary ball despawns on miss; it does not roll out to rest. This keeps the on-floor population bounded to owned balls only.

## Helper upgrade (future)

A court-role item, a dog that fetches rested balls and returns them to the rack. Reuses the existing court-role plumbing; whether it ships as a fixture or a lighter behavioural item is an implementation choice for its own ticket.
