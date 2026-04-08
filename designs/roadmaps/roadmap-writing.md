# Volley Vendetta - Writing Roadmap

```mermaid
timeline
    title Writing Roadmap

    Alpha
        : World and Narrative
        : Partner Writing
        : Item Writing

    Beta
        : The Break Writing
        : Post-Break
        : Peace

    Content Updates
        : Copy Pass
```

Writing lands alongside the content it supports. Partner writing ships with each partner. Item writing ships with each item. There are no standalone writing deliverables that exist in isolation from the thing they describe.

## Alpha

**World and Narrative** establishes the underlying layer: lore, characters, setting, tone, and the shape of the clue ladder. Includes the high-level break design so Beta can implement without waiting. This is the foundational document that everything else in writing references.

**Partner Writing** ships with each pre-break partner: name, personality, backstory, barks (pre-break line sets), and bio. Each partner's ordinary name directly references a person who affected the main character in their reality. Post-break partners and post-break line sets ship in Beta.

**Item Writing** ships with each pre-break item: descriptions (default, power revealed, narrative revealed variants) and the Tinkerer's commentary. Post-break items ship in Beta.

## Beta

**The Break Writing** covers the reveal moment. One specific truth, clearly committed to. The highest-stakes writing in the game.

**Post-Break** covers the shifted bark line sets, post-break partner and item writing, and any changed copy. Same voices, different weight.

**Peace** covers partner barks and copy for the post-game state: warmer, quieter, settled.

## Dialogue system tooling

The game has heavy dialogue requirements: Tinkerer destruction lines (one per item), synergy failure lines (~490 pairs), Shopkeeper entry dialogue that shifts across Act 1, partner banter, and the signal-layer clue ladder. Before Narrative Scripting begins, evaluate **Dialogic** (AssetLib) as the dialogue runtime. It handles branching dialogue, character portraits, timeline-based sequences, and conditional line selection, which maps well to the tier-gated and condition-based dialogue described in The Shopkeeper and the Tinkerer design. The alternative is a bespoke system, which may be simpler for this game's mostly single-line-per-trigger pattern but would need to be built.

---

## Content Updates

**Copy Pass** covers general in-game text, UI copy, and any remaining written content that needs polish.
