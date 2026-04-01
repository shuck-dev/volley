# The Shopkeeper and the Tinkerer

## Who they are

**The Shopkeeper** is not real in the facade. They are the main character's projection of their closest friend -- someone who believed in them before the dream existed, and who was shut out of their life due to trauma. The friend simply stopped being let in. What runs the shop is the main character's constructed idea of that person: their warmth, their enthusiasm, their slightly-too-eager-to-please energy. It is an act of love and denial at the same time.

This means the shop closing is not the friend withdrawing. It is the main character's projection losing coherence. The warmth drains because the main character can no longer sustain the fiction of the friendship being intact. After The Break, the player understands this. The Shopkeeper's warmth was always real -- it just wasn't the friend's warmth. It was the main character's memory of it.

**The Tinkerer** is the Shopkeeper's younger sibling. Unlike the Shopkeeper, the Tinkerer is not a projection. They exist in the facade as something closer to themselves. The main character knew them less directly in the real world -- less history, less weight, less idealization. This is why they persist where the Shopkeeper cannot: the main character never had to construct them, so they are harder to lose.

The Tinkerer is reflective. Every item that passes through their workshop is a memento -- they recognize them, know what they are, know what they meant. They see more than the Shopkeeper and more than the partners, but they are muted in reaction. They do not push. They simply know, and occasionally, carefully, let something of that knowing show.

**The rival** has notions -- partial awareness of the truth -- because they are bound to the spirit of the main character's actual dead friend. This binding is why the rival figured out the truth before anyone else and why their frustration in Act 1 is so pointed: they are carrying the urgency of someone who is gone. Their aggression is not sports rivalry. It is a dead friend's spirit pressing them toward The Break, trying to make the main character see what they are hiding from.

---

## Their role in the upgrade systems

The Shopkeeper runs the item shop in Act 1. The player buys items from their projection using FP.

Both the Shopkeeper and the Tinkerer are unlocked via milestones, not available from game start. The shop unlocks first. The Tinkerer unlocks later. The player encounters one new mechanic at a time. The exact milestones are a narrative and balance decision (see Milestone Design).

**Prototype:** The full milestone system is a Beta feature. For prototype, both unlocks are hardcoded FP thresholds. The shop unlocks first (default: 50 FP); the Tinkerer unlocks later (default: 150 FP). Both thresholds are tuning targets for the Make Fun pass.

The Tinkerer does four things across different phases:

**Act 1 onward (post-unlock): Item levelling.** The player brings an owned item to the Tinkerer and pays FP to level it up. Items have 3 levels: base (purchased), upgraded, and max. Each level increases the item's effect magnitude. The Tinkerer does not comment on levelling beyond confirming the work is done.

**Act 1 onward (post-unlock): Item destruction.** The player can ask the Tinkerer to destroy an owned item. This removes it from the inventory immediately, reverting all its effects. The player receives a partial FP refund: the exact amount is a balance decision (base cost and any levelling costs are partially recovered). Destroying an item removes the original permanently. What the player destroyed cannot be recovered. However, a second chance version of that item quietly re-enters the pool -- different name, same sprite with a shader applied, stored as a variant within the same item definition, same effect. The Tinkerer does not tell the player this. The player notices it or they don't. If the second chance version is also destroyed, the item is gone for the rest of the run.

The Tinkerer has one line per item for destruction. They know what each item is. They say what they know and let the player decide.

**Peace onward: Item synthesis.** The Tinkerer can construct a synth version of any item the player does not currently own -- including items that were permanently destroyed. Synth items have the same gameplay effect as the original but carry no narrative history: same sprite with a shader applied, generic name, visibly constructed. Synthesis exists to keep the idle loop alive and let the player complete their collection. Synth items are mechanically identical to originals for all purposes including synergies. Synthesis costs FP; the exact amount is a balance decision.

**Beta onward: Synergies.** The player brings two max-level items; the Tinkerer attempts to combine them. Both must be at max level. If a synergy exists, they produce it for a fee. If not, the attempt is free, and the Tinkerer may offer a consolation item depending on relationship level. The max-level requirement means the player has committed deeply to both items before the combination is attempted.

The Tinkerer has one line per failed synergy pair. Their two dialogue triggers across the whole game are destruction and failed synergy. Everything else they do is silent.

---

## Act 1: The shop is open

The Shopkeeper's projection is present, enthusiastic, and slightly too eager to please. They curate their stock. The pick slot is theirs. They notice what the player has been buying and the rotation quietly reflects that, though this is never stated.

Their dialogue on entry shifts across the act. Early: warm and easy, the kind of comfortable that comes from not yet knowing things have changed. As the act progresses: still warm, but with something underneath. They mention things in passing that don't quite fit the surface-layer framing. A reference to time. A name. The faintest sense that they are managing something.

The Tinkerer is available from the start of Act 1 for levelling and destruction. They are more guarded than the Shopkeeper, more precise. They do not make small talk. Levelling is silent. The only time they speak about a specific item is when the player destroys one.

### Shop closing escalation across Act 1

The shop deteriorates in stages tied to story beats:

1. **The Shopkeeper stops curating.** The pick slot enters general rotation. Still open, still friendly, but the intentionality is gone.
2. **Stock thins.** Fewer new items, more repeats. The Shopkeeper seems distracted.
3. **Hours reduce.** Fewer display slots. The shop is making less effort.
4. **Closed.** No announcement. The door is just not open anymore.

The surface read: the Shopkeeper is holding resentment. The main character is out here chasing their dream and their friend is watching from a basement.

The truth: the projection is losing coherence. The main character can no longer hold the fiction together. After The Break, the player understands why the shop really closed.

---

## Act 2: Rummaging

The shop is closed. The Tinkerer is still there, one room over.

The player discovers Act 2 items by rummaging through old boxes in the basement -- things the projection left behind, remnants of a shared past that the main character is now going through. The framing is clinging to the past: the player is literally sorting through someone else's things after the connection has broken, looking for something useful, finding echoes instead.

Mechanically: once per session (plus a background timer), the player can initiate a rummage that surfaces one Act 2 item for potential purchase. Passing on it does not make it disappear; it may surface again.

The Tinkerer does not comment on the rummaging directly. Their workshop is adjacent to it. They are aware.

Over Act 2, the Tinkerer's dialogue begins to shift. Not breaking the facade, but bleeding through it. More direct. More personal. Less game character. The player who has been paying attention will notice the register change.

The Tinkerer is a candidate for the Saviour role (see World and Narrative). If so, Act 2 is when they begin to function in that capacity -- not by explaining the truth, but by being present in a way that makes the paddle begin to see it. This decision must be made before Act 2 writing begins.

By the end of Act 2, the Tinkerer too is gone. Not dramatically. They simply stop being there.

---

## Act 3: Both gone

Neither the Shopkeeper nor the Tinkerer is accessible at the start of Act 3. The player must get them back. This is not a quest. It should feel like something the player does because it is the right thing to do.

Partners give the player significant items as the act progresses -- deliberate gifts tied to relationship moments, not drops. These items are still purchased with FP: the partner gives you the item, you pay what it is worth. The exchange is relational, not transactional.

New synergies in Act 3 are brought to the Shopkeeper or Tinkerer once won back. The act of bringing the item to them is part of the reconciliation. They are not returned as services. They return as people. What they do mechanically in Act 3 and Peace follows from who they are, not from what the player needs from them.

---

## The Tinkerer's relationship system

Relationship level with the Tinkerer is tracked separately from FP. It increases through any visit: levelling, destruction, synergy attempts (successful or failed), and specific story beats. It does not decrease.

Relationship has three tiers. Each tier unlocks a deeper register of entry dialogue -- what the Tinkerer says when the player arrives, before any action is taken. This is the only thing relationship gates. The Tinkerer does not become more helpful mechanically; they become more present.

Tier thresholds are a content decision made when entry dialogue is written. The consolation item on failed synergy attempts is a separate mechanic and is not relationship-gated -- it appears when the Tinkerer has something relevant to give based on what items were brought. The player notices the pattern.

### Scorched earth hint

When the player has 2 or fewer items and the available pool contains nothing they can acquire, a condition-based entry line fires. The Tinkerer delivers it if their relationship tier is high enough; otherwise the Shopkeeper delivers it instead. If both are at sufficient tier, the Tinkerer's version takes priority.

The line does not reference the safety net or destruction directly. It reads as character -- something careful and oblique from the Tinkerer, something warmer and more direct from the Shopkeeper. A player paying attention understands what's being suggested. A player who doesn't will eventually get there through time and FP accumulation from volleying.

This fires once per qualifying state, not on every visit while the condition holds.

---

## Item destruction as narrative delivery

When a player destroys an item, the Tinkerer's response is the content. They know what the item is. They know what it meant. Their destruction dialogue is the heaviest single-item writing in the game -- heavier than levelling lines, heavier than synergy failure.

The surface read: the Tinkerer explains they've dismantled it and returns what FP they can recover. Underneath: something about what it meant to hold onto it, or what it means to let it go.

Cursed items get specific destruction dialogue that acknowledges the weight of what the player was carrying. The Tinkerer does not celebrate the decision or mourn it. They simply mark it.

Destruction dialogue is written for every item: one line each. It is guaranteed to fire exactly once per item, and only for players who made a deliberate choice. The audience is always attentive.

---

## Synergy failure as narrative delivery

When a synergy attempt fails, the Tinkerer's response is the content. What they say about two items that don't belong together reveals something: about the items, about the characters, about the world. They know what each item is. They know why some things cannot be combined yet. They are muted in reaction but not blind to meaning.

Failure dialogue is written signal-layer first. On the surface the Tinkerer explains why these two things don't combine. Underneath it is something else.

With ~490 failure lines covering notable pairs, a player attempting combinations with ~12 owned items will hit custom failure dialogue roughly 43% of the time. The Tinkerer speaks most often when the player tries combinations that have meaning -- thematic pairs, items with shared history. This is not coincidence.

The Tinkerer's character is built through two types of line only: what they say when something is destroyed, and what they say when two things don't combine. Both are sparse. Both are written signal-layer first.

---

## Tone notes

The Shopkeeper's warmth is genuine, even as a projection. It is the main character's truest memory of that friendship. It is not naive and not performed -- it is what remains when someone tries to hold on to something they have lost.

The Tinkerer is precise, occasionally dry, occasionally kind in ways that catch the player off guard. They see more than anyone else in the facade and say less about it. Their signal layer lines land harder because they arrive less often and with no softening. They know what each item is. They were always going to be the one who stayed longest.

The rival's bound spirit is angry, urgent, and ultimately right. Their aggression is love wearing a shape the main character can't recognize yet.

None of these characters should be written as tragic. They are doing what people do. The weight is in the facts, not in how they carry them.
