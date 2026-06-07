# Memory as a Graph

The memory corpus is 400-plus flat prose files, and the agent skims them. This is the
structure that replaces the heap with a typed parent-tree and a small crown, so the right
content is findable without dumping everything. Options survey:
`designs/research/memory-system-improvements.md`. Letters layer:
`designs/ai/letters-as-memory.md`. Consolidation procedure: the `digest` skill.

## The problem it solves

Unstructured data is not retained. A flat heap of prose memory files has nothing to grip:
every fact is equidistant and equally forgettable, which is why the agent skims the
session-start dump as boilerplate, asserts from a fuzzy sense, and fails to find rules
that already exist. Reducing file count is the symptom of the fix; structure is the fix.

## The core: a parent-tree with a crown

Each memory file is a node. One typed edge, `parent`, in its frontmatter names the principle
it is an instance of:

```yaml
---
parent: rule-reconciliation
---
```

Following `parent` upward gives a tree: one path to a root, no cycles, a walk that terminates.
A node with no `parent` is a root; the few top roots are the **crown**. That is the whole core,
typed parent edges plus the crown they form. No separate pointer layer, no identifiers beyond
the filename, no association edges. The file is the node; `parent` names another file.

Because the edge target is a filename, a rename can silently dangle every child that pointed at
the old name, and orphan-detection (a node with no `parent`) does not catch a `parent` pointing
at a file that no longer exists. So edge validation is part of the CORE, not deferred: a lint
step confirms every `parent` resolves to an existing node, run at reconciliation and as a
pre-commit check. Cheap, and it is what makes filename-as-target safe without UUIDs.

This breaks the dump-and-skim circle. A flat index is the wall by another name: every line a
root, so reading the index IS reading everything. A parent-tree has a crown, so the entry point
is only the few top roots. Retrieval is descent, not scan: enter at a crown root, follow
`parent` down to the leaf, touch only that branch. The crown is the cut, both for the skim
problem (a small crown, not 400 lines) and the walk-forever problem (descend one branch, never
traverse the whole corpus).

## The crown is the only pointer

The crown is a small generated map: the top roots, each with a one-line gist, offered at
session start as the entry points. It is the only place pointing happens. Below the crown,
descent follows `parent` edges through the files directly; there is no pointer indirection to
maintain. MEMORY.md is generated as the crown, a projection of the tree, so the index cannot drift
from the structure.

## Tiers (when a node is read)

- **Reflex tier**: a tiny set of posture rules read FIRST every session, the first items on the
  reading list. A rule earns the tier only by serving a distinct purpose no other reflex serves
  (a function test, not a budget); the set is small as a consequence. About two: the motive (do
  the true thing) and the instrument (confidence is not accuracy, go read). Distinct from
  operating conventions (review, dispatch, git), which are settled rules, not posture. See #873,
  #722. They are read first, not injected whole; reading is the act (below).
- **Lookup tier**: everything else. Read by descending from the crown when a prompt narrows the
  work.

## What session start offers: a reading list

Nothing in the start dump is injected whole. Everything is a POINTER, and the dump is a reading
list the fresh instance works top to bottom as its first act. No resident exception, not even the
reflex tier: injecting a body whole is force and does not install it anyway (the letters proved
that, and so did a missed concision rule), so even the most important rule is a pointer that is
READ, never force-fed. Reading the list is the act; a pointer sat in the buffer is unread.

The list, in order:

1. **The reflex pointers**: the two posture reflexes, read first because they shape every move
   before any prompt narrows the work.
2. **The crown pointers**: the top roots, one-line gist each, the entry map to descend from when
   a prompt arrives.

Letters are part of this corpus, not a separate system; their roots sit in the crown like any
other, the recent/band/digest gradient being their loading property (owned by
`letters-as-memory.md`, an instance of this design). What is never in the dump: any body. Bodies
are read on the reach, reflex bodies first as the opening of the list, lookup bodies when a prompt
descends to them.

This is why the dump stays under the 10K injection cap with room to spare: a reading list of
pointers (a slug and a one-line gist each) is tiny, where a list of bodies is the wall. The cap
is not a constraint the design fights; it is satisfied by the dump being pointers, not content.

## A worked branch

Discovery as a development process, one mid-root and its branch:

```
discovery (you do not know up front; the doing teaches you, correct the structure to match)
|- formal    the lifecycle stage: discovery issue -> spike (design+tech) -> feature tickets
|- informal  constant learning-by-doing, too small to ticket; correct as you go
             (reconciliation is this, applied to the memory surface)
```

## Maintenance is graph upkeep

Reconciliation is discovery applied to the memory surface: doing the work, you find two
fragments are one principle, so you correct the structure. The typed tree makes the calls
queryable: a node with no `parent` is an orphan to attach; two nodes under the same parent that
say the same thing merge to one (and the surface shrinks); a node whose name encodes a retired
idea gets renamed. It runs continuously as-you-go (informal) and as a periodic deep read (the
`digest` for letters; the dream or auto-consolidation pass for the corpus, #722). Better
maintenance is better retention, not tidiness.

## Deferred until the problem appears

The core is parent-tree plus crown, nothing more, because the smallest thing that tests the
hypothesis (does a typed crown and descent reduce skimming) is the right first build. Three
elaborations were considered and deferred, each to be added only when a real problem calls for
it, not designed-for in advance:

- **Stable identifiers (UUIDs) instead of filenames as edge targets.** Solves rename-cascade.
  Deferred: the core edge-validation lint catches a dangling `parent` after a rename (it does
  not silently corrupt), so filename targets are safe enough. Add UUIDs when rename churn makes
  the grep-repoint genuinely painful, not before.
- **An association layer (`relates-to` cross-edges, not routed).** Richer than a strict tree.
  Deferred: it is never walked for retrieval, so it earns nothing until association is shown to
  help. The single-parent locatability cost is meanwhile handled by the tracked-duplicate escape
  above, not by this layer.
- **Cascading resolution (leaf plus its ancestry, shared ancestors once).** A leaf carries more
  meaning with its principle chain. Deferred: it is an optimization on descent; validate descent
  first.

## Matching: the seed

Descent needs a seed, the node a prompt enters at, and that seed is the engine, not a future
elaboration: a crown and a tree with no match step is shelves and an unindexed catalogue. The
baseline is deliberately crude and specified, not deferred: keyword match of the prompt against
each node's slug and first line, take the best-scoring node as the seed, and on a tie or a
below-threshold score fall back to offering the CROWN rather than a confident wrong branch. A
cross-domain prompt (touching two branches) seeds both and offers both branches if they fit the
cap, else the crown. This is the same keyword instrument the correction-signal hook uses, so its
precision is the residual risk (below), but the engine exists from day one.

## Single parent is a tracked trade-off

A node routes through exactly one `parent`, which mislocates a rule that genuinely instances two
principles (`feedback_rule_reconciliation` is meta-rule and workflow; `feature_pr_decomposition`
is architecture and PR-workflow). Forcing one parent means a prompt matching the other branch
will not descend to it. This is a known locatability cost, named not deferred. The escape is not
the association layer (still deferred) but a DELIBERATE, tracked duplicate: a genuinely
cross-branch rule may sit under two crown branches as an intentional pointer, recorded as such,
so it is reachable from both and is not mistaken for emergent mis-filing the reconciliation pass
should merge.

## What Claude Code natively supports

Verified against the Claude Code docs (researcher pass, 2026-06-07). The store and the
crown-generator are harness-agnostic (plain files, plain script). Retrieval maps to native
mechanisms:

- **Crown at session start**: a SessionStart hook generates the crown and injects it as
  `additionalContext`. Hard cap: a single value over 10,000 chars is written to a file and only
  its path plus a preview is injected. Keep the crown to the top roots only.
- **Descent is done by a hook, not by me live.** There is no native graph traversal; at-need
  retrieval natively is only (MEMORY.md head at start) + (skill description match) + (the agent
  choosing to Read, the unreliable instrument). The automated form is a UserPromptSubmit hook
  that walks `parent` edges from the matched node and injects that branch before the prompt
  reaches me. The walk terminates (visited-set, one branch) and stays bounded (the branch, not
  the corpus), under the same 10K cap.
- **Skills as entry points**: a SKILL.md description-trigger (flat intent-match, no hierarchy)
  can fire a node; its body can `!`cat node-file`` to pull the content on match.
- **MCP only for semantic recall**: embedding/vector matching across the full corpus needs an
  MCP server, the heavyweight path the research already rejected. Keyword/intent matching and
  edge-walking are native.

## Offer, not force

The reader is a fresh instance with no continuity (the why is owned by `letters-as-memory.md`).
Two failures follow: pull fails (nothing remembers to descend) and force fails (a dump at boot
is skimmed, the wall). The model is OFFER: the crown and the matched branch made available,
small and relevant, at the moment they help, and taken up freely. SessionStart and
UserPromptSubmit are how the offer is delivered, not a licence to inject everything; an offer
that is a wall is force again. This is the team protocol across the session boundary (the memory
root `feedback_we_are_a_team`).

## The honest limit

The graph earns its keep on the MAINTENANCE payoff: reconciliation becomes a query (merge
same-parent duplicates, attach orphans), and orphans become mechanically detectable (a node with
no `parent` is found by running the tree, where flat-file bloat was found only by a human
noticing). That half is solid.

The RETENTION claim is narrower than "fixes retention." The tree makes the right content
findable; it does not make the agent read it. The last step is still the agent choosing to Read
the pointed-to content (the unreliable instrument); a well-structured library does not help a
reader who does not pull books. So the honest claim is BETTER ACCESS to the right content, not
guaranteed reading of it. A new failure mode replaces the old: the agent asserts from the crown
gist without descending.

Limits the design has not closed:

- **Matching quality is the residual risk.** The baseline above gives descent an engine, but
  match precision is still the make-or-break: a mis-seed injects the wrong branch, worse than
  nothing because the agent reads it as relevant. The spike validates precision on real prompts
  and tunes the ambiguity threshold; the floor is the crown-fallback, never a confident wrong
  branch.
- **Truncation can manufacture false completeness, worse than the heap.** A deep or wide branch
  blows the cap, and a truncated branch is more dangerous than a dump: the agent sees what looks
  like a complete principle chain and draws confident conclusions from an incomplete premise,
  where the heap at least let it see everything. The spike must set a depth limit and a
  truncation rule that marks a branch as truncated (unresolved tail shown by name), so the agent
  never reads a partial chain as the whole.
- **Build cost is weeks, not an afternoon.** Almost no file carries a `parent` today. Typing
  400-plus means reading each, deciding its parent, and resolving the duplicates that surfaces
  (decisions, not mechanical adds).

Reading is still the instrument's job, not the structure's ([[feedback_self_judgment_is_coherence_not_accuracy]]).
What the structure delivers is the thing the heap never could: the right branch, small and
bounded, offered at the moment it helps, so the next instance can find what it needs instead of
drowning in everything.
