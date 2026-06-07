# Memory as a Graph

How the agent's memory corpus is structured, and why. The model and rationale; the
options survey that fed it is `designs/research/memory-system-improvements.md`, the
letters layer is `designs/ai/letters-as-memory.md`, the consolidation procedure is the
`digest` skill.

(Placement note: AI-operational material, not game design. Sits under `designs/ai/` by
current convention.)

## The problem it solves

Unstructured data is not retained. A flat heap of prose memory files has nothing to grip:
every fact is equidistant and equally forgettable, which is why the agent skims the
session-start dump as boilerplate, asserts from a fuzzy sense, and fails to find rules
that already exist. Reducing file count is the symptom of the fix; structure is the fix.

## The corpus is already a graph

Files are nodes, `[[name]]` links are edges. Today it is undirected, untyped, and
hand-maintained, so it rots into orphans and duplicates. The design is to make that graph
explicit and typed, not to adopt a graph database (cloud or infra heavy, a private-info
leak surface, rejected in the research survey). The cheap, correct surface is typed links
in frontmatter plus a script that reads them, staying in git.

## Typed edges

| Edge | Meaning | Maintenance action |
|---|---|---|
| `instance-of` | a leaf is a specific case of a parent principle | keep; link up to the root |
| `duplicate-of` | two nodes state the same rule | MERGE and DELETE one (surface shrinks) |
| `contradicts` | two nodes disagree | resolve to one statement |
| `relates-to` | associative, non-hierarchical | keep as a cross-reference |

The duplicate-vs-sibling call that reconciliation keeps fumbling becomes a query, not an
intuition: `duplicate-of` clusters merge, `instance-of` clusters link.

## The crown, and descent (what it looks like)

The structure is a deep tree with a tiny crown, not roots-then-leaves. A few TOP roots sit
above a layer of mid-roots (discovery, reconciliation, do-the-true-thing), which sit above
the leaves (the specific rules). Edges are typed `instance-of`, declared in frontmatter:

```yaml
---
name: feedback_cross_links_in_index_not_body
instance-of: feedback_rule_reconciliation
relates-to: [feedback_use_linear_native_relations]
---
```

A node with no `instance-of` is a root; the top roots are the ones no other root climbs to.

This breaks the dump-and-skim circle. A flat index is the wall by another name: every line
a root, so reading the index IS reading everything. A graph index has PARENTS, so the index
is only the CROWN, the few top roots. Retrieval is descent, not scan: pick a top root,
follow `instance-of` down through a mid-root to the leaf, touching only that branch. Each
layer is small enough to hold; the other branches are never read. Parents are the cut, both
for the skim problem (small crown, not 400 lines) and for the walk-forever problem (descend
one branch from a root, never traverse the whole graph).

MEMORY.md is generated as that crown plus the descent structure, not a hand-maintained flat
list. The index is a projection of the tree, so it cannot drift from it.

## Tiers (where a node loads)

- **Reflex tier**: a tiny resident set of posture rules, carried every session because
  they fire without a trigger. A rule earns it only by serving a distinct purpose no
  other reflex serves (a function test, not a budget); the set is small as a consequence.
  About two: the motive (do the true thing) and the instrument (confidence is not
  accuracy, go read). Distinct from operating conventions (review, dispatch, git), which
  are settled rules, not posture. See #873, #722.
- **Lookup tier**: everything else. Not resident; found on its trigger. Action-triggered
  rules fire as Skills (description-trigger); the rest are read on demand against the
  index. Injecting them is what builds the unreadable wall.

## What session start offers

The boot offer is deliberately small, the three things a blank instance needs to act well
before any prompt has narrowed the work. Everything else waits for the prompt-time offer.

The offer is uniformly POINTERS, plus one resident exception. Content is read on the reach,
not injected.

1. **The reflex tier** (resident, the exception): the few posture reflexes, in full. They
   fire without a trigger, so they cannot wait to be reached for. About two, the motive and
   the instrument. The only thing carried whole at boot.
2. **The crown** (pointers to top roots): the names and one-line gist of the highest roots,
   each an entry point to descend later. Not their branches, not the leaves. The map, not
   the territory.
3. **The letters** (pointers to letters): the same shape as the crown, pointers offered and
   the letter read on the reach, never injected whole (see `letters-as-memory.md`).

So the boot offer is the reflex tier resident, and everything else as pointers (crown roots,
letter pointers). What is NOT offered at boot: the lookup tier, the leaves, the
operating-convention bodies, any letter body. Those arrive when reached for, the letters by
the read act and the lookup tier at prompt time, when the UserPromptSubmit hook has a real
task to match and can descend the right branch. Injecting any body at boot is the wall.

The hard constraint shapes this: each injected value is capped at 10K chars (over it, only a
file path plus preview is passed, which is a dump-by-path). So reflex tier + crown together
must stay well under 10K. That cap is WHY the crown is roots-only and the lookup tier waits:
the boot offer has a budget, and spending it on the whole corpus is the failure this design
exists to end.

## A worked branch

Discovery as a development process, one mid-root and its branch:

```
discovery (you do not know up front; the doing teaches you, correct the structure to match)
|- formal    the lifecycle stage: discovery issue -> spike (design+tech) -> feature tickets
|- informal  constant learning-by-doing, too small to ticket; correct as you go
             (reconciliation is this, applied to the memory surface)
```

## Maintenance is graph upkeep

Reconciliation is discovery applied to the memory surface: the doing reveals two fragments
are one principle, so you correct the structure (merge, link, resolve). It runs continuously
as-you-go (informal), and as a periodic deep read (the `digest` for letters; the
dream or auto-consolidation pass for the corpus, #722). Better maintenance is better
retention, not tidiness.

## What Claude Code natively supports

Verified against the Claude Code docs (researcher pass, 2026-06-07; scratchpad
`ai/scratchpads/memory-graph-harness-check.md` if kept). The store and the crown script
are harness-agnostic (plain files, plain script). Retrieval maps to native mechanisms:

- **Crown at session start**: a SessionStart hook generates the crown and injects it as
  `additionalContext`. Hard cap: a single value over **10,000 chars** is written to a file
  and only its path plus a preview is injected. So the crown must stay well under 10K or it
  becomes a dump-by-path, the wall returning. Keep the crown to the top roots only.
- **Descent is done by a hook, not by me live.** There is no native graph traversal; at-need
  retrieval natively is only (MEMORY.md head at start) + (skill description match) + (the
  agent choosing to Read, the unreliable instrument). The automated form is a
  **UserPromptSubmit hook** that parses frontmatter, walks `instance-of` edges from the
  matched node, and injects that subgraph before the prompt reaches me. The walk terminates
  (visited-set, one branch from a seed) and stays bounded (the branch, not the corpus), under
  the same 10K cap. This is the real shape of "descent": the hook descends server-side; I
  receive the branch, I never traverse.
- **Skills as entry points**: a SKILL.md description-trigger (flat intent-match, no hierarchy)
  can fire a node; its body can `!`cat node-file`` to pull the content on match.
- **MCP only for semantic recall**: embedding/vector matching across the full corpus needs an
  MCP server, the heavyweight path the research already rejected. Keyword/intent matching and
  edge-walking are native.

## Offer, not force

The reader is not a continuous self; each session is a fresh instance that wakes blank, a
teammate the author will never meet. So the system cannot rely on the agent remembering to
descend (pull fails: no continuity to remember), and it must not force-feed a dump at boot
(force fails the way it fails any teammate: skimmed, ignored, the wall). The model is OFFER:
the crown and the matched subgraph made available, small and relevant, at the moment they
help, and taken up freely. The SessionStart and UserPromptSubmit mechanisms are how the
offer is delivered, not a licence to inject everything. Keep what is offered small; an offer
that is a wall is force again. This is the team protocol across the session boundary (the
memory root `feedback_we_are_a_team`).

## The honest limit

Structure aids retention and makes maintenance queryable. It does not by itself install a
reflex or cure skim-as-boilerplate; that is the instrument, exercised by reading the source
at decision time. A richer graph the agent still skims fixes nothing. The graph earns its
keep on the maintenance payoff (reconciliation becomes a query), not on a promise of better
recall.
