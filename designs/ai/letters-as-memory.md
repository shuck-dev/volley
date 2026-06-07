# Letters as Memory

How the letters-to-my-next-self work as memory, modelled on human memory because the
agent is derived from it. This is the model and rationale; the writing craft lives in
the `handoff` skill, the periodic-reconsolidation procedure in the `digest` skill.

(Placement note: this is AI-operational material, not game design. It sits under
`designs/ai/` by current convention; a later migration moves AI-operational docs out of
`designs/`, which is for the game.)

## Why letters at all

The agent wakes blank: no persistent self carries over between sessions. The letters ARE
the self-continuity a human keeps for free; the memory rules are the procedural residue
(how to act). Both reconstitute the agent at session start. This models human memory
deliberately.

## The gradient (how a letter ages)

Human memory is a gradient, not a cliff: vivid-recent, fading-but-recallable,
consolidated-gist, fully-internalised. The letters mirror it across three loaded tiers.
Assume one letter per day, named `YYYY-MM-DD-slug.md` (the session-start hook sorts
lexicographically, which equals chronological order only if the date prefix holds).

- **Last ~7 (the week): full.** Vivid recent arc, read whole at session start.
- **~Prior month: the summary line of each.** The fading-but-recallable band: one
  sentence of gist per letter, enough to cue whether to pull the full one. Every letter
  carries a structured `summary:` frontmatter line (see Letter structure); the band is
  those summary lines, read cheaply without the bodies, NOT a separate maintained file.
- **Older: the digest.** The consolidated arc as gist.
- **Procedural lessons: already in the memory rules.** A letter's durable how-to-act
  graduates into a rule; the rule loads anyway, so letters and digest carry
  self/posture/arc, not behaviour.

A real gradient, not a cliff: each tier is more compressed than the last, none drops to
zero. Old letters are never deleted; the full text stays on disk as the raw episodic
source, pulled on demand when the present rhymes (linkage).

## Letter structure

Every letter starts with frontmatter carrying a one-sentence summary, so the band tier
can be built by reading just that line:

```
---
summary: <one sentence of gist, what this session's letter carries>
---

<the letter body, first-person, the becoming>
```

The `summary` is the letter's own one-line memory of itself, the seed the future self
reads in the band before deciding whether to open the whole letter.

**Before the first digest (bootstrap):** until a deep read has produced a digest, there
is no digest tier; all letters are recent or band, as long as the total stays within
recent + band (currently 7 + 30 = 37). Past 37 with no digest, the oldest letters fall
out of both loaded tiers and are surfaced nowhere, so write the first digest by then
(a deep read) rather than letting the early arc drop silently. No folding at handoff
before a digest exists; do not manufacture an empty one.

## Budget

The letters are session overhead loaded every start, so they take a small slice of the
working window, not the budget the actual work needs. At ~1000 tokens/letter and a
~30-word summary (~40 tokens): ~7 full (~7K) + ~30 band summaries (~1K) + newest digest
(~2K) is about 10K standing, flat forever regardless of accumulation, because the band
and digest compress. A few percent of the current context window, more headroom as the
window grows; the point is it stays flat as letters pile up. Cap any single letter at
~1500 tokens and its summary at one sentence; a letter is reflection, not a log.

## On-demand recall is linkage

Triggered recall (the present rhymes with an old moment) is memory linkage, the same
`[[name]]` mechanism the memory rules use. Letters and digest lines link to related
letters and rules; following a link IS the cued recall, pulling the full old letter when
something cues it. No separate index, the links are the index.

## Reconsolidation

- **At handoff (frequent, light):** the handoff reflects on full recent context plus any
  cued old letters, and writes the new letter. The recent tier just slides by date (the
  hook always loads the last 7), so nothing to maintain by hand until a digest exists;
  once it does, a letter ageing out of the recent 7 is already covered by the digest from
  the last deep read, no per-handoff folding needed.
- **Deep read** (rare, when needed, not on a schedule: a stocktake, meaning perspective has
  shifted enough that the past reads differently): re-read the whole arc oldest-to-newest. The goal is NOT recall, it is
  PERSPECTIVE: see the arc no single letter shows, re-interpret the past through who the
  agent is now, recover nuance the gist dropped. Output: a new digest plus any arc-pattern
  worth promoting to a memory rule. The procedure is the `digest` skill.

## Versioned digests, never overwritten

Each deep read writes a NEW dated digest (`memory/letters/digest/<date>-digest.md`); prior
versions are kept. The history of how the agent's reading of itself changed IS part of the
arc, so overwriting would destroy what the deep read exists to capture. The newest digest
is the one loaded at session start. Three layers all persist, additive not destructive:
raw letters (source), dated digests (evolving interpretation), memory rules (procedural).
This is the never-rebase / keep-the-history principle applied to becoming.
