# Upgrade Shop

## Goal
Design and implement the player-facing item acquisition UI: a friend's clearance where the player takes items by moving them into a box. The rotation system ensures the right items appear at the right moments without feeling scripted, and the clearance's visible state changes as the friend becomes more distant across Act 1.

**Points:** 5
**Dependencies:** Upgrade Mechanics (item data model), Progression System (FP economy)
**Unlocks:** The Shopkeeper and the Tinkerer (character integration), UX Design (clearance UI pass)

---

## Act structure overview

How the player acquires items changes with each act. The shop is an Act 1 mechanic. Acts 2 and 3 have their own acquisition systems (see The Shopkeeper and the Tinkerer).

| Act | Acquisition method |
|---|---|
| Act 1 | Clearance: taking items from a friend who is moving away |
| Act 2 | Rummaging: going through the friend's leftovers after they moved |
| Act 3 | Partners: significant items gifted by partners |

---

## Clearance unlock

The clearance is not available from game start. It unlocks when the player hits a specific milestone. Before that point the player earns FP but has nowhere to spend it, which creates anticipation. The exact milestone is a narrative and balance decision (see Milestone Design).

**Prototype:** The full milestone system is a Beta feature. For prototype, the clearance unlocks at a hardcoded FP threshold. The threshold is a tuning target for the Make Fun pass; the default starting point is 50 FP. The clearance panel is hidden and the HUD button is absent until this threshold is crossed.

## Narrative framing

The shop is not presented as a shop. It is a friend's clearance: they are moving away and letting you take things from their stuff. The player does not buy items. They move things into a box to take with them. The friend is the shopkeeper character.

FP is still spent per item, but the fiction is about the weight of the ask, not a transaction. A cheap item is easy to take; nobody thinks twice. An expensive one requires deeper trust: the player has to feel comfortable asking for it, and the friend has to feel comfortable letting it go. Mechanically the FP economy is unchanged (per-item costs, idle accumulation, Tinkerer levelling as the ongoing sink). The surface language shifts: "purchase" becomes "take", "cost" becomes the friendship it takes to ask, and the shop panel becomes the clearance scene with the box.

The interaction is diegetic drag-and-drop: the player moves items from the friend's things into a box (see SH-51: diegetic drag-and-drop spike).

---

## Shop display (Act 1)

The shop shows 5 item slots at a time. The player sees the item name, description, and FP cost (presented as friendship required to take it). There is no mechanical description. The player discovers what an item does by owning it.

Items are taken directly from the clearance by dragging them into the box. Taken items are added to the player's inventory immediately and their effects apply from that moment. Each item can only be taken once. Owned items are excluded from the rotation.

When a player destroys an item, a second chance version of that item enters the current act's pool: same effects, a variant of the original name, same sprite with a shader applied (see Upgrade Mechanics: Item Variants). In Act 1 it re-enters the clearance rotation normally. In Act 2 it surfaces through rummaging the friend's leftovers, which is narratively appropriate: you got rid of something and then find something like it while going through what they left behind. If the second chance version is also destroyed, that item is removed from all pools permanently.

The clearance is accessible from the HUD at any time. The game continues running behind it. No pause.

---

## Shop refresh

The shop refreshes when both triggers have fired:

1. **Session start.** A refresh is queued when the player opens the game.
2. **Timer.** A background timer fires after a set interval while the game is running. Tune interval during Make Fun pass.

Both conditions must be satisfied before the rotation changes. Opening and immediately closing the game does not grant a new rotation -- the timer must also have elapsed. This prevents the player from farming new stock by restarting. An idle player who returns after the timer has run will see new stock as soon as they open the game.

---

## Idle economy and item cost

**Open problem.** FP accumulates during idle play. If item costs are too low relative to idle FP rates, the player can passively afford items without engagement, draining the clearance without the decision-making that makes taking feel meaningful.

The rotation already limits access (the player can only take what is currently displayed), which helps. But item costs must be tuned high enough that idle FP represents meaningful progress toward taking an item, not trivial pocket change. This is a Make Fun pass tuning target.

One mitigation: levelling items at the Tinkerer is the primary ongoing FP sink. Taking a new item is a decision; levelling it to max is the sustained investment. If levelling costs are appropriately steep, the economy remains meaningful even when idle FP builds up.

---

## Rotation system

The shop rotation is not random: it is shaped by four layers that work together silently.

### Layer 1: Act-gated pools

Items belong to one of four pools: `"act1"`, `"act2"`, `"act3"`, `"peace"`. Each pool unlocks at the start of its act. The rotation can only draw from unlocked pools. New pools entering the rotation makes the shop feel changed without the change being explicitly announced.

### Layer 2: Paired gravity

When the player owns a max-level item that has a synergy partner (Beta), that partner's weight in the rotation is elevated. The player does not see this. They notice that the other item tends to appear once they have maxed its pair -- which is when they are ready to attempt a synergy anyway.

The elevation lasts for three rotation cycles, then resets. If the player purchases the partner, gravity clears immediately.

In prototype, this layer is implemented but has no visible effect until synergy pairs are authored in Beta.

### Layer 3: Friend's pick slot

One of the five slots is reserved as the friend's pick: something they set aside for you specifically. This slot is filled by authored selection rather than the weighted random pool. It is the primary channel for ensuring narratively significant items surface at the right moment.

Use the pick slot for:
- Items that carry the heaviest signal layer and benefit from appearing at a specific story beat
- One half of a synergy pair the player should have access to

As the friend becomes more distant across Act 1, the pick slot is the first thing that changes. They stop setting things aside. The slot enters the general rotation. This is the earliest mechanical sign that something is shifting.

### Layer 4: Discovery floor

Every three rotation cycles, at least one slot must contain an item the player does not own that belongs to a synergy pair they have not yet discovered (if any such items are available in the current pool). Silent guarantee against long periods with no synergy progress visible.

This floor activates only if the normal rotation would otherwise produce a cycle with no synergy-relevant items. It is not visible to the player.

### Layer 5: Safety net item

One item per act pool is designated as the safety net item. It never appears in normal rotation. It surfaces only when both conditions are true simultaneously: the player owns no items and the available pool is otherwise empty (all items owned, destroyed, or unavailable). It is a last resort, not a shortcut. Once taken it leaves the safety net slot and the player is back in the normal system.

The safety net item should be cheap and mechanically neutral: something that gets the player moving again without being a meaningful upgrade.

When the pool is empty and the player has 2 or fewer items (but not yet zero), the Tinkerer or the friend delivers a condition-based hint nudging the player toward clearing their remaining items. See The Shopkeeper and the Tinkerer: Scorched Earth Hint.

---

## Probability of finding a new synergy

With 50 items and 25 synergy pairs, there are C(50,2) = 1,225 possible combinations. The base discovery rate per new attempt is 25/1,225 = 2.0%.

In practice with ~12 items owned, the accessible combination space is C(12,2) = 66 pairs. If 3-5 synergies exist within those pairs, the effective discovery rate on owned items is 5-8%. Paired gravity pushes this higher for items with known synergy partners.

The real pacing lever is the rotation, not the ratio.

---

## Clearance winding down (Act 1)

As the friend becomes more distant, the clearance thins and eventually ends. The friend is moving away; there is less left to give. The sequence is tied to story beats, not timers:

1. **Pick slot goes quiet.** The friend stops setting things aside for you. The slot enters general rotation. Still 5 items; the selection just feels less intentional.
2. **Less stuff left.** Fewer new items appear. Repeats increase.
3. **Slot count drops.** 5 → 4 → 3 items displayed.
4. **They've gone.** The clearance is over. The friend has moved away.

The winding down should be felt before it completes. When it finally ends it should not feel surprising.

---

## Act 2: Rummaging

The clearance is over. The friend has moved away. The player discovers Act 2 items by rummaging through what the friend left behind: things that did not fit in the move, things they chose not to take, things that were too heavy to carry for reasons that were not about weight. Going through them is holding on.

Mechanically: the player initiates a rummage action (once per session, or on a timer, mirrors the clearance refresh model). Each rummage surfaces one item from the Act 2 pool. The item can be taken with FP or passed over. Passing does not mean it is gone; it may surface again in a future rummage.

The Tinkerer is still available throughout Act 2 for levelling and synergy attempts.

---

## Act 3: Partner gifts

The clearance is long over. Partners give the player significant items as the act progresses: not as drops, but as deliberate gifts tied to relationship moments. These items still cost FP (the partner gives you the item, you give what it is worth to you and to them). The exchange is relational, not transactional.

New synergies discovered in Act 3 are brought to the friend or Tinkerer once they have been won back. The act of bringing the item to them is part of the reconciliation, not separate from it.

---

## Open questions

- Rummage timer interval: once per session is the minimum. Does a background timer also apply as with the clearance? (Probably yes, for consistency.)
- What does the clearance look like when it has fewer than 5 items as the friend winds down? (Gaps visible, or reflow? UX Design pass decision.)
- How are partner gifts triggered in Act 3: milestone-gated, relationship-level-gated, or both?
