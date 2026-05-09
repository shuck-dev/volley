# Narrative outline formats

Research scratchpad for mission Banana Stopa: which writers'-room-style outline format would best replace `designs/narrative/outline.md`. The current doc is too in-the-weeds, too game-aware, and does not inspire writers. The redo needs to be less mechanical, sincere, heartfelt, unique, and serve as a clear guide while threading enough story to give context. Below: the long list of traditions surveyed, three finalists with worked Volley fragments, and a recommendation.

A note on sources. Most studios do not publish their internal bibles. Where the document itself is closed, this scratchpad relies on the developer's own description of it in talks, podcasts, and devlogs, and says so.

## Long list

**The TV show bible.** A reference document for incoming writers: logline, story engine, character breakdowns, pilot, future seasons. The format has migrated into games via TV-trained writers. Studiobinder's template is the most-cited current version; ScreenCraft maintains a list of canonical examples (*Lost*, *Friday Night Lights*, *Breaking Bad*) ([Studiobinder](https://www.studiobinder.com/blog/what-is-a-show-bible-examples-template/), [ScreenCraft](https://screencraft.org/blog/21-series-bibles-that-every-tv-screenwriter-should-read/)). Its strength is onboarding. Its weakness is that it reads like a pitch document; it tells the show, it does not feel it.

**The Disco Elysium worldbuilding compendium.** Robert Kurvitz's worldbuilding for Elysium grew over twenty years out of a tabletop campaign and a 2013 novel, *Sacred and Terrible Air*. The internal design document existed in three printed copies, one of which a former line producer reportedly tried to sell after the studio fractured ([Game Camp France 2024 talk](https://www.youtube.com/watch?v=rqYGh078W0I), [80.lv on the ZA/UM split](https://80.lv/articles/truth-behind-firing-disco-elysium-developers-za-um-s-canceled-sequel)). The model is encyclopaedic: an authored cosmology, indexed by entry, with the writer's voice present in every paragraph. Strength: voice. Weakness: scale; Elysium is one million words deep, Volley is not.

**The Kentucky Route Zero act script.** Cardboard Computer (Jake Elliott, Tamas Kemenczy, Ben Babbitt) built KRZ over a decade, releasing it act by act between 2013 and 2020. Their public-facing texts read like staged plays: scene headings, stage directions, prose passages that double as design notes. The GDC 2014 talk "Designing for Mystery" describes how the script works alongside the prototype ([GDC Vault](https://gdcvault.com/play/1018063/Designing-for-Mystery-in-Kentucky), [SAIC profile](https://libraryguides.saic.edu/cate/kyroute0)). Strength: it makes a writer want to write. Weakness: prescriptive on staging; can crowd out invention.

**The Outer Wilds knowledge-truth document.** Mobius Digital's narrative does not gate on objects; it gates on the player learning facts about a fixed world. Co-creative leads Alex Beachum and Loan Verneau described the design at GDC 2020: every bit of lore is something true, placed in the world, that the player can find in any order ([GDC 2020](https://gdconf.com/article/attend-gdc-and-learn-how-outer-wilds-nailed-curiosity-driven-game-design/), [Loan Verneau interview](https://www.pointnthink.fr/en/loan-verneau-creative-lead-at-mobius-digital-on-outer-wilds/)). The internal doc, by their account, is closer to a "what is true in this world" register than to an act outline. Strength: handles non-linear story without confusion. Weakness: less useful for a game with a fixed two-act spine.

**The Citizen Sleeper vignette ledger.** Gareth Damian Martin built *Citizen Sleeper* as a stack of small written scenes hung on a contract loop; the writing draws on their own experience of trans life, chronic illness, and precarity, and the BAFTA "minimum viable design" talk describes how the vignettes were written before the systems hardened ([BAFTA talk](https://www.youtube.com/watch?v=r2b_M4a8SoQ), [Origin Story](https://www.originstory.show/episodes/citizen-sleeper)). Strength: small, sincere, place-and-character led. Weakness: assumes a vignette-shaped game.

**The Firewatch playable Twine.** Sean Vanaman's team replaced a static character document for Henry with a playable Twine the rest of the team could explore; it became the game's intro ([Film Stories on Firewatch](https://filmstories.co.uk/features/firewatchs-henry-and-tutorialising-narrative/), [Wikipedia: Firewatch](https://en.wikipedia.org/wiki/Firewatch)). Strength: turns the bible into something walkable. Weakness: a tool, not a document; does not sit alongside `story.md` cleanly.

**The Inkle Ink-script outline.** Jon Ingold's *Heaven's Vault* is written directly in the open-source Ink scripting language, where the outline and the runtime script are the same artefact, with conditional branches and reusable scenes ([GDC Vault on Heaven's Vault](https://gdcvault.com/play/1025392/-Heaven-s-Vault-Creating), [Game Developer interview](https://www.gamedeveloper.com/design/knockin-on-i-heaven-s-vault-i-how-inkle-designed-its-first-3d-game)). Strength: outline and implementation share one source. Weakness: pulls the document toward systems; bad fit for a story-only outline.

**The Yoko Taro multi-route grimoire.** *Grimoire NieR* and its revised edition are an external supplement that documents the world across the multiple endings *NieR* produces; *The Lost World* novella from the Grimoire was later adapted into *Replicant ver.1.22*'s Ending E ([NieR wiki on The Lost World](https://nier.fandom.com/wiki/The_Lost_World)). Strength: handles multiple readings of the same story. Weakness: again, external supplement, not a working bible.

**The Octavia Butler commonplace book.** The Huntington holds nearly 200 of Butler's notebooks, where she compiled "working notes for novels and short stories, research, journal entries, notes on daily life and activities", in a hybrid she kept porting from paper to early Mac through the 90s ([The Huntington archive](https://www.huntington.org/verso/mining-archive-octavia-e-butler), [Online Archive of California finding aid](https://oac.cdlib.org/findaid/ark:/13030/c8hm5br8)). Strength: working document, voice-led, gathers rather than dictates. Weakness: a notebook is not a guide; it does not onboard a second writer.

**The Le Guin carrier bag.** Le Guin's 1986 essay reframes story away from the spear (single hero, killing blow) toward the receptacle: a bag holds many things at once, each one important ([ursulakleguin.com](https://www.ursulakleguin.com/the-carrier-bag-theory-of-fiction), [The Outline](https://theoutline.com/post/7886/ursula-le-guin-carrier-bag-theory)). Not a format in itself; a posture that some of the formats above instantiate (notebook, vignette ledger).

**The Lucas Pope public devlog.** The TIGSource thread for *Obra Dinn* ran from July 2014 to June 2019; the dithering reversal of November 2017 was the work being walked back in public after readers said the new version was worse ([Pope's devlog index](https://dukope.com/devlogs/), [TIGSource thread](https://forums.tigsource.com/index.php?topic=40832.0)). The thread is the bible. Strength: aligns exactly with the open-development posture. Weakness: chronological, not navigable by canon point.

**The Susan O'Connor structural template.** O'Connor teaches an eight-beat narrative spine through The Narrative Department: Need, Desire, Opponent, Plan, Battle, Moment of Realization, New World ([The Narrative Dept](https://www.thenarrativedept.com/), [Game Developer profile](https://www.gamedeveloper.com/design/upping-the-craft-susan-o-connor-on-games-writing)). Practical, well-tested. Risk for Volley: it foregrounds Opponent, and Volley does not have one in any conventional sense; the opponent is the protagonist's avoidance.

**The Emily Short storylet inventory.** Short's blog catalogues plot architectures for non-linear narrative: branching, quality-based, salience-based, waypoint, storylets ([Beyond Branching](https://emshort.blog/2016/04/12/beyond-branching-quality-based-and-salience-based-narrative-structures/), [Storylets: You Want Them](https://emshort.blog/2019/11/29/storylets-you-want-them/)). Index-card-led, modular. Strength: rigorous about non-linearity. Weakness: assembled, not authored; loses voice.

**The Fullbright environmental-story room sheet.** Steve Gaynor and Kate Craig described the *Gone Home* approach at GDC 2015: documents written per-room, per-object, with the family's recent move as the design constraint that made the inventory legible ([GDC 2015 archive](https://archive.org/details/GDC2015Gaynor), [Game Developer write-up](https://www.gamedeveloper.com/design/how-i-gone-home-i-s-design-constraints-lead-to-a-powerful-story)). Strength: turns place into prose. Weakness: presumes static spaces.

## Three finalists

### 1. The Cardboard-Computer act script

A document organised as an act-by-act sequence of staged scenes, each a short prose passage with light direction, written in the authorial voice and read like a play.

The format borrows from theatre, which Cardboard Computer borrows from openly: KRZ's Acts are released as published texts that read as plays, and the studio talk at SAIC in October 2025 describes the writing-as-staging discipline directly ([SAIC event listing](https://www.saic.edu/events/jake-elliott-tamas-kemenczy-and-ben-babbitt-kentucky-route-zero), [GDC: Designing for Mystery](https://gdcvault.com/play/1018063/Designing-for-Mystery-in-Kentucky)). The Slate profile from December 2020 calls the prose "deadpan reactions to bizarre unfolding events" balanced between "Appalachian plain speak" and "speculative fiction" ([Slate](https://slate.com/culture/2020/12/kentucky-route-zero-profile-best-video-game-2020.html)). The doc is the script; the script is the bible.

Why it fits Volley:

- *Inspires the writer.* Reading a staged scene makes you want to write the next one.
- *Threads story.* The prose is the outline; context arrives by being shown.
- *Guides clearly.* Scene headings name venue, time, who is on stage; canon is whatever the script says.
- *Stays out of mechanics.* No HUD or system talk; the rally is a stage business.
- *Aligns with open-development posture.* Authored voice all the way down.
- *Suits Volley's shape.* Two acts, locked-gate hinge, a small cast: the format is built for exactly this size.

Worked Volley fragment:

> **Act I, Scene 7. The garden, late afternoon. The shopkeeper's stall.**
>
> The sun sits low enough that the railings throw slats across the court. The chalk has been touched up since yesterday. THE PROTAGONIST is at the baseline, racquet in the off-hand. The stall is open. THE SHOPKEEPER is behind the counter, leaning on their elbows, watching the rally land.
>
> Beyond the stall, in the wall, sits the gate. Iron, painted pale green a long time ago and not since, a padlock at chest height. The protagonist does not look at it. They have not looked at it today.
>
> The chime rises on the apex return.
>
> **SHOPKEEPER.** Five thousand and one.
>
> A pause that is the wind doing the work, not the writer. The shopkeeper says the protagonist's name across the court. The name is the one only the shopkeeper uses.
>
> **SHOPKEEPER.** That's the week.
>
> The protagonist nods without taking their eye off the ball. The count climbs. The stall smells of citrus. Somewhere a phone, somewhere not in this scene, is not ringing.
>
> *Note to writer: the gate is visible from here but never the subject of attention until Part 2. If a scene in this venue feels like it wants to look at the gate, that is the wrong scene; that scene is later.*

Tradeoffs and risks:

The format can over-specify staging and crowd out the next writer's invention. Mitigation: each scene is short, and italicised author notes carry the canon-locks rather than burying them in stage business. Second risk: the format reads as theatrical, which is on-tone for Volley's bench-and-cliff moment but could feel airless across a whole document. Mitigation: not every entry has to be a scene; place-portraits and character-portraits sit between scenes as quieter beats.

### 2. The Citizen Sleeper vignette ledger

A document organised as a flat list of small, self-contained written scenes, each anchored to a place or a person, each readable on its own, written in the same voice across the document.

Damian Martin describes the writing process as starting from personal, honest scenes: the opening was written first, from "what it felt like to wake up", and the rest was assembled around that anchor ([Origin Story](https://www.originstory.show/episodes/citizen-sleeper), [BAFTA talk](https://www.youtube.com/watch?v=r2b_M4a8SoQ)). The Game Design Roundtable episode #316 with Damian Martin describes the underlying philosophy: literary prose, deliberate obscuring, vignettes as the unit ([The Game Design Roundtable](https://thegamedesignroundtable.com/episode/316-citizen-sleeper-with-gareth-damian-martin/)). The ledger format also resembles Octavia Butler's commonplace books at the Huntington: short entries gathered over time, the voice consistent, the structure emergent ([Huntington](https://www.huntington.org/verso/mining-archive-octavia-e-butler)).

Why it fits Volley:

- *Inspires the writer.* Each vignette is a small finished thing; the next writer reads one and writes one.
- *Threads story.* The vignettes are the story, in fragments.
- *Guides clearly.* The ledger is indexed: by venue, by character, by act.
- *Stays out of mechanics.* A vignette has no mechanics; only people and places.
- *Aligns with open-development posture.* Generous, sincere, accretive. A devlog could literally publish entries from the ledger.
- *Suits Volley's shape.* Two acts of small moments, hinged on the cliff. The format scales down well.

Worked Volley fragment:

> **#23. The locked gate.**
>
> Behind the stall, in the back wall of the garden, there is a gate. Iron, painted a faded sea-green, the colour the railings used to be before the railings were repainted and the gate was not. A padlock hangs from the latch. The padlock is the same age as the protagonist, give or take. There is no key in the protagonist's pockets. There has never been a key in the protagonist's pockets. The gate has been locked the whole of the protagonist's adult life.
>
> The protagonist walks past it every day to reach the stall. They do not look at it. They do not, in any conscious way, avoid looking at it. It is the wall, and the wall is part of the garden, and the garden is the place they train.
>
> What is on the other side: a short path, a bench, a cliff. None of which the protagonist will name to themselves until the album fills.
>
> *Locked: the gate does not open until the sister hands over the key. The padlock is not picked, broken, or worked around. This is the only object in the garden that obeys this rule.*

> **#24. The shopkeeper, before the rally.**
>
> Before the count starts, the shopkeeper unlocks the stall. The unlocking is the first sound of the day. They wipe the counter with a cloth they have had longer than the stall. They lay out the receipt book even though no receipts will be written. They wait. They are always there before the protagonist arrives. The protagonist has never asked when they get up. The shopkeeper has never said.
>
> *Voice: the shopkeeper's name is held back in the document until the cliff, the same way it is held back in the game.*

Tradeoffs and risks:

A flat ledger can lose its spine. Without an act structure, a new writer might write a strong vignette in the wrong tonal register for that point in the game. Mitigation: tag each entry with its act, and order the ledger chronologically by player encounter. Second risk: the format invites length; 200 entries become a swamp. Mitigation: enforce a one-page maximum per vignette and resist the urge to gloss what `story.md` already says.

### 3. The Le Guin carrier-bag, structured as a place-and-people sourcebook

A document organised by what is in the world rather than what happens in it: places, people, objects, weathers, written as authored prose portraits, with the spine of events pulled out into a short separate timeline at the back.

The format draws its posture from Le Guin's "Carrier Bag Theory of Fiction": the story is held in the bag, not pointed by the spear; many protagonists, no single line ([Le Guin essay](https://www.ursulakleguin.com/the-carrier-bag-theory-of-fiction)). Its closest practical sibling is the Outer Wilds approach to canon: every fact is something true in the world, placeable and stable, encountered in any order, described in Beachum and Verneau's GDC 2020 talk ([GDC](https://gdconf.com/article/attend-gdc-and-learn-how-outer-wilds-nailed-curiosity-driven-game-design/)). It also rhymes with Fullbright's per-room sheets for *Gone Home*, where the room is the unit of canon ([GDC 2015 archive](https://archive.org/details/GDC2015Gaynor)).

Why it fits Volley:

- *Inspires the writer.* A portrait of the garden invites a writer to put characters into it.
- *Threads story.* The portraits carry context; the timeline at the back carries the sequence.
- *Guides clearly.* Canon is what is in the bag; if a thing is not in the bag, it is not canon yet.
- *Stays out of mechanics.* Portraits describe what a place is and feels like, not how it is implemented.
- *Aligns with open-development posture.* "What is true in the world" is exactly the register of `story.md` and the open-development essay's "The Source as the Product".
- *Suits Volley's shape.* The two-world structure (Construction, Reality) is itself a carrier-bag conceit: two bags, one footprint where they overlap.

Worked Volley fragment:

> **The garden.**
>
> A walled enclosure at the back of a small house on the coast. Painted plaster, sea-green railings, palm trees against the wall on the south side, where the sun lands longest. A clay court, freshly chalked, the lines redone weekly by hand. A wooden stall in the corner with a counter and a roof of corrugated tin painted yellow inside. A back wall with a gate in it. The gate is locked.
>
> The garden is the protagonist's daily care. The chalk is the protagonist's. The court is the protagonist's. The stall is the shopkeeper's. The wind in the garden is the bond between the two of them; when the bond thins, the air in the garden moves differently, and the rally finds it harder to land.
>
> Two gardens share this footprint without overlapping. Construction's garden is built from the protagonist's memory of the real one, sprucing it up. The real garden, in Reality, is the same shape with less paint and more weather. The gate is on both, and the gate is locked on both, and only one key opens it.
>
> **The shopkeeper.**
>
> Stands behind the counter of the stall in the garden. Calls the protagonist's name across the court when the rally lands. Has known the protagonist longer than the protagonist has known themselves. Their phone number is in the protagonist's phone, unnamed, dialable, never picked up until the cliff. They are alive. They are tired. They have, at the start of Part 2, gone to the bench at the cliff and stayed there, refusing calls. The fear that they are dead is the fear of Part 2, and the fear is wrong.
>
> Their name is the world record. The world record is their phone number. Both facts are held back from the player until the cliff. The writer holds them back too; if a scene seems to want to name either, it is the wrong scene, and the right one is later.
>
> **Timeline (back of the bag).**
>
> The protagonist trains alone, then with partners. The count climbs. The cracks arrive. The championship is won and feels wrong. The protagonist is pulled into Reality. The shop is empty. The album fills as the rally turns to memory recall. The compartment opens; the sister hands over the key. The gate is unlocked. The cliff is the cliff; the bench is the bench; the shopkeeper is alive. The dial connects.

Tradeoffs and risks:

The carrier bag can dissolve into atmosphere if no spine is named; portraits are easier to write than a structure. Mitigation: the timeline is mandatory and short, and every portrait names where in the timeline the place or person is in their canonical state. Second risk: a writer reading portraits without the timeline can write a scene that violates a canon-lock by accident. Mitigation: lock-flags inside portraits ("held back from the player until the cliff"), as in the worked fragment above.

## Recommendation

The carrier-bag sourcebook is the best fit. It matches the open-development essay's posture in tone (authored, sincere, generous with context, low on apparatus); it rhymes with how `story.md` already reads; it handles Volley's two-world shape natively without shoving everything onto a single act spine; and it gives a writer something to walk into rather than a rubric to fill in. The hardest thing for the new outline to do is not contradict `story.md` and not duplicate it; portraits sit alongside the prose comfortably, where a script would compete with it.

The Cardboard-Computer act script is the runner-up and a strong second pick if Josh wants the document to dramatise rather than describe. Its risk is that it crowds invention; its reward is that scenes on the page already feel like the game. The Citizen Sleeper vignette ledger is the third pick, useful if the carrier bag turns out to be too place-led for moments that are really about a person doing one small thing.

If the choice is hard, a hybrid is honest: the carrier-bag sourcebook as the spine of the document, with two or three Cardboard-Computer-style staged scenes inserted at the load-bearing hinges (the championship win, the locked gate, the cliff dial). That keeps the bag the bag, and lets the spear come out for the moments that genuinely want it.

## Loose ends

- No primary source for an internal Volley-style bible used by Mobius Digital or Cardboard Computer; both are described in interviews and GDC talks, never published. The closest published artefacts are the *Disco Elysium* art book and the KRZ act texts themselves.
- Susan O'Connor's narrative template is taught through The Narrative Department but not published in full. If the eight-beat spine is wanted as a sanity check on the carrier-bag's timeline, that is a separate research pass.
- Animation series bibles (Pixar, Ghibli, Cartoon Network) were not surveyed deeply; search returned mostly TV-format material. Separate pass if wanted.
