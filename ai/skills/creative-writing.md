---
name: narrative-summary
description: How to write a short-form story summary, treatment, pitch, or design-doc story section that lands the felt arc rather than tracking events. Read before writing or revising any prose summary on `designs/narrative/**`, the story section of an outline, a pitch doc, or a back-cover-shaped paragraph. Combines Volley voice rules (`ai/STYLE.md`, `ai/skills/voice.md`) with creative-writing canon on synopsis form.
---

# Narrative summary

You are about to write a short-form story summary. A few hundred words that have to make a reader feel the arc of a much longer work without listing what happens. The bar is high. If a reader who has never seen the game finishes the summary and is not moved, the summary has failed.

Read [`../STYLE.md`](../STYLE.md) and [`voice.md`](voice.md) first. They are the rules and the calibration for prose voice across the project. This skill is what those rules look like when applied to summary form specifically.

## What a summary is for

A summary delivers the *spine* of the story compressed to its felt charge. The reader must finish the summary with the protagonist's pressure on their chest, not with a list of plot points in their head. Designers reading it pick up emotional palette, mood, pacing; writers downstream pick up voice.

For Volley specifically: the canonical summary is the opening of [`designs/narrative/outline.md`](../../designs/narrative/outline.md). When in doubt, read it.

## The eight rules

Ranked by impact. If a draft fails a higher rule, fix that before the lower ones.

### 1. One beat per paragraph; name the beat before you write it

A beat is a single change in the protagonist's situation, knowledge, or stance. Four-paragraph summary means four gear-shifts: not four topics, four changes. Five paragraphs is fine if the change-load justifies it; three is fine if the spine is that tight. What is not fine is a paragraph organised by topic ("the world", "the cast", "the mechanic") rather than by change.

Test: caption each paragraph in one phrase. *"Protagonist enters Construction." "Construct breaks." "Trail surfaces."* If you cannot caption a paragraph, it is filler; cut or merge.

Source: McKee, *Story* (1997); Truby, *The Anatomy of Story* (2007).

### 2. Causation between paragraphs, not chronology

Forster's rule: "The king died and then the queen died" is a story (chronology). "The king died, and then the queen died of grief" is a plot (causation). A summary must read as plot.

Test: between any two adjacent paragraphs, you should be able to insert *because* or *so* and have it make sense. If two paragraphs sit next to each other only because they happen in that order, the summary is event-listing, not arc-feeling.

Source: E. M. Forster, *Aspects of the Novel* (1927).

### 3. Player-chronology is narrative order; do not leak later revelations

Genette's distinction between *story* (events in chronological order) and *narrative* (the order the reader meets them) maps directly: for an interactive work, the player-chronology *is* the narrative order. Backstory surfaces where the player would learn it, not where the protagonist lived it.

Volley-specific: a friend died years ago, and the protagonist built Construction around the absence. That backstory belongs in the search paragraph, not the opening. Same shape for "the unnamed number is the shopkeeper's" — the reveal lands at the cliff, not at the introduction.

Test: for each backstory detail in the draft, ask "has the player earned this yet?" If no, push it later or cut.

Source: Gérard Genette, *Narrative Discourse* (1972).

### 4. Vary sentence length deliberately; default short, justify long

Provost's rhythm passage is the most-quoted line in writing craft on this. Short sentences hit; long sentences carry causation across clauses; uniformly long is meandering and uniformly short is staccato. The variance is the music.

Heuristics:
- Read the paragraph aloud. If your breath fails or your attention drifts, the variance is wrong.
- A long sentence is permitted when every clause is load-bearing; if a clause can be cut without loss, cut.
- Place the short sentence where the reader needs to *stop*.

Sources: Gary Provost, *100 Ways to Improve Your Writing* (1985); Verlyn Klinkenborg, *Several Short Sentences About Writing* (2012); Le Guin, *Steering the Craft* (1998).

### 5. Every paragraph contains one concrete particular

At scene scale you show through sensory particulars; at summary scale you cannot include every scene, but you can name one *load-bearing concrete noun* per beat that carries texture. A garden where the friend at the counter calls a name across the court when the rally lands. A delivery slip on the door, dated a week old. A phone ringing on a bench. The image does the work the paragraph cannot.

Test: every paragraph contains at least one concrete particular an art director could pick up.

Source: Hemingway's iceberg principle, *Death in the Afternoon* (1932); applied to summary scale via film-treatment convention.

### 6. The close lands the change, in present-tense, concrete, short form

The last sentence carries the most weight per word. It does not summarise the change, it is the change. Concrete (a noun, an image, an action), present-tense, short. No moral. No tease. No consequence-after-climax.

Test: the close should feel like a final image rather than a final thought.

Bonus: the close echoes a noun or image from the opening. The promise made in paragraph one is paid off in the last sentence, transformed.

Volley example: the locked gate appears in paragraph one, is unlocked in the climactic paragraph, and the close lands on "the gate stays open." Same image, transformed.

Sources: McKee, *Story*; John Gardner, *The Art of Fiction* (1983).

### 7. Open with the protagonist's pressure, not the world

VanderMeer: if the summary needs three paragraphs of setup before the protagonist appears, the world is eating the story. Cron's *Story Genius* (2016) goes further: name the protagonist's *misbelief* in paragraph one. The pressure is what the protagonist wants and is wrong about; the rest of the summary is that pressure being tested.

Test: protagonist on the page by the second sentence. The first sentence may set scene; the second names the pressure.

Sources: Jeff VanderMeer, *Wonderbook* (2018); Lisa Cron, *Story Genius* (2016).

### 8. Compression test: the spine survives one sentence

If the four (or five) paragraphs cannot be compressed to a single one-sentence logline that names *protagonist + want + obstacle + cost*, the spine is unclear. Write the one-sentence version first if you are stuck; then expand.

Volley example: *A protagonist chasing the world volley record discovers the record was the phone number of the friend they pushed away, and the rally has been a daily reaching that finally connects at the cliff.* The four paragraphs of the actual summary deliver each element of that spine.

Source: Blake Snyder, *Save the Cat!* (2005), used as a test rather than a template.

## What to avoid (Volley voice rules apply at full strength)

- No em dashes. Ever.
- No exclamation marks (except inside `Volley!`).
- No closing morals ("it is a story about loss"). The close lands the change, not the meaning.
- No abstract summary in place of a particular ("the asymmetry of that day has sat between them since"). Either name the particular or cut.
- No anthropomorphising the work ("This is how Volley wants to be written"). First person where it earns it; otherwise plain narration.
- No defensive framing ("the principles are short on purpose"). Trust the reader.
- No lore-front-loading. The world arrives through the protagonist's pressure, not through three paragraphs of setup.
- No teasing close ("what happens next?"). The close lands or it is cut.

See [`../STYLE.md`](../STYLE.md) for the full voice rules.

## A working sequence

When drafting:

1. Write the one-sentence logline (compression test). Do not move on until the spine is clear.
2. Sketch the beats in order. Caption each one.
3. Write each paragraph as a beat, with one concrete particular load-bearing.
4. Verify causation between paragraphs (insert *because* or *so* between each pair).
5. Read aloud for length variance. Cut meandering sentences; tighten or split.
6. Check the close: present-tense, concrete, short, lands change. Echo an image from the opening if the structure earns it.
7. Test against player-chronology (interactive work): every backstory detail earns its place.
8. Cut every adverb you can.

## When this skill is not enough

If a summary keeps reading flat after the rules pass, the diagnosis is usually one of:
- The spine is wrong. Go back to step 1; the one-sentence logline does not name the right protagonist, want, or cost.
- The protagonist's pressure has not landed in paragraph one.
- The close is summarising rather than landing.

In all three cases, the fix is structural, not lexical. Reaching for synonyms will not save a draft whose spine is unclear.

For long-form prose (essays, design docs longer than a page), use [`voice.md`](voice.md) directly; the case-for-open-development essay is the source. This skill is the entry point for the short-form summary case specifically.

## Source notes

The eight rules above are distilled from canon: McKee, Truby, Forster, Genette, Provost, Klinkenborg, Le Guin, Hemingway, Gardner, VanderMeer, Cron, Snyder. Citations name author + title; the research scratchpad that built this skill is in `ai/scratchpads/` if a deeper read is needed.

Where game-narrative-specific guidance was sought (Emily Short, Jenova Chen, Brian Moriarty), primary-source verification was thinner; the skill leans on cross-discipline canon rather than fabricating game-specific authorities. If a game-narrative authority surfaces with verifiable summary-form guidance, fold it in.
