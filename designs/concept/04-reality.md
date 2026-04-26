# Reality

The second style. Reality on its own terms: how it looks, how it sounds, the shape of a Reality scene. High-level architecture in `00-two-styles.md`. The break that introduces Reality lives in `02-cracks-and-break.md`. The Part 2 work that happens inside Reality (photo album, sister, search) lives in `03-reconstruction.md`. The cliff and the call live in `05-postgame.md`.

## The place

Reality is one place: the protagonist's hometown. A small coastal town on the Welsh and Cornish coast in an imagined warmer climate. Painted terraces in seaside colours, the palette of Tenby and Aberaeron: pinks, yellows, sea-greens, sky-blues. Whitewashed walls. Palm trees in places. A high street that smells of rain and citrus. Mediterranean light on a British coastline. Faded grandeur with sun on it. Ordinary, lived-in. Pulls from real reference points; sits on no map.

The map is geographically static. The hometown does not grow; the town stays the size it was when the player first walked through it at the break. What changes is what is in it. Across Part 2, things are added: people who become reachable, objects that were not there before, conversations that open as the protagonist is ready for them. The same hometown, revealed in passes.

## Visual register

Gold-hour. Weighted. Plainer than Construction. The light is slant afternoon rather than full midday; the shadows lengthen; the air carries dust. Saturation drops a notch from Construction; line weight thickens; compositions hold longer pauses.

Characters are at their actual ages. Less vibrant, less full, deliberately unconstructed. The Six Marks still apply (per the artist world bible's section B); their expression here is plainer warmth, specific detail without gleam, breathing posture without performance.

The pull of Reality is its honesty. The player ends up wanting it.

Touchstones: [Spiritfarer](https://store.steampowered.com/app/972660/Spiritfarer_Farewell_Edition/)'s quieter moments, [Lake](https://store.steampowered.com/app/1812120/Lake/), [Omori](https://en.wikipedia.org/wiki/Omori_(video_game))'s Faraway Town. Loss is acknowledged; the prose breathes; the rally is not the engine here.

## Audio register

Reality is acoustic. Bustle, wind instruments, rooms with people in them. Where Construction is bright synthetic music with a melodic chip-tone heritage, Reality is the air outside that synth.

Across Part 2, the two styles converse in the soundtrack: synth and acoustic in tension, the weight moving toward fuller arrangement by late Part 2. At the cliff, the music thins. At the credits, full orchestra reaches for both wonder and weight. Synthesis. Full direction in SH-281.

## The shape of a scene

Reality is interaction-driven, not rally-driven. The player walks into a scene, does small attentive things, leaves. Each scene is hand-crafted: layered state, contextual interactions, dialogue, descriptive prose, the present-and-attentive puzzle shape.

The structure-level commit: not pong; not inventory recombination; being present in a room and finding what wants to happen. Specific puzzle mechanics (interaction surfaces, scene state, dialogue layering) are downstream game-design work and live in SH-279.

Scenes are gated by photos. Each found photo opens a Reality scene; finding the photo and the corresponding scene compounds the trail. The mechanic itself is in `03-reconstruction.md`; what matters here is the shape: scenes are hand-built, return-supporting, layered with state across visits.

## The cast in Reality

Reality holds the real-world version of every cross-style character. Each is at their actual age, in their actual life, plainer than their Construction-render. The player meets them across Part 2.

**The sister.** The tinkerer's real-world counterpart. The shopkeeper's younger sister. Less weighted by the death than the shopkeeper. Holds the photo album. The bridge. One of the first reachable people in Reality. Detail in `03-reconstruction.md`.

**Martha and the partners.** The cashier at the actual newsagent; the others as they actually are. Not coaches here, just people the protagonist knew.

**The shopkeeper.** Present in Reality from the break onward. Not approachable directly until the cliff. The unnamed number that never connects is the player-facing weight of their absence; detail in `03-reconstruction.md`. The cliff meeting and the call are in `05-postgame.md`.

**The protagonist.** Reality-render of the MC. Older, gentler, less athletic than their Construction-render. Same character, real version.

The champ is Construction-only. No Reality counterpart. Their reality is the cliff (`05-postgame.md`): the place the friend group used to jump from, the place the friend died, the place the shopkeeper went back to.

## Period

Late 90s or early 2000s as a tonal range. Pre-smartphone. Phones flip or candy-bar or land-line. Numbers held in heads or written on paper, not auto-named in pocket databases. Period-appropriate clothes, signage, phone hardware, photo prints. The unnamed-number mechanic depends on the period.

## Production notes

- Reality is finite hand-crafted content. The hometown is built once with iterative additions across Part 2.
- The sister is the most-visited Reality character (she holds the photo album). Her scene supports many returns.
- The cliff is a separate location built once. The same cliff the friend group used as a jumping spot, the same edge the friend went off, the bench at the top dedicated to them. Used at the chosen-acceptance moment and re-enterable through the unlocked gate after the call (`05-postgame.md`).
- Specific Reality tooling (interaction surfaces, scene state, dialogue, navigation) belongs to SH-279.
