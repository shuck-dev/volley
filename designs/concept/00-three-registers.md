# The Three Registers

The high-level structure of Volley as a game. This doc carries the architecture; per-arc docs in this folder carry the detail.

This is a working set of docs. Refinement passes follow.

## Map

- This doc: the game's overall shape and the synthesis index.
- `01-construction.md`: the bright world, the cast, the shopkeeper psychology, the tournament structure, the champ, the rally and the count.
- `02-cracks-and-break.md`: the wall thinning and the wall coming down.
- `03-reconstruction.md`: the long arc after the break, the bidirectional carry, the reconciliation mechanic.
- `04-reality.md`: the second register; the hometown, the cast in Reality, the photo book, the cliff.
- `05-postgame.md`: the call, the seashell, what the bright world becomes after.

The earlier narrative pass at `designs/02-alpha/01-world-and-narrative.md` is raw material for these docs. Pieces that work are kept; pieces that do not are reframed or dropped. The picked-up section below names the deltas.

## What the game is

The protagonist holds a racquet. Their stated goal is to beat the world volley record. Friends help them along the way. The count climbs, the rally tiers climb with it, the friends keep showing up. The hook arrives in the friend's voice in the first session, not on a HUD; the count gives a number, the friend gives the number meaning.

What the player does not know yet: the world record is a phone number. The shopkeeper's. Every volley counts toward dialling someone the protagonist could reach but won't. The construction is a coping shape; reaching the record means making the call.

The bright world is a construction the protagonist is actively maintaining. It takes energy to keep. The warmth in it is real; the pretense is the rendering. The game is the arc of that pretense thinning, the wall coming down, and the protagonist learning to live without it.

## The three registers

**Construction.** The bright world. Saturated, full, helping. Volleyball lives here; the count is the engine; the world record is the goal. The protagonist's pretense actively maintained against a loss they have not yet been able to face. Detail in `01-construction.md`.

**Reality.** A complete second register. Visually distinct from Construction: gold-hour, weighted, plainer, characters at their actual ages. Story-driven; layered scenes the player walks into. One place, the protagonist's hometown, geographically static with content added across the arc. Detail in `04-reality.md`.

**Reconstruction.** The arc. The long phase after the break in which the wall stays down and the player can travel between Construction and Reality at will. Not a third visual register; a meta-state of free travel and bidirectional carry. Reconciliation lives inside Reconstruction as the actions the player takes. Detail in `03-reconstruction.md`.

## The five movements at a glance

1. **Construction.** The pretense actively maintained. The rally climbs toward the record. The count is visible; the goal is named in dialogue. (Detail: `01-construction.md`.)
2. **Cracks.** Reality leaks into the construction in small atmospheric ways. Each crack is dismissible; the cumulative pressure matters. (Detail: `02-cracks-and-break.md`.)
3. **The break.** The wall comes down once. Cumulative cracks plus a singular rupture. The player is pulled into Reality involuntarily for the first time. (Detail: `02-cracks-and-break.md`.)
4. **Reconstruction.** The long arc. Free travel between registers; bidirectional carry; reconciliation actions accumulate; the cliff visit closes the arc. (Detail: `03-reconstruction.md`.)
5. **The call.** Reaching the world record means dialling the shopkeeper. Peace is the call made. (Detail: `05-postgame.md`.)

After the call: postgame, with the champ gone and a seashell in their place.

## Cross-register principles

These principles bind the registers together; the per-arc docs should not contradict them.

- **Everyone is real.** The supporting cast in Construction is the real cast from the protagonist's life, rendered young / vibrant / helping. The same people exist in Reality at their actual ages. Two asset sets per character that appears in both. Exception: the champ (Construction-only; their reality is the cliff).
- **The hook is in dialogue, not HUD.** The world record is named by a character (probably the friend at the stall) in the first session. The number is on a HUD; the meaning is not.
- **Cracks are tonal, not concrete.** A real-world object literally appearing in Construction reads as a flag the player can point at. A colour shift or a beat in a partner's posture is harder to name and easier to absorb. Concrete leakage breaks the deniability the cumulative shape needs.
- **Reconstruction is not a third visual register.** The two registers stay distinct. Reconstruction's signal is the carry, plus a gradual weathering of Construction's saturation, plus play-level differentiators (score hidden in Construction, champ dialogue softens, audio shifts).
- **Reality is finite hand-crafted content.** One place, built once, with iterative additions across Reconstruction. Reality cannot be procedural; the team builds each scene.

## What this teaches each surface

- **Artist world bible**: two asset sets per character that appears in both registers (champ is the exception). Reconstruction's visual signal is the carry plus weathering, not a third render. Cracks are tonal and atmospheric; do not draw concrete reality-leaks.
- **MC profile**: the protagonist's reconciliation arc is the spine of their interior life. The call-of-the-void layer the profile already names becomes legible as the resistance to crossing into Reality. The cliff is where that resistance is met head-on.
- **Tech-context**: the rally tooling holds Construction. Reality's tooling is its own thing: layered scene-state, contextual interactions, dialogue, descriptive prose, the present-and-attentive puzzle shape, the bidirectional carry. SH-279 is the right place to spike this.
- **Audio (SH-281)**: a register per phase. Construction is synthetic / bright / energetic; Break is abstract synth, harsh, minimalist; Reality is acoustic with bustle and wind; Reconstruction is synth and acoustic in conversation, escalating to full orchestra by the end.

## What this teaches the production

- Construction's content scales (procedural rally, item economy, partner system).
- Reality's content does not. The hometown is built once with iterative additions across Reconstruction. The cliff is a separate location built once. Finite hand-crafted content.
- Reconstruction's length is a budget knob: more reconciliation actions means longer arc but more content to build.
- Idle pacing means the cracks need to escalate slowly enough that month-long players see them as cumulative rather than clustered around early sessions.
- The cast doubles in Reconstruction (each supporting-cast character with a Reality-side asset). Worth bounding the partner count early.

## What we are picking up from the prior narrative pass

Strong keeps from `designs/02-alpha/01-world-and-narrative.md`:

- The world record is the shopkeeper's phone number. The hook resolves into the call.
- Peace is the call made.
- The shopkeeper is the friend who got pushed away. Same person as the friend at the stall. Two renders.
- The champ is the dead friend. Construction only. Returns as a partner once the cliff is faced.
- The hometown is the reality place. Coastal, British-seaside-meets-southern-Spain.

Reframings:

- The shopkeeper's role in the death has shifted from "tried to help after" to "involved but not responsible." Something else caused it; the shopkeeper was present, entangled, a daily reminder of the failure. This sharpens why the protagonist blocks them out and why the call is hard.
- The post-break mechanic in the prior doc was badge activation (slotting narrative items into milestone badges). The new architecture replaces this with the bidirectional carry. Badge activation may persist as one expression of the carry inside Construction, or be dropped entirely. SH-279 will decide.
- The narrative doc framed the post-break phase as a single arc through denial-to-acceptance. The new architecture splits it into Reconstruction (the arc) and Reconciliation (the actions inside it).

## Open questions (synthesis index)

The questions live in their respective per-arc docs; this is the index.

From `01-construction.md`:
- Gym-leader / encounter shape. The "leaders as metaphors" framing reads as too on-the-nose (close to Omori). Currently being reworked: a venue-tied encounter involving the partner, off the main flow, in a shared themed battle space.
- Partner unlock cadence inside the gym-leader-vs-partner shape.

From `02-cracks-and-break.md`:
- Crack pacing. Cracks tied to count milestones, playtime, story flags, or a combination?
- Cracks as deniable in an idle context. Burst-player vs all-night-grinder pacing.

From `03-reconstruction.md`:
- Reconciliation action count. 4–6 or 5–7?
- Action shape. Memory faced, character encountered, small task, or varying?
- Bridge unlock signal. UI affordance, character moment, music shift?
- Cliff trigger. What unlocks the cliff dip late in Reconstruction?
- Visual language of the carry.

From `05-postgame.md`:
- Reality cycling post-call. After the call, does the game continue, close, or open into a Regret-style alt-perspective?

## What this unblocks

- The artist world bible can name the three registers and the five movements, with content fills proceeding once the open questions on action count, crack pacing, and the encounter shape are answered.
- SH-279 (tech spike on reality gameplay) absorbs the hometown structure, the layered-scene puzzle shape, and the bidirectional carry.
- SH-281 (audio direction) drafts the music register per phase.
- Future content tickets live downstream of these per-arc docs reaching consensus.
- The MC profile can deepen with the call-of-the-void resistance mapped onto the cliff's chosen-acceptance shape.
