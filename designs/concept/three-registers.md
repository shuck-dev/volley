# The Three Registers

A first-cut spike on Volley's overall structure. The doc captures what is decided, names what is open, and gives the team a stable spec the artist world bible, the MC profile, and the tech-context can point at while the open questions resolve.

This is a working doc. Refinement passes follow.

## What the game is

The protagonist holds a racquet. Their stated goal in the bright world is to beat the world volley record. Friends are there to help them along the way. The count climbs, the rally tiers climb with it, the friends keep showing up. The hook arrives in the friend's voice in the first session, not on a HUD; the count gives a number, the friend gives the number meaning.

The bright world is a construction the protagonist is actively maintaining. It takes energy to keep. It is real where it is warm; it is pretense where it papers over a loss the protagonist is not yet willing to face. The game is the arc of that pretense thinning, breaking, and the protagonist learning to live without needing it as a wall.

The game has three registers: Construction, Reality, and Reconstruction.

## Construction

The bright world. The garden, the stall, the racquet, the rally. Saturated colour, generous light, surfaces that gleam, shadows held warm. Characters drawn young and full and helping. The volley record is the goal; the count is the engine. Volleyball lives here and only here.

Construction is a coping shape. Spiritfarer is the closest playable precedent: "We've only created a playground and framework for you to deal with your own emotions" (Nicolas Guérin, Thunder Lotus). The bright world is honest about being a defence. The warmth in it was always real; the pretense is the rendering, not the warmth itself.

The artist's hardest job lives here. Construction must be straight-up enjoyable as an idle pong game for the player who never thinks about the narrative. The cracks come later; if they arrive before the player has good reason to want the rally to keep going, they have nothing to crack.

## Cracks

Reality leaks into the construction in small atmospheric ways. A flicker in the venue light, a partner's tilt held a beat too long, a colour cooling at the edge of the frame. Each leak is dismissible on its own. Their cumulative pressure is what matters.

The cracks earn dismissibility from prior generosity (Pattern 1 in `designs/research/game-structure-references.md`). The construction has to land as genuinely fun before a single crack works. Spec Ops's first heat shimmer arrives roughly three hours in, after the player has settled into a competent-soldier rhythm; Doki Doki's first poem night arrives after hours of dating-sim warmth; Inscryption's first scrybe-room break arrives once the player has earned the deck. Volley's idle pacing scales these numbers up, but the principle holds.

Cracks should be tonal, not concrete. A real-world object literally appearing on the rack reads as a flag the player can point at; a colour shift or a beat in a partner's posture is harder to name and easier to absorb. Concrete leakage breaks the deniability the cumulative shape needs.

## The break

The break is the wall coming down. Spec Ops is the structural exemplar: cumulative cracks across seven chapters, then chapter eight is the singular moment that makes the prior cracks legible as a chord rather than as noise. Volley's break is both. The cracks pile up, dismissible. Then one moment is the rupture, and from there reality is in the player's life whether they wanted it or not.

The break's mechanical signature: the player is pulled into reality involuntarily for the first time. The dip is forced. They cannot return to construction at will; the structure controls the moment they come back.

## The reconciliation arc

Between the break and reconstruction the player makes a series of gated dips into reality. Each dip is voluntary in the local sense (the player chooses to enter), narratively triggered in the structural sense (the dip is available because the arc has reached a moment that asks for it).

The dip shape: enter reality with a need, do something there (face a memory, encounter a character, witness a moment, perform a small task), bring something back into construction, advance. Each dip compounds; the wall thins as the dips accumulate; eventually the cumulative reconciliation reaches a threshold and the wall is gone.

Reality during the reconciliation arc is finite hand-crafted content. It is not a procedural loop; it cannot be. Each dip is a scene the team builds. This is a real production budget that bounds the doc's other ambitions.

Reality's tone in these dips: gold-hour, weighted, story-driven. Characters at their real ages, less vibrant, less full. Spiritfarer, Lake, Omori's Faraway Town are the tonal touchstones. Loss is acknowledged; the prose breathes; the rally is not the engine here. The pull of reality is its honesty; the player ends up wanting it.

Reality's mechanic in these dips: layered situations the player walks into, with several things going on at once and a handful of contextual interactions available. The puzzle is being present in the room and doing the right small thing. Not inventory recombination, not pixel-hunting; closer to navigating a busy scene where a small attentive act has the right effect.

## Reconstruction

The cumulative reconciliation reaches a threshold. The wall is gone. The player can travel freely between Construction and Reality.

Reconstruction is not a third visual register. The two registers stay distinct: Construction is still vibrant, Reality is still gold-hour. Reconstruction is the meta-state in which the player has access to both and can carry across.

The carry is bidirectional and mechanical:

- **Constructs into reality.** Any item, character, memory, or insight from Construction can be brought into Reality and used as a tool to solve the layered situations there. Anything and everything counts; the design is open here.
- **Reality into construction.** Real-world acknowledgements feed back into the rally: new venues unlock, partners gain new lines, the bright world acknowledges what it had been hiding from. Hints for reality's puzzles can also surface in construction.

The visual signal of being in reconstruction is the act of crossing, plus the persistent presence of one register's elements when the player is in the other. The bridge itself is the new affordance.

The Nausicaä framing the bible has named applies here, gently: as the player carries reality's weight back into construction, the bright world's saturation can drop a notch, line weight thicken, compositions hold longer pauses. The construction doesn't visually rebuild; it ages with the player.

## What this teaches each surface

- **Artist world bible**: the protagonist holds the racquet in Construction with bright-world weight, in Reality with real-world weight (older, plainer). Two asset sets per character that appears in both. Reconstruction's visual signal is the carry, not a third render. Cracks are tonal and atmospheric; do not draw concrete reality-leaks.
- **MC profile**: the protagonist's reconciliation arc is the spine of their interior life. The call-of-the-void layer the profile already names becomes legible as the resistance to crossing into Reality.
- **Tech-context**: the rally tooling holds Construction. Reality's tooling is its own thing: layered scene-state, contextual interactions, dialogue, descriptive prose, the present-and-attentive puzzle shape. SH-279 is the right place to spike this.

## What this teaches the production

- Construction's content scales (procedural rally, item economy, partner system).
- Reality's content does not. Each dip is hand-crafted; the team builds them in sequence.
- The reconciliation arc's length is a budget knob: more dips means longer arc but more content to build. Fewer dips means tighter arc but less time for the player to feel the pull.
- The break can be foreshadowed via cracks for an arbitrary playtime before triggering; idle pacing means the cracks should escalate slowly enough that month-long players see them as cumulative rather than cluster around early sessions.

## Open questions

The structure above is settled in conversation. The questions below are not, and the spike's next pass should answer them.

1. **Dip count.** How many dips between the break and reconstruction? Idle pacing argues 4–6; narrative arc argues 5–7. The answer affects content scope and pacing.
2. **Dip kind.** Each dip's GET shape: a memory faced, a character encountered, a small physical task, or all three varying per dip? Affects SH-279 tooling.
3. **Crack pacing.** Cracks tied to count milestones, playtime, story flags, or a combination? Idle players play in spurts over months; cracks that gate on count alone reward grinders.
4. **Bridge unlock signal.** When reconstruction unlocks, what does the player see/feel? A UI affordance? A character moment? A shift in the music? Worth designing rather than leaving implicit.
5. **The hook's specific dialogue.** Whose voice in the first session names the world record as the want, and what do they say? The friend at the stall is the strongest candidate; the line's specific shape is downstream story work.
6. **Multiple breaks vs single break.** The structure above implies one break (involuntary first dip) followed by gated voluntary dips. NieR's route-A/B/C shape is an alternative where breaks recur. Confirm single break or define how multiple breaks would feel different from gated dips.
7. **Reality cycling post-reconstruction.** Does the player ever lose access to Reality, or is reconstruction the terminal state for that capability? Default: terminal. Confirm.
8. **The story tying volleyball to the loss.** The hook (beat the world volley record) is generic sport-game language; for a construction-as-coping defence, the goal needs to rhyme with the loss. This is a story concern, not a structural one, and lives downstream. Capturing as an open question so it does not vanish.

## What this unblocks

- The artist world bible's content fills can proceed once dip count and crack pacing are answered. Without those, the bible can describe Construction and the cracks pattern, but not the rhythm of dips.
- SH-279 (tech spike on reality gameplay) absorbs the layered-scene interaction model and the bidirectional carry. Most of its work follows from the open questions answered here.
- Future content tickets (specific dip scenes, specific cracks, specific puzzles) live downstream of this doc reaching consensus.
