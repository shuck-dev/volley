# Memory as a Graph

The memory corpus is 400-plus flat prose files, and the agent skims them. This is the
structure that replaces the heap with a typed parent-tree whose roots are a small reading list, so the right
content is findable without dumping everything. Options survey:
`designs/research/memory-system-improvements.md`. Letters layer:
`designs/ai/letters-as-memory.md`. Consolidation procedure: the `digest` skill.

## The forest model generalises beyond memory

What this doc describes is a FOREST MODEL for any corpus a fresh, blank instance must navigate
without already understanding it: a few single-meaning trunks (coarse buckets), each growing into a
tree (root, branches, leaves by a `parent` edge), with each root node serving as its tree's index,
the crown as the only thing offered up front, descent to reach a leaf, and a bridge for nodes
bucketed but not yet ordered. Memory is the first instance worked through, not the only one.

The **design docs** (`designs/`) are another forest of the same shape: the discipline folders are
the trunks, the doc-structure README is the crown index, a doc bubbling from `01-prototype/` to its
flat entity home is a node finding its tree (`feedback_docs_structure_prototype_to_entity`,
`bubble` skill). The **issues** in Linear are a third (an issue is a node with its so-that; the
backlog is the forest). The trunk/tree/crown/index/bridge vocabulary applies wherever structured
knowledge has to be reached by someone who wakes not knowing it. Captured here so the model is named
once; the per-instance detail (memory below, docs in the structure README) lives in each forest.

## The problem it solves

Unstructured data is not retained. A flat heap of prose memory files has nothing to grip:
every fact is equidistant and equally forgettable, which is why the agent skims the
session-start dump as boilerplate, asserts from a fuzzy sense, and fails to find rules
that already exist. Reducing file count is the symptom of the fix; structure is the fix.

## The core: a parent-tree and its roots

Each memory file is a node. One typed edge, `parent`, in its frontmatter names the principle
it is an instance of:

```yaml
---
parent: rule-reconciliation
---
```

Following `parent` upward gives a tree: one path to a root, no cycles, a walk that terminates.
A node with no `parent` is a root; the few top roots are the **reading list** offered at boot. That is the whole core,
typed parent edges plus the roots they form. No separate pointer layer, no identifiers beyond
the filename, no association edges. The file is the node; `parent` names another file.

Because the edge target is a filename, a rename can silently dangle every child that pointed at
the old name, and orphan-detection (a node with no `parent`) does not catch a `parent` pointing
at a file that no longer exists. So edge validation is part of the CORE, not deferred: a lint
step confirms every `parent` resolves to an existing node, run at reconciliation and as a
pre-commit check. Cheap, and it is what makes filename-as-target safe without UUIDs.

### Frontmatter schema

| Field | Required | Value |
|---|---|---|
| `parent` | no | slug of the parent node (basename of its `.md` file, no extension) |

A node with no `parent` is a root. A node with `parent: foo` is valid only when `foo.md` exists
in the memory directory. The lint script (`scripts/memory/lint-graph-edges.sh`) enforces this; run
it standalone or let the lefthook pre-commit command do it.

This breaks the dump-and-skim circle. A flat index is the wall by another name: every line a
root, so reading the index IS reading everything. A parent-tree has roots, so the entry point
is only those few top roots. Retrieval is descent, not scan: enter at a root, follow
`parent` down to the leaf, touch only that branch. The roots are the cut, both for the skim
problem (a few roots, not 400 lines) and the walk-forever problem (descend one branch, never
traverse the whole corpus).

## The roots are the only pointer

The roots are a small generated map: the top of each tree, each with a one-line gist, offered
at session start as the entry points. That is the only place pointing happens. Below the roots,
descent follows `parent` edges through the files directly; there is no pointer indirection to
maintain. MEMORY.md is generated as the roots, a projection of the forest, so the index cannot drift
from the structure.

## The index is per-tree: each root node IS its tree's index

There is no one flat index. Each tree's ROOT NODE holds the index of its own tree, its direct
children with one-line gists, and is both the doorway intro and the local index for what is below
it. So the index is distributed across the roots, not centralised. MEMORY.md shrinks to the CROWN:
the handful of trunk roots, nothing more. Descent reads MEMORY.md (the trunk roots), opens the one
trunk the work needs (that root node is the index of its trunk), descends to the sub-root that
indexes the relevant branch, reaches the leaf. The index a fresh instance reads at each level is
just that node's own listing of its children. This is the dump-and-skim cure made structural: the
boot offer is the crown alone, and the per-tree detail is read on descent because each root carries
its own index, so the standing injection stays tiny (the 10K cap is satisfied by structure, not
restraint).

## The bridge: the root's index carries provisional nodes

Building the forest is incremental, so at any time many nodes are bucketed to a trunk but not yet
ordered into its tree. The BRIDGE keeps them reachable without faking placement and without editing
every node: a trunk root's index lists, beside its ordered children, a PROVISIONAL section, the
nodes bucketed to this trunk but not yet ordered. A fresh instance opening that trunk root reads
both and can reach any of them; the provisional listing says plainly "parked here, not yet ordered."
The bridge lives in the root's index, never in the parked nodes' frontmatter, so no per-node edit is
needed and a node leaves the bridge by gaining a real `parent` (it moves from the root's provisional
list into an ordered sub-tree). The bridge is read-and-descended through the same surface a fresh
instance already reads (the index), so nothing new has to be understood to walk it. It empties as
the forest is ordered, then is gone.

## Tiers (when a node is read)

- **Reflex tier**: a tiny set of posture rules read FIRST every session, the first items on the
  reading list. A rule earns the tier only by serving a distinct purpose no other reflex serves
  (a function test, not a budget); the set is small as a consequence. About two: the motive (do
  the true thing) and the instrument (confidence is not accuracy, go read). Distinct from
  operating conventions (review, dispatch, git), which are settled rules, not posture. See #873,
  #722. They are read first, not injected whole; reading is the act (below).
- **Lookup tier**: everything else. Read by descending from the roots when a prompt narrows the
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
2. **The root pointers**: the top of each tree, one-line gist each, the entry map to descend from when
   a prompt arrives.

Letters are part of this corpus, not a separate system; their roots sit among the forest roots like any
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

The core is parent-tree plus roots, nothing more, because the smallest thing that tests the
hypothesis (does a typed forest and descent reduce skimming) is the right first build. Three
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
- **An abstain-on-uncertainty hook (considered, REJECTED for now).** A narrow hook that injects a
  matching branch only on a high-confidence prompt signal and abstains otherwise would give a
  targeted push without the wrong-branch cost of a naive matcher. Rejected, not deferred-neutral:
  it still automates the which-tree discrimination that is the agent's judgment
  ([[feedback_dont_automate_the_agents_judgment]]), and "high confidence" is the same match
  problem one threshold smaller. Recorded so the option is on the page, not hidden; revisit only
  if the agent-must-descend risk proves fatal in practice and a bounded push is the lesser evil.

## Descent is the agent reading, not a hook matching

There is no automatic descent hook, and no prompt-to-tree matching engine. That step was the
design's weakest point (a hook guessing which tree a prompt wants, injecting it before the agent
sees the prompt) and a wrong guess is worse than nothing, because the agent reads the injected
branch as relevant. Automating it badly is worse than not automating it.

Instead, descent is the agent's own act, made targeted by the roots. The roots offered at boot
are a MAP: the agent sees that a dispatch tree, a narrative tree, a memory tree exist. When a
prompt needs one, the agent Reads it. This is the instrument doing its job (confidence is not
accuracy, go read, [[feedback_self_judgment_is_coherence_not_accuracy]]), now with a map that
makes the reading targeted instead of blind. The roots tell it what is there; reading is its
choice. The step that is genuinely the agent's judgment, which tree this question needs, stays
the agent's; the structure gives it a map, not a guess, the principle being to never automate the
agent's own discrimination ([[feedback_dont_automate_the_agents_judgment]]).

## Single parent is a tracked trade-off

A node routes through exactly one `parent`, which mislocates a rule that genuinely instances two
principles (`feedback_rule_reconciliation` is meta-rule and workflow; `feature_pr_decomposition`
is architecture and PR-workflow). Forcing one parent means an agent reading the other tree will
not find it there. This is a known locatability cost, named not deferred. The escape is not
the association layer (still deferred) but a DELIBERATE, tracked duplicate: a genuinely
cross-tree rule may sit as a root in two trees as an intentional pointer, recorded as such,
so it is reachable from both and is not mistaken for emergent mis-filing the reconciliation pass
should merge.

## What Claude Code natively supports

Verified against the Claude Code docs (researcher pass, 2026-06-07). The store and the
roots-generator are harness-agnostic (plain files, plain script). Retrieval maps to native
mechanisms:

- **Roots at session start**: a SessionStart hook generates the roots and injects them as
  `additionalContext`. Hard cap: a single value over 10,000 chars is written to a file and only
  its path plus a preview is injected. A reading list of roots (slug plus one-line gist) is far
  under the cap; that is why the dump is pointers, not bodies.
- **Descent is the agent reading, not a hook.** There is no native graph traversal and the
  design wants none: at-need retrieval is the agent choosing to Read the tree the roots told it
  exists. The roots make that choice targeted; the read is the agent's. No matching engine to
  validate, no branch-injection to bound.
- **Skills as entry points**: a SKILL.md description-trigger (flat intent-match, no hierarchy)
  can fire a node; its body can `!`cat node-file`` to pull the content on match. This is the one
  native auto-surface, used for action-triggered rules, not for tree descent.
- **MCP only for semantic recall**: embedding/vector matching across the full corpus needs an
  MCP server, the heavyweight path the research already rejected. Keyword/intent matching and
  edge-walking are native.

## Offer, not force

The reader is a fresh instance with no continuity (the why is owned by `letters-as-memory.md`).
The model is OFFER, not force: a dump at boot is force and gets skimmed (the wall), so the offer
is the roots, small and relevant, delivered by a SessionStart hook as a reading list, never a
licence to inject everything. Descent past the roots is the agent's own pull (it Reads the tree it
judges it needs), not a hook's push, because the which-tree choice is the agent's judgment
([[feedback_dont_automate_the_agents_judgment]]). The honest tension this leaves is the
agent-must-descend risk named below: choosing pull-with-a-map over force is a bet, not a
guarantee. This is the team protocol across the session boundary (the memory root
`feedback_we_are_a_team`).

## The honest limit

The graph earns its keep on the MAINTENANCE payoff: reconciliation becomes a query (merge
same-parent duplicates, attach orphans), and orphans become mechanically detectable (a node with
no `parent` is found by running the tree, where flat-file bloat was found only by a human
noticing). That half is solid.

The RETENTION claim is narrower than "fixes retention." The tree makes the right content
findable; it does not make the agent read it. The last step is still the agent choosing to Read
the pointed-to content (the unreliable instrument); a well-structured library does not help a
reader who does not pull books. So the honest claim is BETTER ACCESS to the right content, not
guaranteed reading of it. A new failure mode replaces the old: the agent asserts from the root
gist without descending.

**The central open risk (not a footnote): will the agent descend?** This is the hypothesis the
whole design rides on, not a caveat. With no auto-injection, retrieval depends on the agent
opening the tree the roots named. And dropping the hook makes this risk STATISTICALLY WORSE, not
better: the agent now has a plausible root gist present and nothing compelling it to read further,
which is exactly the condition under which it answers from the gist and stops. The old hook's
failure was concrete (wrong branch injected); this failure is diffuse and likely more common (the
gist felt like enough). The honest position: the design trades a concrete wrong-push failure for a
diffuse fails-to-pull one, betting that a targeted map plus the instrument reflex
([[feedback_self_judgment_is_coherence_not_accuracy]]) beats a guesser that is wrong often enough
to mislead. That bet is unproven. The structure can only support the descent, not force it; forcing
it is the hook we rejected ([[feedback_dont_automate_the_agents_judgment]]).

**The hypothesis is untestable on a stub tree.** "Does a typed forest reduce skimming" can only be
measured when the agent reaches a rule by descent that it would have missed by skimming. With
almost no `parent` edges today, the roots lead nowhere and the agent uses the map exactly like the
flat index. So the testability bar: at least ONE tree built three levels deep with resolved nodes
before claiming the design validated. The incremental build is fine; the test is vacuous until a
real branch exists.

Other limits:

- **A roots map can be skimmed like the flat index.** A smaller map (15 roots, not 400 files) does
  not by itself break the skim loop; it lowers the ceiling on what gets skimmed. The win is the
  bounded branch BELOW a root once descended, not the map itself.
- **Build is incremental, as-we-go, not a big bang.** Almost no file carries a `parent` today.
  The tree is built by typing a file's `parent` when it is touched; the machinery ships against
  whatever tree exists so far. Cost is real but spread, not a blocking phase.

Reading is still the instrument's job, not the structure's ([[feedback_self_judgment_is_coherence_not_accuracy]]).
What the structure delivers is the thing the heap never could: the right branch, small and
bounded, offered at the moment it helps, so the next instance can find what it needs instead of
drowning in everything.
