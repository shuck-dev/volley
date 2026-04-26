# The Shopkeeper and the Tinkerer

## Who they are

**The Shopkeeper** is the main character's projection of someone they pushed away. The friend who tried to help after the best friend died and got shut out. What runs the shop is the main character's constructed idea of that person: their warmth, their enthusiasm, their slightly-too-eager-to-please energy. It is an act of love and denial at the same time.

The shop closing is not the shopkeeper withdrawing. It is the main character's projection losing coherence. The warmth drains because the main character can no longer sustain the fiction. After the break, the player understands this.

**The Tinkerer** is quieter, more guarded, more precise. They do not make small talk. They see more than the Shopkeeper and more than the partners, but they are muted in reaction. They do not push. They simply know, and occasionally, carefully, let something of that knowing show.

The Tinkerer's relationship to the shopkeeper and the main character in reality is an open question for the writing pass.

---

## Their role in the upgrade systems

The Shopkeeper runs the item shop in pre-break. The player buys items from their projection using FP.

Both the Shopkeeper and the Tinkerer are unlocked via progression thresholds in the Progression Manager. The shop unlocks first. The Tinkerer unlocks later.

**Prototype:** Both unlocks are defined in ProgressionConfig. The shop unlocks first (default: 50 FP); the Tinkerer unlocks later (default: 150 FP). Both are tuning targets.

The Tinkerer does three things in pre-break:

**Item levelling.** The player brings an owned item and pays FP to level it up. Items have 3 levels: base, upgraded, max. Each level increases the item's effect magnitude. The Tinkerer does not comment on levelling beyond confirming the work is done.

**Item destruction.** The player can ask the Tinkerer to destroy an owned item. This removes it from the inventory, reverting all effects. Partial FP refund. A second chance version quietly re-enters the pool (different name, same sprite with shader, same effect). The Tinkerer does not tell the player this. If the second chance is also destroyed, the item is gone for the run.

The Tinkerer has one line per item for destruction. They know what each item is.

**Synergies (content update).** The player brings two max-level items; the Tinkerer attempts to combine them. If a synergy exists, they produce it for a fee. If not, the attempt is free. The Tinkerer has one line per failed synergy pair. Their dialogue triggers across the game are destruction and failed synergy. Everything else is silent.

---

## Pre-break

The Shopkeeper's projection is present, enthusiastic, slightly too eager. They curate the pick slot from the narrative item pool. They notice what the player buys and the rotation quietly reflects it.

Their dialogue on entry shifts as the player progresses. Early: warm and comfortable. Later: still warm but with something underneath. References that don't quite fit the surface framing.

The Tinkerer is available for levelling and destruction. More guarded, more precise. Levelling is silent. They only speak about a specific item when the player destroys one.

### Shop closing

The shop deteriorates in stages tied to progression:

1. **The Shopkeeper stops curating.** The pick slot enters the main pool. Still open, still friendly, but the intentionality is gone.
2. **Stock thins.** Fewer new items, more repeats.
3. **Hours reduce.** Fewer display slots.
4. **Closed.** No announcement. The door is just not open anymore.

The surface read: the Shopkeeper is holding resentment. The truth: the projection is losing coherence.

---

## Post-break

The shop is closed. The main character told themselves the shopkeeper moved away. The Tinkerer is still there.

The player discovers post-break items by rummaging through old boxes, remnants of what the projection left behind. Mechanically: once per session (plus a background timer), a rummage surfaces one post-break item for potential purchase.

The Tinkerer does not comment on the rummaging directly. Their workshop is adjacent. They are aware.

---

## Peace

The shopkeeper is back. What form this takes in the pong world is an open question. The Tinkerer is still there. Synthesis becomes available: the Tinkerer can construct a synth version of any item the player doesn't own, including permanently destroyed items. Synth items are mechanically identical, visibly constructed.

---

## The Tinkerer's relationship system

Relationship level increases through visits: levelling, destruction, synergy attempts, story beats. It does not decrease.

Three tiers. Each tier unlocks a more candid layer of entry dialogue. This is the only thing relationship gates. The Tinkerer does not become more helpful mechanically; they become more present.

---

## Item destruction as narrative delivery

When a player destroys an item, the Tinkerer's response is the content. They know what the item is. Their destruction dialogue is the heaviest single-item writing in the game.

The surface read: they've dismantled it and return what FP they can. Underneath: something about what it meant to hold onto it, or what it means to let it go.

Destruction dialogue is written for every item: one line each. Guaranteed to fire exactly once per item.

---

## Tone notes

The Shopkeeper's warmth is genuine, even as a projection. It is the main character's truest memory of that person.

The Tinkerer is precise, occasionally dry, occasionally kind. They see more than anyone else and say less. Their lines land harder because they arrive less often and with no softening.

None of these characters should be written as tragic. They are doing what people do.

---

## Open questions for writing pass

- What does the shopkeeper's return in Peace look like in the pong world?
- How many entry dialogue beats does the shopkeeper have across pre-break?
