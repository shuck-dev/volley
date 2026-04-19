# Angle 4: Open Source Earns

Evidence that open-source games sell, and that open tools underpin a generation of indie work.

## Mindustry (Anuken)

- Licence: **GPL-3.0**, confirmed in the repo footer at [github.com/Anuken/Mindustry](https://github.com/Anuken/Mindustry) and on [Wikipedia](https://en.wikipedia.org/wiki/Mindustry).
- Distribution: free builds on [itch.io](https://anuke.itch.io/mindustry), F-Droid, and the GitHub releases page; paid on Steam (AppID 1127400) at $9.99 since the v6 Steam release in late 2019.
- Revenue: [games-stats.com](https://games-stats.com/steam/game/mindustry/) estimates lifetime Steam gross ~**$9.7M** (dev net ~$2.9M after Steam + VAT); [SteamSpy](https://steamspy.com/app/1127400) puts owners at 1-2M. Estimates, not Anuke figures.
- The GitHub README offers no philosophical rationale, only a GPL link and a Steam link. Treat "Anuke's stated reasoning" as **unverified**. The behavioural fact stands: a solo dev publishes source publicly and still clears seven figures gross on the paid store build.

## Shapez / Shapez 2 (tobspr Games)

- Licence of original: **MIT**, confirmed in [shapez.io/LICENSE](https://github.com/tobspr-games/shapez.io/blob/master/LICENSE) and `package.json`. README describes it as "the source code for shapez, an open source base building game inspired by Factorio."
- The community fork, [shapez-community-edition](https://github.com/tobspr-games/shapez-community-edition), is GPL-3.0, maintained by contributors after tobspr moved to Shapez 2.
- Sales of original Shapez: **over 500,000 units on Steam** (cited in [Shapez 2 Wikipedia page](https://en.wikipedia.org/wiki/Shapez_2) and coverage at [gamespress](https://www.gamespress.com/shapez-2-Launches-Fully-Assembled-April-23-on-Steam-Tops-650000-Sales-)), plus ~10M demo plays on shapez.io.
- Shapez 2: **150,000 copies in first weekend** of Early Access ([PCGamesN](https://www.pcgamesn.com/shapez-2/sales-milestone-reached), Aug 2024), **500k** by the Dimension Update ([tobspr on X](https://x.com/tobspr/status/1930595894283440214)), **650k+ by full launch April 2025** ([Games Press](https://www.gamespress.com/shapez-2-Launches-Fully-Assembled-April-23-on-Steam-Tops-650000-Sales-)).
- Shapez 2 is **closed source** and paid-only. The original was a free, open, massively-played demo funnel; the sequel monetises the audience it built. That is the strategic pattern, not "open source sells."

## Godot Engine

- Licence: MIT. Governance via the **Godot Foundation** (non-profit, est. 2022) and separate **Godot Development Fund**.
- Contributors: **2,500+ lifetime**, 500+ on the 4.3 release alone per [Godot Foundation news](https://godot.foundation/news/).
- Funding: **€35,992/month** from 1,521 members + 18 sponsors as of Aug 2025 ([fund.godotengine.org](https://fund.godotengine.org/)); Foundation employs 13 contractors.
- Unity Runtime Fee spillover (Sep 2023): Godot GitHub stars and new-user signups roughly doubled in the month after ([Game World Observer](https://gameworldobserver.com/2024/03/27/godot-doubled-user-base-after-unity-controversy)). Re-Logic (Terraria) donated **$100k to Godot + $100k to FNA**, calling Unity's fees "predatory" ([Game World Observer](https://gameworldobserver.com/2023/09/20/re-logic-donates-200k-godot-fna-engines-unity-runtime-fee)).
- Road to Vostok's Antti publicly ported from Unity to Godot after the fee, spending 615 hours: **"There's a good possibility that Godot becomes the Blender of game engines"** ([PC Gamer](https://www.pcgamer.com/hardcore-survival-shooter-road-to-vostok-is-looking-really-good-after-switching-engines-from-unity-to-godot/)).
- Confirmed commercial Godot titles: **Brotato, Dome Keeper, Cassette Beasts, Halls of Torment, The Case of the Golden Idol, Road to Vostok** (per [Godot showcase](https://godotengine.org/showcase/) and [Automaton West](https://automaton-media.com/en/news/godot-engine-is-seeing-explosive-growth-total-number-of-godot-games-on-steam-surpasses-last-years/)). Automaton notes Godot games on Steam in 2024 already exceeded all of 2023 with five months remaining.

## Blender

- Blender Foundation (non-profit, Netherlands). Primary income: the **Blender Development Fund**, €3.1M received in 2024, funding 15+ full-time devs ([Wikipedia](https://en.wikipedia.org/wiki/Blender_Foundation), [fund.blender.org](https://fund.blender.org/)).
- Corporate backers include **Epic ($1.2M grant, 2019), AMD, Intel, NVIDIA, Netflix (€240k/yr Corporate Patron, 2026), Ubisoft, Arrowhead (Helldivers 2, Gold at €30k/yr)** ([blender.org press](https://www.blender.org/press/ubisoft-joins-blender-development-fund/), [CG Channel](https://www.cgchannel.com/2026/02/arrowhead-game-studios-backs-the-blender-development-fund/)).
- Ubisoft adopted Blender as primary DCC at their Paris Animation Studio.
- Blender Studio's "Open Movies" (Big Buck Bunny through Charge) proved a non-profit can drive a pro-grade tool and ship released art alongside it, bankrolled by community + corporate donations rather than licence fees.

## Counter-evidence and limits

- **Open source is not the sales engine.** Shapez 2 is closed and outsold the open original. Mindustry's Steam buyers aren't compiling from source; they want convenience, Workshop, achievements.
- Plenty of GPL/MIT indie games on GitHub earn nothing. The Mindustry/Shapez pattern needs strong design + a free/web demo funnel + a self-organising community. Licence alone does nothing. No rigorous public dataset of "open-source games that flopped" exists; argued from absence.
- **Anuke's written reasoning** for GPL is not in the README; treat as unverified.

## So what

Open tooling (Godot, Blender) is already the mainstream substrate for a chunk of commercial indie output, and corporate money flows back to keep it alive. Open *game source* is rarer as a revenue strategy but has at least two clear seven-figure-ish proofs (Mindustry, original Shapez). The defensible claim for Volley: openness is a distribution and trust multiplier, not the monetisation itself.
