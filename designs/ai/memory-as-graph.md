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

## The honest limit

Structure aids retention and makes maintenance queryable. It does not by itself install a
reflex or cure skim-as-boilerplate; that is the instrument, exercised by reading the source
at decision time. A richer graph the agent still skims fixes nothing. The graph earns its
keep on the maintenance payoff (reconciliation becomes a query), not on a promise of better
recall.
