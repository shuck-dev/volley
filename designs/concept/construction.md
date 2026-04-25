# Construction

The bright world. The pretense the protagonist is actively maintaining. This doc carries Construction's detail; high-level architecture lives in `three-registers.md`.

## What Construction is

The garden, the stall, the racquet, the rally. Saturated colour, generous light, surfaces that gleam, shadows held warm. Characters drawn young and full and helping. Volleyball lives here and only here. The structure is a tournament: the protagonist is climbing the volley world ladder toward the championship.

Construction is a coping shape. Spiritfarer is the closest playable precedent: "We've only created a playground and framework for you to deal with your own emotions" (Nicolas Guérin, Thunder Lotus). The bright world is honest about being a defence. The warmth in it was always real; the pretense is the rendering, not the warmth itself.

The artist's hardest job lives here. Construction must be straight-up enjoyable as an idle pong game for the player who never thinks about the narrative. The cracks come later (`cracks-and-break.md`); if they arrive before the player has good reason to want the rally to keep going, they have nothing to crack.

## The cast

The cast splits into two groups. The supporting cast are real people from the protagonist's life, rendered in the bright world. The player will see two asset sets for each: a Construction-side rendering (young, vibrant, helping) and a Reality-side rendering (their actual age, plainer, in their actual life). The opposing cast is just one person: the champ, the dead friend, who sits at the top of the tournament ladder.

### Supporting cast

- **The protagonist.** Drawn like any other character; the player needs to see them to connect to them. Construction-render and Reality-render, same shape as everyone else. The Construction-render is what the player connects to throughout the bright world; the Reality-render is the protagonist as they actually are. The two stay distinct; the protagonist's image does not transform across the arc. The player gets the contrast by switching registers.
- **The shopkeeper / friend at the stall.** The warmth at the centre of the venue, pre-break. In reality, this is someone the protagonist has pushed away. Same person, two renders. The shopkeeper leaves the construction at the break (`cracks-and-break.md`) and returns at the call as the final partner on the right side of the court (`postgame.md`). (See "Why the shopkeeper is at the stall" below.)
- **Martha and the partners.** Real people the protagonist knew, summoned into the bright world as the protagonist's coaches and training partners. Each has a real-world counterpart the player can meet during Reconstruction. (See "The coaches" below.)
- **The tinkerer.** Real person, the shopkeeper's younger sister. Holds the photo book in Reality (`reconstruction.md`).

### Opposing cast

- **The champ.** The dead friend. The championship final. Someone the protagonist looks up to, never a rival; the player the protagonist always admired. No real-world counterpart in person; their reality is the cliff (`reconstruction.md`).

## Why the shopkeeper is at the stall

The shopkeeper was there when the friend died. The protagonist was not.

That asymmetry is the wedge. The friend did something reckless, alone except for the shopkeeper, who witnessed it and could not save them. The shopkeeper carries the memory; the protagonist carries the absence. Their grief is not shared in the same direction. Talking to the shopkeeper would mean hearing what happened, and naming where the protagonist was instead. The protagonist pushes them away because the shopkeeper IS the failure of presence, made daily and visible. Not as judgment, the shopkeeper did not cause it; as mirror.

The shopkeeper's tries to help after the death were partly their own grief reaching for connection. They got pushed away because the protagonist could not bear what their presence pointed at.

The protagonist's mind cannot let them go either. The shopkeeper is the only one who knows; the only one who could understand. The construction's compromise is precise: keep the shopkeeper present, warm, available; have the relationship that does not require admitting where the protagonist was when the friend died. The friend at the stall, attentive without intruding, is the relationship the protagonist wants AND the relationship they cannot have in reality, rendered as the version they can hold.

This is why the world record IS the shopkeeper's phone number. Every rally is the protagonist's unconscious reach. The count climbing is the protagonist almost-dialling without admitting they want to. The bright world's whole engine is the substitute relationship being maintained against the day the real one becomes possible.

It is why the championship sits structurally as the final wall. Reaching the champ means reaching the dead friend, which means facing what happened, which means facing the shopkeeper, which means facing where the protagonist was instead.

It is why the call is the ending (`postgame.md`). Once the protagonist has faced the cliff (the place they should have been) and reconciled the absence, there is nothing left between them and the shopkeeper. The shared knowledge has been waiting all along.

## The tournament

The bright world is shaped as a volley tournament. The protagonist is climbing the ladder; the championship is the world record; the world record is the shopkeeper's phone number. Reaching it means making the call.

The structure: each main venue hosts one round of the tournament. The player rallies in that venue with their coach (a partner) until they qualify; then they enter the round, where the coach takes the other side and the player faces them in the round's match. Win the round, advance.

Round matches happen in a shared themed battle space, off the main rally flow. The player attempts each round when ready. Win unlocks: the next venue, the next coach, the next mechanic, the next round.

The championship is the final round, against the champ.

### The coaches

Each partner is a coach who trains the protagonist in a specific mechanic. The training happens through the rally: the partner is on the right side of the court, and as you rally with them, the mechanic they hold becomes available to you. By qualifying for their round, you have learned what they teach.

Then they take the other side for the round match. The encounter is the test of what they taught you. Master-and-pupil shape. Their mechanic, plus everything you learned from earlier coaches, is in your kit; the round is where you prove you can use it under pressure.

Each milestone should feel interesting and different from the others. Mechanics compose: by the championship the player has a stack of techniques, each tied to a person who taught them. The kit accumulates with the cast.

Concrete shape of the mechanics is downstream design (one mechanic per coach, each distinct, all working together). What this doc commits is the shape: coach trains the protagonist via the rally, then becomes the opponent in the round, with the mechanic they taught at the centre of that match.

### The champ as the championship

The champ is the final coach the protagonist had: the friend they used to play with, who was the best at the game and pushed the protagonist to be better. In the construction, the champ holds the championship spot, a person the protagonist looks up to, never a rival.

Pre-break, the protagonist climbs the rounds, learning each coach's mechanic, and eventually qualifies for the championship. The championship match is unwinnable. The wall is exactly there. The break (`cracks-and-break.md`) is what happens when the player has been at the championship long enough that the construction can no longer hold them against the impossibility.

Late in Reconstruction, after the cliff visit, the champ shifts. They become recruitable as a partner; the player can put them on the court like any other. The rallies are different with them; they were always the player they admired. The path to the call opens once the champ is a partner the player can rally with, not a championship match they cannot win.

After the call, the champ is gone (`postgame.md`).

## The rally and the count

The rally is the engine of Construction. Pong-shape court (described in the artist world bible's court section), protagonist on the left with a racquet, coach on the right. The count climbs as long as the rally holds. Items and effects layer on top.

Pre-break, the count is visible. The current round's qualifying count gates the next round; the championship's qualifying count is the world record. The champ holds the championship; the player can qualify for the championship match but cannot win it.

Post-break (Reconstruction), the count is hidden in Construction. The number can still be checked, but only by visiting somewhere in Reality. See `reconstruction.md` for the mechanics.

## Prototype scope

Per SH-275 (define prototype venue scope), the prototype delivers one venue: the garden. That maps to one round of the tournament: Martha as the coach, one mechanic she teaches, one round match in the shared themed battle space. The championship and the rest of the rounds unfold across alpha and beta.

The prototype's job is to land the championship-shape: the protagonist meets a coach, learns from them, qualifies for a round, plays the round match, wins, and gets the felt sense that this is the path. The other rounds are content fills against a structure the prototype proves out.

## Open questions

- **Mechanic shape.** What specifically does each coach teach? Concrete pong mechanics like top-spin, lob, smash, drop-shot, defensive dig — or something different? The space is open; what matters is each is interesting, different, and composable.
- **Round match format.** Pong with items and effects active, 1v1, no partner on court. What's the win condition? First-to-N points? Reach a count threshold against the coach's pressure? Survive a number of returns? Affects the felt difference between rally-mode and match-mode.
- **Tournament round count for the full game.** SH-275 will name venues. One round per venue means tournament length tracks venue count.
- **Drop-out behaviour.** If the player loses a round, what happens? Re-attempt? Train more? Affects pacing.

## Production notes

- The cast doubles in scope. Protagonist + shopkeeper + tinkerer + 4-6 partners (each in two renders, plus their teaching mechanic), plus the champ (one render, plus their championship match). Worth bounding the partner count early.
- Construction's content scales (procedural rally, item economy, partner system, tournament rounds). This is the part of Volley that has long-tail content runway.
- Round matches reuse one battle court re-themed per venue; production-tight versus building unique battle venues.
- The count's pre-break / post-break behaviour is one of Construction's load-bearing mechanics. The hidden-count move post-break is described in `reconstruction.md`.
