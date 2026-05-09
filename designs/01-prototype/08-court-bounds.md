# Court Bounds and Miss

Court geometry, the apex return, and the miss event live in [`08-court-control.md`](08-court-control.md). This doc covers cues, the spirit-of-the-volley framing, the rest-balls flow, and the future helper.

**Dependencies:** Venue (`08-venue.md`), Balls (`08-balls.md`), Items (`08-items.md`), Roles (`08-roles.md`).

---

## Cues

Bounces and misses read distinctly. Bounces off the ground are a short tick and a small squash on the ground itself, no camera impact. A miss is the existing miss beat plus a flash on the player paddle's edge; the rally counter resets with its current audio. The ball is visibly still alive and rolling onto the venue floor; the cue acknowledges the rally ended without pretending the ball is gone. All cues are audio plus world-space, never screen-space banners.

## Spirit of the volley

A rally is how the spirit of the volley shows up. It is not owned by the player and it does not live in the ball; it answers commitment to the exchange and holds the ball up for as long as that commitment keeps paying out. Every return is tribute. The counter is how present the spirit is in this rally, not how many points were scored.

A miss sends the spirit away. It does not leave in anger; it leaves because there is nothing left to answer. The ball loses what kept it weightless and does what balls do.

A player can call the spirit alone. Partners amplify it but do not create it. High-count rallies visibly run hotter; the ball carries the spirit's charge in how it reads. A miss drains it; the ball on the venue floor is just a ball. Items that extend or revive rallies are gestures of devotion to the spirit.

## Resting balls

A ball rolled out of the court sits visibly on the venue floor wherever it stopped. The player can't serve from a rested ball; serves come from the rack. Rested balls stay put across rallies, saves, and scene reloads.

Balls can rest anywhere on the venue floor; the shop, workshop, and kit zones absorb them and let them roll to a stop like any other patch. Rack footprints are drop targets, not rest surfaces; a ball that enters one snaps into the rack instead.

If the player owns exactly one permanent ball and it is resting, the rack is empty and the main character idles. The player drags the resting ball back to the rack to re-enter the loop. This is intentional friction: a miss has a cost beyond the counter reset, and it teaches the rack gesture before the helper takes it away.

## Drag-out distinguished from miss

A live ball pulled mid-rally back onto the rack is not a miss; the ball enters the inactive state cleanly and the rally continues with whatever balls remain. A live ball dropped outside the court without landing on the rack counts as a miss.

## Temporary balls

Temporary balls (frenzy and similar) clear on their authored expiry regardless of where they land. A missed temporary ball despawns on miss; it does not roll out to rest. This keeps the on-floor population bounded to owned balls only.

## Helper upgrade (future)

A court-role item, a dog that fetches rested balls and returns them to the rack. Reuses the existing court-role plumbing; whether it ships as a fixture or a lighter behavioural item is an implementation choice for its own ticket.
