# The Three Registers

A working spike on Volley's overall structure. The doc captures what is decided, names what is open, and gives the team a stable spec the artist world bible, the MC profile, and the tech-context can point at while the open questions resolve.

This is a working doc. Refinement passes follow.

The doc draws on an earlier narrative pass (`designs/02-alpha/01-world-and-narrative.md`) as raw material. Pieces that work are kept, pieces that do not are reframed or dropped, and the pickups are flagged as such.

## What the game is

The protagonist holds a racquet. Their stated goal is to beat the world volley record. Friends help them along the way. The count climbs, the rally tiers climb with it, the friends keep showing up. The hook arrives in the friend's voice in the first session, not on a HUD; the count gives a number, the friend gives the number meaning.

What the player does not know yet: the world record is a phone number. The shopkeeper's. Every volley counts toward dialling someone the protagonist could reach but won't. The construction is a coping shape; reaching the record means making the call.

The bright world is a construction the protagonist is actively maintaining. It takes energy to keep. The warmth in it is real; the pretense is the rendering. The game is the arc of that pretense thinning, the wall coming down, and the protagonist learning to live without it.

The arc has five movements: Construction, Cracks, Break, Reconstruction (the long arc), and the cliff that closes Reconstruction. Reconciliation lives inside Reconstruction as the actions the player takes. By the end, the protagonist has reconciled the event and reconstructed their view of the world, and reaches the record by making the call.

## Construction

The bright world. The garden, the stall, the racquet, the rally. Saturated colour, generous light, surfaces that gleam, shadows held warm. Characters drawn young and full and helping. The volley record is the goal; the count is the engine. Volleyball lives here and only here.

Construction is a coping shape. Spiritfarer is the closest playable precedent: "We've only created a playground and framework for you to deal with your own emotions" (Nicolas Guérin, Thunder Lotus). The bright world is honest about being a defence. The warmth in it was always real; the pretense is the rendering, not the warmth itself.

The artist's hardest job lives here. Construction must be straight-up enjoyable as an idle pong game for the player who never thinks about the narrative. The cracks come later; if they arrive before the player has good reason to want the rally to keep going, they have nothing to crack.

### The cast in Construction

Everyone in Construction is a real person rendered in the bright world's register. The player will see two asset sets for each: a Construction-side rendering (young, vibrant, helping) and a Reality-side rendering (their actual age, plainer, in their actual life). The exception is the rival.

- **The protagonist.** Young, full of motion, focused on the rally. The reality version comes later.
- **The shopkeeper / friend at the stall.** The warmth at the centre of the venue. In reality, this is someone the protagonist has pushed away. Same person, two renders.
- **Martha and the partners.** Real people the protagonist knew, summoned into the bright world to fill the right side of the court. Each has a real-world counterpart the player can meet during Reconstruction.
- **The tinkerer.** Real person, the shopkeeper's younger sister.
- **The rival.** The exception. The dead friend. No real-world counterpart in person; their reality is the cliff (see Reconstruction).

### The rival

The rival is the dead friend rendered as a partner. The construction had to do something with someone it could not leave out and could not face on equal terms; what it did was put them in the partner slot with the wrong relationship. They are the only construct without a real-world embodiment, because the dead friend cannot appear in Reality except as place and absence (see the cliff).

The rival is a character, not a score. They take the right side of the court the way other partners do, but where Martha is uncomplicated warmth, the rival is the protagonist's memory of someone who pushed them. Their barks are sharper. Their returns are harder. The player rallies higher with the rival on the court than with anyone else, and the count climbs faster, but the texture is competitive rather than companionable. The narrative doc's read holds: the rival's aggression is not really aggression; it is the friend's old habit of not letting the protagonist coast.

Pre-break, the rival is the partner who sets the record-1 ceiling. The protagonist plays best with them; the count peaks under their pressure; the wall is exactly there. The player feels the rival as the obstacle through the play itself, not through a leaderboard.

Late in Reconstruction, after the cliff visit, the relationship shifts. The rival becomes a regular partner. The pushiness softens; the rallies still go high, but the protagonist is no longer being pushed; they are playing with someone they once played with. The path to the record opens.

After the call, the rival is gone (see Postgame).

## Cracks

Reality leaks into the construction in small atmospheric ways. A flicker in the venue light, a partner's tilt held a beat too long, a colour cooling at the edge of the frame. Each leak is dismissible on its own. Their cumulative pressure is what matters.

The cracks earn dismissibility from prior generosity (Pattern 1 in `designs/research/game-structure-references.md`). The construction has to land as genuinely fun before a single crack works. Spec Ops's first heat shimmer arrives roughly three hours in, after the player has settled into a competent-soldier rhythm; Doki Doki's first poem night arrives after hours of dating-sim warmth; Inscryption's first scrybe-room break arrives once the player has earned the deck. Volley's idle pacing scales these numbers up, but the principle holds.

Cracks should be tonal, not concrete. A real-world object literally appearing on the rack reads as a flag the player can point at; a colour shift or a beat in a partner's posture is harder to name and easier to absorb. Concrete leakage breaks the deniability the cumulative shape needs.

## The break

The break is the wall coming down. Spec Ops is the structural exemplar: cumulative cracks across seven chapters, then chapter eight is the singular moment that makes the prior cracks legible as a chord rather than as noise. Volley's break is both. The cracks pile up, dismissible. Then one moment is the rupture, and from there reality is in the player's life whether they wanted it or not.

The break's mechanical signature: the player is pulled into Reality involuntarily for the first time. The dip is forced. They walk through the protagonist's hometown. They see the people behind the partners. The shopkeeper is at their actual age. Martha is the cashier at the actual newsagent. The cliff is somewhere in this geography but not yet visited.

The break ends and the player is back in Construction, but the wall does not go up again. Reconstruction begins.

## Reconstruction

The arc. The long phase between the break and the cliff. The wall stays down; the player can travel between Construction and Reality at will. The protagonist is reconstructing their view of the world.

Reconstruction is not a third visual register. The two registers stay distinct: Construction is still vibrant, Reality is still gold-hour. Reconstruction is the meta-state in which the player has access to both and can carry across.

The carry is bidirectional and mechanical:

- **Constructs into reality.** Any item, character, memory, or insight from Construction can be brought into Reality and used as a tool. The construction is what the protagonist built to keep going; in Reconstruction, the things they built turn out to be useful in the world they were avoiding.
- **Reality into construction.** Real-world acknowledgements feed back into the rally. New venues unlock; partners gain new lines; the bright world acknowledges what it had been hiding from. Hints for Reality's puzzles surface in Construction.

The visual signal of Reconstruction is the act of crossing, plus the persistent presence of one register's elements when the player is in the other. The bridge itself is the new affordance.

As the carry accumulates, the bright world ages with the player. Saturation drops a notch; line weight thickens; compositions hold longer pauses. The construction does not visually rebuild; it weathers.

### Reconciliation

Reconciliation is what the player DOES inside Reconstruction. The actions: dips into Reality, carries back, attentions paid, small reckonings worked through. Each reconciliation action compounds. The cumulative effect is the protagonist getting closer to the cliff, closer to the rival becoming a partner, closer to the call.

By the end of Reconstruction, the protagonist has reconciled the event and reconstructed their view. The two land together.

### Reality, the place

Reality is one place: the protagonist's hometown. A small coastal town, British-seaside-meets-southern-Spain. Terraced houses next to whitewashed walls; a high street that smells of both rain and citrus; light shifting between northern grey and Mediterranean glare. Ordinary, lived-in.

The place is geographically static. The map does not grow; the town stays the size it was when the player first walked through it at the break. What changes is what is in it. Across Reconstruction, things are added: people the player can meet, objects that were not there before, conversations that open as the protagonist is ready for them. The same hometown, revealed in passes.

Reality's tone is gold-hour, weighted, story-driven. Characters at their real ages. Less vibrant, less full, deliberately unconstructed. Spiritfarer, Lake, Omori's Faraway Town are the tonal touchstones. Loss is acknowledged; the prose breathes; the rally is not the engine here. The pull of Reality is its honesty; the player ends up wanting it.

Reality's puzzle shape is layered. The player walks into a scene with several things going on at once and a handful of contextual interactions available. The puzzle is being present in the room and doing the right small thing. Not inventory recombination; not pixel-hunting; closer to navigating a busy scene where a small attentive act has the right effect.

### The cliff

Late in Reconstruction, the protagonist visits the cliff where the friend died. The dip does not take them to the familiar hometown; it takes them somewhere they have been avoiding all along.

The cliff is the structural opposite of the break. The break is forced acceptance of Reality (the wall comes down on you). The cliff is chosen acceptance of the loss (you walk to it). The two are bookends.

After the cliff visit, the rival's pushiness softens. They become a partner in the ordinary sense; the rallies still go high but the protagonist is no longer being pushed. The gap to the record closes through reconciliation actions in the construction's final stretch. The path to the call opens.

## The call

Reaching the world record means making the call. The shopkeeper picks up. They are still there.

The call is the ending. The warmth in Construction is now available without the pretense; the protagonist can be in their hometown, with the people who are actually there, and the rally is something they did and may still do, but it is no longer a wall.

## Postgame

The player can return after the call. When they do, the rival is gone. They were always grief-shaped; once the loss has been faced and the call has been made, there is nothing for them to be in the construction anymore. The right side of the court they used to take is empty.

The rival has left an item behind. The item changes the game. The shape of that change is downstream design; what the structure asks for is one specific object the player picks up on first return that opens a postgame mode the bright world did not have. Possible reads (not commitments): a racquet handle the protagonist now plays with, that rallies the way the rival rallied; an unlock for a different perspective the player can run from; a memento that turns the world record from a number into a memory, with a new ladder underneath.

The narrative doc names "Regret" as a future-update perspective for someone who never made the call. The postgame item is the structural slot that perspective could live inside.

## What this teaches each surface

- **Artist world bible**: the protagonist holds the racquet in Construction with bright-world weight, in Reality with real-world weight (older, plainer). Two asset sets per character that appears in both. The rival is the exception (Construction-only, with the cliff as their reality). Reconstruction's visual signal is the carry plus the gradual weathering, not a third render. Cracks are tonal and atmospheric; do not draw concrete reality-leaks.
- **MC profile**: the protagonist's reconciliation arc is the spine of their interior life. The call-of-the-void layer the profile already names becomes legible as the resistance to crossing into Reality. The cliff is where that resistance is met head-on.
- **Tech-context**: the rally tooling holds Construction. Reality's tooling is its own thing: layered scene-state, contextual interactions, dialogue, descriptive prose, the present-and-attentive puzzle shape, the bidirectional carry. SH-279 is the right place to spike this.

## What this teaches the production

- Construction's content scales (procedural rally, item economy, partner system).
- Reality's content does not. The hometown is built once with iterative additions across Reconstruction. The cliff is a separate location built once. This is finite hand-crafted content; the team builds it in sequence.
- Reconstruction's length is a budget knob: more reconciliation actions means longer arc but more content to build. Fewer actions means tighter arc but less time for the player to feel the pull.
- The break can be foreshadowed via cracks for an arbitrary playtime before triggering; idle pacing means the cracks should escalate slowly enough that month-long players see them as cumulative rather than clustered around early sessions.

## What we are picking up from the prior narrative pass

Strong keeps from `designs/02-alpha/01-world-and-narrative.md`:

- The world record is the shopkeeper's phone number. The hook resolves into the call.
- Peace is the call made.
- The shopkeeper is the friend who got pushed away. Same person as the friend at the stall. Two renders.
- The rival is the dead friend. Construction only. Returns as final partner once the cliff is faced.
- The hometown is the reality place. Coastal, British-seaside-meets-southern-Spain.

Reframings:

- The shopkeeper's role in the death has shifted from "tried to help after" to "involved but not responsible." Something else caused it; the shopkeeper was present, entangled, a daily reminder of the failure. This sharpens why the protagonist blocks them out and why the call is hard.
- The post-break mechanic in the prior doc was badge activation (slotting narrative items into milestone badges). The new architecture replaces this with the bidirectional carry: constructs into Reality, reality into Construction. Badge activation may persist as one expression of the carry inside Construction, or be dropped entirely. SH-279 will decide.

Drops:

- The narrative doc's framing of post-break as a single arc through denial-to-acceptance is reframed as Reconstruction (the arc) plus Reconciliation (the actions inside it). The vocabulary is sharper; the shape is the same.

## Open questions

The structure above is settled in conversation. The questions below are not, and the spike's next pass should answer them.

1. **Reconciliation action count.** How many distinct reconciliation actions across Reconstruction? Idle pacing argues 4–6 major ones; narrative arc argues 5–7. The answer affects content scope and pacing.
2. **Action shape.** Each reconciliation action's GET: a memory faced, a character encountered, a small physical task in Reality, or varying per action? Affects SH-279 tooling.
3. **Crack pacing.** Cracks tied to count milestones, playtime, story flags, or a combination? Idle players play in spurts over months; cracks that gate on count alone reward grinders.
4. **Bridge unlock signal.** Reconstruction begins immediately after the break. What does the player see/feel that marks the bridge as available? A UI affordance? A character moment? A shift in the music?
5. **The cliff trigger.** What unlocks the cliff dip late in Reconstruction? Sufficient reconciliation actions completed? A specific item or memory carried? A count threshold approached? Worth being explicit.
6. **Reality cycling post-call.** After the call, does the game continue, or does it close? The narrative doc names "Regret" as a future-update alternate perspective. For the prototype-to-alpha scope, what state does the game leave the player in when the call lands?
7. **Cracks as deniable in an idle context.** Idle games are played in short sessions over months. A cumulative crack pattern has to work for both the burst-player and the all-night-grinder. The pattern's pacing across real time vs in-game time is open.
8. **Visual language of the carry.** When the player carries a construct into Reality, what does that look like on screen? An item icon that persists? A character who walks alongside? A note that surfaces in dialogue? Affects the tech-context and the artist's job.

## What this unblocks

- The artist world bible can name the three registers, the cracks, the break, Reconstruction, the cliff, and the call as the architecture, with content fills proceeding once the open questions on action count and crack pacing are answered.
- SH-279 (tech spike on reality gameplay) absorbs the hometown structure, the layered-scene puzzle shape, and the bidirectional carry. Most of its work follows from the open questions answered here.
- Future content tickets (specific reconciliation actions, specific cracks, specific Reality scenes, the cliff design, the call's beat) live downstream of this doc reaching consensus.
- The MC profile can deepen with the call-of-the-void resistance mapped onto the cliff's chosen-acceptance shape.
