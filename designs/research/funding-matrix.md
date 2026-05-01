# Funding matrix

The price of Volley reflects what the funding has actually built. The matrix is public for the same reason the source is open and the devlog runs in the open: the audience deserves to see the function that produces the number.

This document is the team's opening position on how funding maps to product. Nothing here is settled. The structure is the canon; the numbers are the working draft. The studio's pricing posture is the [open-development essay's](the-case-for-open-development.md) posture, scaled to one game: free in the browser, paid at the download, free if you build from source.

## How to read the bands

Each band is a possible final shape of the game. The matrix is a function: cumulative funding determines what the full game gets to be, and the price reflects what the full game actually is at that band. There is no fixed aspirational V1 sitting at the top that earlier bands are climbing toward. If funding never grows past Band 2, the game ships as the Band 2 shape and that is the full game.

Every band ships a full game. The full narrative arc is present at every band; rally, climb, climax, postgame, none of it gets cut. Every non-tech discipline is contracted or hired from Band 0 onwards: there is always a commissioned composer, always a commissioned artist. What scales with funding is *scope of game* (venues, partners, postgame), *scope of score* (piano, ensemble, orchestra), *scope of art* (compact set, full set, animated), and *team shape* (more contractors and FTEs as the bands climb). Each band's work is the real, shipped work at that band; nothing is "placeholder" waiting for a real version later. Piano at Band 0 is the score at Band 0.

Josh's own role across the bands is **tech** (engine, gameplay code, infrastructure) plus founder and director responsibilities throughout. Tech is the only discipline he handles solo, and only at the lower bands; from Band 2 or 3 it becomes a hired role too.

The studio plans against a **3-year production cycle**: prototype → demo → V1 on Steam by the end of year 3. The cumulative-funding figures in each row below are *total funding raised over the full 3-year cycle*, not progressive year-by-year targets. The band the project lands at is determined by what the 3-year total actually was; whichever band that is, that is the game and the price.

The £700/month baseline alone produces £25,200 over 3 years (£700 × 36), which puts the project firmly inside Band 1 with no external revenue at all.

## The matrix

| Band | Total funding over the 3-year cycle (GBP) | Scope of game | Download price (USD) |
|---|---|---|---|
| 0 | Up to £10,000 (around the baseline alone for one year) | Compact: a small handful of venues and partners | $2 |
| 1 | £10,000 to £25,000 | Compact, same as Band 0 | $3 |
| 2 | £25,000 to £75,000 | Modest: more venues and partners | $5 |
| 3 | £75,000 to £250,000 | Mid: most of the venue set; postgame begins to fill | $7 |
| 4 | £250,000 to £750,000 | Full: every venue and partner the design names; the V1 the studio aims to ship | $9.99 |
| 5 | £750,000 to £2,000,000 | Full plus sustained postgame; ports if they make sense | $19.99 |

Every band gets a Steam release alongside itch and the web build. Steam Direct is a flat one-time fee, so the cost of being on Steam is essentially nothing; visibility on Steam is a separate question. Same product, same price across all three surfaces. Bands are GBP cumulative, prices USD per the studio's pricing convention (the storefronts work in USD; the studio's reporting works in GBP). The price climb at any band applies to *new buyers*; existing owners are never asked to top up.

The £2M ceiling is anchored to **Aseprite** (the matrix's named per-product analogue, $19.99 on Steam) and matches *Caves of Qud* and *Massive Chalice* from comparable tiers. Above £2M cumulative, the studio is no longer working on this one game's funding question and a different planning document takes over.

What scales per band beyond game scope: score scope and art scope live in their own per-band tables under [Score and art scope](#score-and-art-scope); team shape lives under [Employees and contractors](#employees-and-contractors).

## Score and art scope

Both the score and the art scale with the bands. Each is a separate table because the disciplines are commissioned independently, and the work shipping at any band is the real work for that band, not a stand-in.

### Score

What actually scales is **ensemble size and orchestration depth**: piano alone, piano plus a couple of players, small ensemble, full ensemble, full ensemble plus an orchestral section. Unusual instruments (vibraphone, talk box, harp, wild synth, the kinds named in the [audio bible](../audio/bible.md)) can land at any band including Band 0; a single session is small enough that the band's budget is not the constraint. What constrains them is whether the piece calls for one.

| Band | Score scope |
|---|---|
| 0 | Compact commissioned piano cues; an unusual instrument can layer in where a piece needs it |
| 1 | Compact commissioned piano cues at slightly larger scope; same instrument flexibility |
| 2 | Commissioned piano across the game; one or two additional players where the piece calls for them |
| 3 | Piano plus a small ensemble for selected cues |
| 4 | Full ensemble across the game; longer mixing passes |
| 5 | Full ensemble plus orchestral sections (strings, brass); the multi-genre work the [audio bible](../audio/bible.md) reaches for |

### Art

Animation is a Band 0 concern: the rally itself is animated, characters swing a racquet, the ball moves. The minimum animation set (idle, swing, recover, ball flight, ball bounce) ships at Band 0. What scales with funding is *animation scope* (more characters, more contextual animations, secondary motion) and *art fidelity* (compact set → art-bible standard → polish + lighting), in parallel.

| Band | Art scope |
|---|---|
| 0 | Compact commissioned art set; minimum animation (rally motion, swing, ball, basic character poses) |
| 1 | Compact commissioned art set at slightly larger scope; animation as Band 0 |
| 2 | First full art set across the venues; expanded animation (more poses, basic contextual animations) |
| 3 | Art-bible standard across the venues that ship; animation across the partner cast |
| 4 | Art-bible polish on every layer; full animation (idle variations, contextual responses) |
| 5 | Studio-wide art polish; full animation with secondary motion (cloth, hair) and full lighting |

## Employees and contractors

The studio's people across the bands fall into five disciplines: **tech**, **art**, **sound design**, **music**, and **marketing / PR / community**. Every discipline is present at Band 0; none get added or removed as the bands climb. What changes is how the work is staffed.

**At Band 0, every discipline is a contractor.** Including tech in part: Josh handles tech on the lower end, and external tech help (engine specialists, infra, porting) is brought in as the work demands. The reason is rotational: the work is bursty. The composer needs to write for a few weeks for a cue and then there is no music work for a month. The artist needs a sprint of pieces and then nothing for a stretch. Marketing needs a push around a release, then quiet. None of this is a full-time job for a full-time person at Band 0; running it as commissions to specialists who swap in when needed is honest to the actual shape of the work and to the budget.

**From Band 1 onwards, FTE hires begin.** The first hire is whichever discipline has stopped being bursty and started being constant; production and tech are typical first FTEs. Specialist commissions (composer, lead artist, marketing partner) continue alongside the FTEs at every band, sized to the band's scope.

**By Band 4 (V1-launch headcount):** tech, production, design have FTE leads; art and music carry FTE seats with contractors filling specialist work; marketing / PR / community is at minimum a part-time FTE through the V1 launch window, often a launch-window contractor uplift on top.

**By Band 5:** the studio has senior leads in every discipline, with contractors brought in for specialist work that doesn't justify a permanent seat (multi-genre score work, one-off art commissions, ports, regional marketing).

The studio's hiring posture for FTE roles is **high-talent juniors with growth runway, treated well**. Junior loaded cost ~£32K to £45K means more bodies per band, and the team that grew up with the studio becomes its senior leadership at higher bands. Specialist commissions are senior-from-day-one because they are commissioned for specific work.

## What the matrix does not promise

The matrix is not a roadmap; it does not commit the studio to reaching any particular band by any particular date. It is not a paywall; the web build is free at every band, the source is open at every band, the escape hatch never closes. It is not an excuse; if the studio reaches Band 4 funding but the work that band represents is not done, the price does not climb. The studio reaches a band by *building the band's product*, not by collecting the band's cash. The price changes only at milestone releases, when a band's full scope ships.

## Open questions

- The exact dollar boundaries of each band. Current numbers are guesses; the studio replaces them with real cost figures as quotes arrive.
- How the studio handles a band where funding arrives but a key collaborator does not. Probably: the band is not reached until the work is done.
- The transition rule when the studio is between bands at a milestone (e.g. the milestone delivers half the next band's scope). Probably: the price does not move until the full band's scope ships.
