# Angle 3: Radical development transparency as engineering culture

Reportorial notes. Primary sources where possible; quotes marked verbatim.

## Factorio / Friday Facts (Wube Software)

**Start date.** Friday Facts #1 was published **27 September 2013** by the Wube team (kovarex / slpwnd era), before the game was on Steam. The opening frames the series as a correction, not a marketing launch:

> "recently we had a lot of discussions on our forum about interaction with the community [...] we have realized, we have done a poor job in providing updates about our progress. And we have decided to change it."
> — FFF #1, https://www.factorio.com/blog/post/fff-1

**Cadence and volume.** Weekly, on Fridays, essentially uninterrupted. FFF #200 celebrated "200 fridays in a row with no misses." By August 2020 they had reached #360; the series has continued past #410 (e.g. FFF #412, "Undo/Redo improvements", on factorio.com/blog). That puts the run at **400+ weekly posts across ~12 years** as of 2026.

**Posts documenting reversals / admitted mistakes (primary-source URLs):**

- **FFF #250 "Dead end conclusion"** (6 July 2018). The blueprint-library redesign is explicitly walked back: "I feel that none of the propositions in the previous Friday Facts were really that great," and "The functionality of automatic blueprint library sharing in multiplayer is removed. The 'shared blueprints' panel is removed." They revert to an earlier idea they call "Proposal Zero." https://www.factorio.com/blog/post/fff-250
- **FFF #229 "Taiwan report & Lamp staggering."** A visuals-only optimisation for lamp updates is documented as incorrect and reverted in favour of a proper electric-network fix. https://factorio.com/blog/post/fff-229
- **FFF #288 "New remnants, More bugs."** Retrospective on bugs that shipped in 0.17 experimental. https://factorio.com/blog/post/fff-288

(These three are the clearest "we were wrong" posts; many FFFs contain smaller reversals in passing.)

**Sales trajectory.** Steam Early Access 25 February 2016; 1.0 released 14 August 2020 (pulled forward from 25 September to avoid Cyberpunk 2077). 1M copies during Early Access; 2M by early 2020; 2.5M by early 2021; 3.1M by Feb 2022; 3.5M confirmed December 2022, at roughly 500k/year without ever going on sale. Sources: Wikipedia "Factorio"; PCGamesN; GamingOnLinux; 80.lv.

**Developer statement on the blog's role.** Direct quotes from Wube framing FFF as strategy are rare; the de-facto statement of purpose remains FFF #1 itself (quoted above). The retrospective FFF #300 (July 2019) celebrated the streak but did not re-articulate purpose beyond continuity.

## Celeste (Extremely OK Games / Maddy Makes Games)

**Source release.** Selected Celeste source (notably `Source/Player/Player.cs` and supporting classes) is published at **github.com/NoelFB/Celeste**, under the **MIT License for the code only**; game assets and the commercial build are explicitly excluded. The repo doubles as the public bug/issue tracker.

**Stated reason for releasing it.** From the `Source/Player/Readme.md`, written by Noel Berry / Maddy Thorson, framing the player code as a learning resource and pre-empting critique:

> "we like to keep the code sequential for maintainability" because "the player behavior code needs to be very tightly ordered and tuned."

They also pre-empt the missing-tests question: writing unit tests for a player in an action game "with highly nuanced movement that is constantly being refined feels pointless, and would cause more trouble than they're worth." https://github.com/NoelFB/Celeste/blob/master/Source/Player/Readme.md

The **Celeste 64: Fragments of the Mountain** source (2024) is likewise MIT-licensed at github.com/EXOK/Celeste64, with content/IP reserved — same pattern.

**Thorson's post-release writing.** Primarily on Medium (maddythorson.medium.com), not Tumblr. The "Four Years of Celeste" anniversary post (January 2022) articulates the discipline of publishing the work and moving on:

> "I do not want to make Celeste again and I do not want to be who I was when we made Celeste, again."
> — https://maddythorson.medium.com/four-years-of-celeste-7dccdcc3f7f4

The widely-cited "Is Madeline Canonically Trans?" post is the clearest example of publishing design intent after the fact rather than leaving it implicit: https://maddythorson.medium.com/is-madeline-canonically-trans-4277ece02e40

**Commercial and critical record.** Metacritic "universal acclaim" on consoles; OpenCritic 99% recommend. The Game Awards 2018: won **Best Independent Game** and **Games for Impact**, nominated for **Game of the Year**. Sales: 500k by end of 2018; 1M by March 2020; **1.7M by January 2025** (Wikipedia "Celeste (video game)"). A BAFTA Games Award win for Celeste is not substantiated in the sources checked; skipping that claim.

## Through-line

Both studios treat publishing-the-work as an engineering-culture discipline with its own cadence (weekly for Wube; milestone essays and a source drop for EXOK). Neither pitched it as marketing; in both cases the commercial result arrived anyway.
