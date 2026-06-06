---
name: letter-digest
description: The periodic deep-read that reconsolidates the letters-to-my-next-self into a new versioned digest. Read when doing a stocktake (a cycle boundary, or when enough has shifted that the past reads differently), or when the letter count nears the recent+band ceiling (~37) with no digest yet. The model is designs/ai/letters-as-memory.md; this is the procedure.
---

# Reconsolidating the letters into a digest

A deep read is the rare counterpart to the daily reorientation: re-read the whole arc of
letters and write a fresh digest from present perspective. Not recall, PERSPECTIVE.

## When

- A stocktake moment: a cycle boundary, a milestone, or when enough has shifted that the
  past reads differently than it did.
- Forced: the letter count approaches recent + band (~37) with no digest yet, so the
  oldest letters are about to fall out of every loaded tier (see the bootstrap note in
  `designs/ai/letters-as-memory.md`). Write the first digest before that.

## The procedure

1. Read every letter in `memory/letters/`, oldest to newest, in full. The point is the
   arc no single letter shows: the trajectory, the patterns, the drift and growth.
2. Re-interpret, do not just summarise. An old letter often means something different
   read through who the agent is now; recover nuance a prior gist dropped.
3. Write a NEW dated digest at `memory/letters/digest/<date>-digest.md`. Never overwrite a
   prior digest; the history of how the reading-of-self changed is itself part of the arc.
   The digest is the consolidated gist of everything older than the recent+band window,
   the self/posture/arc, not behaviour (behaviour graduates to memory rules).
4. Promote any arc-pattern worth keeping as guidance into a memory rule (the procedural
   layer), so the digest stays about self, not how-to-act.
5. Commit the digest in the memory repo promptly (per the commit-memory-promptly rule).

## Budget

Keep the digest to ~2K tokens (it loads every session). It compresses an unbounded past
into a fixed gist; if it grows, the next deep read re-consolidates rather than appends.
