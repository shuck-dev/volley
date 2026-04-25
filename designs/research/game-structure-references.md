# Multi-Register Game Structures: A Pattern Reading

## What this doc is

Volley has three registers: a bright Construction the protagonist actively maintains, a Reality that arrives when the maintenance fails, and a Reconstruction that returns to the bright shape carrying what Reality showed. The game needs lineage. Other developers have built two-world and break-the-construction shapes before, and the strongest of them did specific, traceable, attributable things to make the shape land. This doc analyses those decisions, organised by pattern rather than by game. Games appear as evidence for patterns; each pattern closes with what Volley can lift from it.

## Method note

Primary sources first: GDC talks, post-mortems on Game Developer (formerly Gamasutra), interviews on Polygon, RPS, PC Gamer, Eurogamer, and the dev's own writing. Mark Brown's GMTK essay on Spec Ops is treated as design analysis, not reception, because Brown reasons from the dev quotes he cites. Wikipedia is used for hard facts (release date, studio, publisher) only when no primary source establishes them; never as the lead citation for a design claim. When a designer has given few interviews (Toby Fox, Davey Wreden), this is named, and the analysis leans on close reading plus contemporary review.

## Pattern 1: cracks earn dismissibility from prior generosity

The crack only works if the construction has already done genuine work for the player. A fissure in something thin reads as a flaw. A fissure in something built reads as wrong. Walt Williams put this directly at GDC 2013: every horrific moment in Spec Ops had to feel like cause and effect, not authorial intervention. "If it wasn't the obvious result of cause and effect and wasn't absolutely key to the narrative, they threw it out", as the GDC summary captures it. Before chapter eight, the player has spent three hours playing a competent third-person military shooter, with Walker as a credible commander and Konrad as a credible quarry. The genre's pleasures are delivered straight, in full. Then the white phosphorus mortar is offered as the only way through. The civilian casualty afterward lands because the three hours of straight shooter set up Walker as exactly the man who would not flinch from picking up the mortar.

Doki Doki Literature Club holds the same shape on a faster timer. The game opens as a clean visual novel: classroom, club room, four girls with archetypal silhouettes, a poem-writing minigame in which the player picks words to please the chosen girl. Dan Salvato has been explicit that the dichotomy was the design: "wanted DDLC to invite players to not take it seriously, then use that mindset against them by forcing them to rethink their relationship with fiction" (Wikipedia paraphrase from Salvato's own commentary; the design motivations video on his channel is the primary). The first poem night, hour two, is the first crack: Sayori's poem reads as a personal note rather than club homework. The crack is dismissible because the construction has been generous: the poems were a real minigame, the girls had real personality, the club room was a real space. By the time the crack arrives, the player is already using the mode it threatens.

Inscryption pushes this further. Daniel Mullins designed the cabin sequence as a fully playable card game first, with horror dressing second. In a Game Developer feature on the Ludum Dare origin, Mullins describes building the deckbuilder so the legibility problem (small icons, no text) was solved before he layered Leshy and the cabin's strangeness on top. The first scrybe-room break, around hour five, only lands because the player has invested in a deck. Inscryption keeps the deck across the break: the construction was real, and the game inherits it.

The Beginner's Guide's "cleaning lady" level is the inverse worth naming. Davey Wreden does not build investment first; he builds Coda's voice through the narrator. The crack lands on whether the player has accepted the narrator's authority. When they have, the cleaning lady (the narrator inserting his own work into Coda's archive) is a fissure in trust rather than in fiction.

**What works.** The construction is delivered in good faith, on its own terms, for long enough that giving it up costs something. The first crack is small enough that the genre's defaults can absorb it. The cumulative cracks erode those defaults until the singular break is the only legible reading.

## Pattern 2: the break is cumulative and singular

The cracks pile up; one moment is the failure that makes the rest legible. Before that moment, the cracks are noise. After it, they are evidence. Spec Ops is the exemplar. Cory Davis, lead designer, on the cumulative goal: "by the time you get to the end we really wanted to express as strongly as possible what can happen to the psychological state of somebody who goes through these horrible events" (quoted in Mark Brown's GMTK Substack essay "Why Spec Ops: The Line Mattered"). The white phosphorus chapter eight sits where it does because the prior seven chapters have been doing the cumulative work: dialogue degradation, loading-screen taunts, the heat shimmer that turns Konrad into a hallucination. None of those alone is enough. Chapter eight is enough only because of all of them.

NieR: Automata's route C does the same trick on a longer arc. Yoko Taro told PC Gamer he wrote the ending first, then the story to justify it: he started "by thinking he wanted 9S and A2 to fight at the very end, and from there built a story to explain why they're fighting". Routes A and B build the cumulative case. The 9S vs A2 fight is the singular moment that makes both routes legible as setup. The structure is doubled: each ending reveals "a new layer of something", as the Siliconera summary of Taro's Famitsu interview puts it.

Silent Hill 2's reveal of Mary's letter is the cleanest singular moment in the genre. Masahiro Ito has been retroactively explicit on Bluesky and in interviews that every monster except Pyramid Head is a projection of Mary: Bubble Head Nurse is Mary suffocating, Lying Figure is Mary in bed, Flesh Lip's mouth is Mary verbally abusing James. Each monster is a cumulative crack the player encounters as horror; the letter retroactively reveals them as grief. The construction (Silent Hill as horror town) and the singular reveal (Mary's recording) are the two ends of the same arc.

Disco Elysium's church scene works the same way. The cracks are the protagonist's interior chorus debating itself across hours of dialogue; the singular moment is when the church's acoustics let the player hear the cryptozoologist's pain register. Robert Kurvitz, on dialogue design at Rezzed 2018: dialogue was written "to be aggressive and personal", with critical information "repeated multiple times by the protagonist's various skills during key moments" (paraphrased in the GameAnalytics interview write-up). The repetition is the cumulative crack; the church is where the player can finally hear what they have been hearing.

**What works.** The cumulative cracks teach the player a reading they do not yet know they have. The singular moment names the reading. The reading then re-runs through every prior crack, retroactively.

## Pattern 3: reconstruction carries knowledge, not assets

When the player returns to the construction-shape after reality, what changes is meaning, not visuals. Outer Wilds' Eye sequence is the textbook case. Alex Beachum's GDC 2021 talk on curiosity-driven exploration is built around the principle that Outer Wilds rewards understanding rather than acquisition: there are no upgrades, no new tools, only new knowledge. The Eye sequence reuses the assets the player has lived with for hours. What has changed is what the player knows about the loop, the Nomai, and the heat death. The reconstruction is the same place, weighted.

Undertale's pacifist ending operates the same way. Toby Fox designed the battle system so that the kill/spare choice "continues to be significant throughout the game, and if you kill certain people, then you can't be friends with them" (paraphrase from his Mary Sue interview, where Fox's available statements on the system are concentrated). The pacifist epilogue does not add a new place; it returns to the places the player passed through and lets the friendships exist there. The asset budget is mostly the same. The meaning is not.

Disco Elysium's epilogue is the architectural version. After the church scene and the tribunal, the protagonist returns to the same Martinaise streets. The renderings are unchanged. The protagonist's interior chorus has become coherent enough to stop arguing. The player walks past the harbour they have walked past forty times. The harbour is the same; the walk is not.

NieR: Automata's route C complicates this by adding new gameplay (A2 as a playable character), but the underlying principle holds: the world is the world the player already knows, re-perceived through a character whose perspective changes what each location means.

**What works.** The reconstruction does not need new assets to feel new. It needs the player's knowledge to have changed. Reusing the bright-world geometry while letting the player's understanding do the reframing is more economical than rebuilding and lands harder, because the recognition is the point.

## Pattern 4: reality is a different game, not the same game with the lights down

Two-world games that work treat reality as a separate genre, not as a desaturated construction. Omori is the cleanest demonstration. Faraway Town is shaped like a slice-of-life walking-and-dialogue game; Headspace is a JRPG. Different stat names, different combat (or none), different pacing. Omocat, in interviews compiled at the Otaku Journalist profile and the OU Game Developer's Association write-up, has been clear that the dream world drew from "lucid dreaming" and personal dreams while Faraway Town drew from concrete domestic life. The two worlds are not made of the same material.

Catherine does the same with day and night. The day sections are visual novel: Stray Sheep bar, dialogue, text messages on Vincent's phone, a moral meter the player fills by replying to Catherine's messages. The night sections are a block-pushing puzzle game with a horror coat. Atlus did not build the day as "Catherine combat with the difficulty turned down". They built a different game and welded the two together at the bedroom door.

Persona 4 and 5 hold the dual-genre line for hundreds of hours. School day is dating sim and life sim; the dungeon is a turn-based JRPG. The two reinforce each other precisely because they reward different kinds of attention.

13 Sentinels is the structural analogue worth naming. George Kamitani told Frontline Gaming Japan he wrote the adventure parts as point-and-click visual novel "because test players found being forced into battles resulted in stress buildup", so the team "decided to separate the adventure and battle parts in the story". The two halves are different games, deliberately. Players choose when to be in which.

**What works.** Reality is its own register, with its own rules, its own inputs, its own kind of attention. The contrast between registers is the work; matching them defeats the purpose.

## Pattern 5: the hook is named in dialogue, not HUD

Construction games whose goal is delivered through fiction land more cleanly than ones where it appears as a quest log. Stardew opens with the grandfather's letter: "If you're reading this, you must be in dire need of a change. The same thing happened to me, long ago. I'd lost sight of what mattered most in life, real connections with other people and nature." The letter is the hook. It tells the player why they are leaving the city, what the farm is for, and what the game is interested in. Eric Barone, in the 425 Magazine anniversary interview, has discussed the original grandfather evaluation as "a little bit harsh" and "something I added at the last minute to tie together the story with your grandfather", and described softening it because he wanted the game to be "a really relaxed and joyous experience". The hook stayed; the score-card did not.

Disco Elysium opens inside the protagonist's head, with the Ancient Reptilian Brain and Limbic System debating whether to wake up. The hook (you are a detective, there is a corpse, you have lost yourself) is delivered by the skills speaking to the protagonist, not by a quest panel. Kurvitz has said the dialogue UI is meant to read like Twitter; the hook arrives as social texture rather than mission briefing.

Outer Wilds opens with the Hearthian launch codes ritual: a child hands you a torch, you light the marshmallows, you talk to the museum curator about the Nomai statues, you board the ship. There is no mission tracker. Beachum's GDC talk emphasises that the structure was "diegetic and player-determined". The hook is delivered as a community of small in-fiction conversations, each one giving you a thread to pull.

Hades is the precedent for hook-as-character-line. Greg Kasavin, in the GDC Podcast episode 16, described the design conceit: a roguelike with narrative continuity where "every time you run into a boss, they remember", grounded in a character "who's just immortal, they don't die for real, because you don't really die for real in roguelike games". The hook is Zagreus wanting to leave; every escape attempt is named in dialogue with Hades, Megaera, Achilles, Nyx. There is no quest log because every NPC is the quest log.

**What works.** The fiction carries the goal. The HUD shows the count and the resources; the dialogue shows the want. The player learns what to want by being told by someone they care about.

## Pattern 6: construction-as-coping is a load-bearing genre

The construction is itself a defence the protagonist mounts. The crack appears when the construction's energetic cost becomes legible. Disco Elysium is the genre's most precise instance: the protagonist's amnesia is the construction. Every skill check is the protagonist holding themselves together; every failure is a small admission that the holding has limits. Kurvitz, in the GameSpot Audio Logs interview, framed the writing as "aggressive and personal" because the skills are doing emotional work the protagonist cannot.

Stardew is the construction-as-grief reading the grandfather's letter prefigures. The farm is the place the protagonist goes when the city has hollowed them out; tending it is the daily work of being well enough. Barone's softening of the grandfather evaluation is a designer recognising that the construction must not punish; the player is already paying for it.

Spiritfarer is explicit. Nicolas Guérin, in the Game Developer interview: "Spiritfarer's core concept came from our wish to talk about the grave subject matter of death and dying, but in a cozy and wholesome way." And: "Interacting with systems and experiencing them firsthand is unique to our interactive medium, and facing the concept of passing away head-on, of actually losing something, is rather interesting." The boat is stewardship. The cooking, the hugs, the housing upgrades are all rituals that hold the player against the eventual goodbye. Guérin again, in CBR: "It's not our message, it's all entirely yours. We've only created a playground and framework for you to deal with your own emotions." The construction is offered to the player as a place to put grief, not as a story to receive it.

Lake holds the same shape at lower stakes: a postal route in 1986 Oregon as a refuge from the city career.

**What works.** The construction is honest about being a defence. The mechanics that maintain it are the same mechanics that the crack will eventually expose. The player and the protagonist are doing the same work.

## Pattern 7: Animal Crossing as foil

Animal Crossing is construction that never breaks. The villagers do not die. The seasons turn but the year holds. The shop opens, the fossils accrue, the museum fills, the loan is paid and another loan is taken. Tom Nook is a constant. Players have spent twenty years living inside this construction.

The cost of never breaking is that the construction cannot mean anything beyond itself. Animal Crossing is sincere about being a place to be; it does not pretend to be a place that is hiding something. The bright world is the whole world. This is not a failure mode. It is a different kind of game. But it is the foil Volley needs to name, because Volley's bright world is doing what Animal Crossing's bright world is doing for the first hour or two, and then doing something Animal Crossing never does. The player who likes Animal Crossing for the unbroken construction is exactly the player who must be allowed to enjoy Volley's bright world on its own terms, per the north-star ("the idle loop was always worth playing"). What separates the two is that Volley earns the right to crack by being good enough to not need to.

## The contrasts

Watch Dogs Legion and Hellblade name the failure modes worth flagging. Legion's procedural-character system was sold as "play as anyone in London"; the design tradeoff was that no character carried specific weight, so the cracks (if there were any) had nowhere to land. The construction was wide and shallow. Hellblade put the player inside Senua's psychosis from minute one, with the voices already at full volume. The construction never had the chance to be generous before becoming compromised. Both games are interesting; neither holds the build-then-break shape. The Spec Ops principle applies in reverse: a crack in something thin reads as a flaw.

The Stanley Parable, by contrast, is a deliberate refusal of the build-then-break shape; it builds and breaks simultaneously, as comedy. It belongs to a different genre. Volley's lineage is not there.

## Open research questions

Three claims could not be established to the standard the rest of the doc holds.

The Stardew grandfather letter quote is reliably reproduced across summaries and wikis, but the original Eric Barone interview where the design intent is named in his own words is harder to surface than expected; the 425 Magazine anniversary piece and IGN's lengthy interview are the strongest available, and the softening-the-evaluation quotes there are what the analysis above relies on. The letter's wording itself is in-game canon, primary by definition.

Toby Fox has given few interviews; the Undertale pacifist-route design analysis above leans on the Mary Sue interview and the Escapist piece, which are the two clearest extant primary statements. Heavier claims about the route's intent would require quotes Fox has not given.

Davey Wreden, similarly, has not extensively interviewed about The Beginner's Guide; the Designer Notes podcast with Soren Johnson (Idle Thumbs Network, October 2015) is the strongest single primary source, and is unavailable as a transcript without listening through. The cleaning-lady reading above is reception-grounded (Brendan Keogh's essay, Emily Short's blog post from the same week) rather than dev-confirmed. This is named in-text where it appears.

What would unblock further analysis: the GDC Vault videos for Williams, Beachum, and Kasavin in full transcript form would tighten several quotes; Frontline Gaming Japan's three-part Kamitani interview is rich and could anchor a deeper 13 Sentinels read; and Ito's Bluesky posts on Silent Hill 2 are scattered and worth a dedicated archival pass before they vanish behind login walls.
