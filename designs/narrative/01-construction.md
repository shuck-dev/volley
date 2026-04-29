# Construction

Part 1. The structural detail of the vibrant world: the tournament shape the climb takes, the rally that drives it, the count, and the unnamed number sitting underneath. High-level architecture in `00-two-styles.md`; the cracks and the win that breaks Construction in `02-cracks-and-break.md`.

Visual canon for Construction lives in [`../art/bible.md`](../art/bible.md) (sections 5 and 14). Cast lives in [`../art/bible.md`](../art/bible.md) § 4 plus the per-character profiles under [`../characters/`](../characters/). Story shape lives in [`../story/outline.md`](../story/outline.md).

## The tournament

The vibrant world is shaped as a volley tournament. The protagonist is climbing the ladder; the championship is the world record; the world record is the shopkeeper's phone number.

Each main venue hosts one round. The player rallies in that venue with a coach until they qualify; then they enter the round, where the coach takes the other side and the player faces them in the round's match. Win the round, advance.

Round matches happen in a shared themed battle space, off the main rally flow. The player attempts each round when ready. Win unlocks the next venue, the next coach, the next mechanic, the next round.

The championship is the final round, against the champ.

### The coaches

Each partner is a coach who trains the protagonist in a specific mechanic. The training happens through the rally. The partner is on the right side of the court, and as the player rallies with them, the mechanic they hold becomes available. By qualifying for their round, the player has learned what they teach.

Then the partner takes the other side for the round match. The encounter is the test of what they taught. Master-and-pupil shape. Their mechanic, plus everything learned from earlier coaches, is in the kit; the round is where the player proves they can use it under pressure.

Each milestone should feel interesting and different from the others. Mechanics compose: by the championship the player has a stack of techniques, each tied to a person who taught them. The kit accumulates with the cast.

Concrete mechanics are downstream design. What this doc commits is the shape: coach trains the protagonist via the rally, then becomes the opponent in the round, with the mechanic they taught at the centre of that match.

### The champ as the championship

The champ holds the championship spot. The protagonist climbs every round, learning each coach's mechanic, until they qualify for the championship. The match is winnable. The break beat (`02-cracks-and-break.md`) lives in what the win turns out to mean.

The champ's role and arc sit in [`../characters/champ.md`](../characters/champ.md).

## The rally and the count

The rally is the engine of Construction. Pong-shape court (described in the artist world bible's court section), protagonist on the left with a racquet, coach on the right. The count climbs as long as the rally holds. Items and effects layer on top.

In Construction, the count is visible. The current round's qualifying count gates the next round; the championship's qualifying count is the world record.

In Part 2 the count behaves differently; see `03-reconstruction.md`.

## The unnamed number, in Construction

The shopkeeper's number sits in the protagonist's phone the whole game, unnamed. Period-correct for a flip or candy-bar device. The player has full control of the phone throughout. Dialling never connects.

In Construction, the number is just digits in a contacts list. The protagonist scrolls past it sometimes. The player can dial it any time and hear the unanswered ring. Nothing in Construction tells the player whose number it is. The recognition is held back for Part 2 (`03-reconstruction.md`).

## Prototype scope

Per SH-275, the prototype delivers one venue: the garden. That maps to one round of the tournament: Martha as the coach, one mechanic she teaches, one round match in the shared themed battle space. The championship and the rest of the rounds unfold across alpha and beta.

The prototype's job is to land the championship-shape: meet a coach, learn from them, qualify for a round, play the round match, win, and feel that this is the path.

## Open questions

- **Mechanic shape.** What specifically does each coach teach? Concrete pong mechanics like top-spin, lob, smash, drop-shot, defensive dig: or something different? The space is open; what matters is each is interesting, different, and composable.
- **Round match format.** Pong with items and effects active, 1v1, no partner on court. What is the win condition? First-to-N points? Reach a count threshold against the coach's pressure? Survive a number of returns?
- **Tournament round count for the full game.** SH-275 will name venues. One round per venue means tournament length tracks venue count.
- **Drop-out behaviour.** If the player loses a round, what happens? Re-attempt? Train more?
- **Encounter shape per round.** The round-match staging needs sharpening; the gym-leader framing reads close to [Omori](https://en.wikipedia.org/wiki/Omori_(video_game)) and is being reworked toward something venue-specific.

## Production notes

- The cast doubles in scope. Protagonist plus shopkeeper plus sister plus four to six partners (each in two renders, plus their teaching mechanic), plus the champ in one render with their championship match. Worth bounding the partner count early.
- Construction's content scales: procedural rally, item economy, partner system, tournament rounds. This is the part of Volley with long-tail content runway.
- Round matches reuse one battle court re-themed per venue: production-tight versus building unique battle venues.
- The count's behaviour shifts between Construction and Part 2 (visible vs hidden). See `03-reconstruction.md`.
