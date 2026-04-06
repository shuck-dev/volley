# Kit and Locker

How items are organised, equipped, and managed. Defines the kit (active loadout), the locker (bench), court items, ball behaviour, passive FP, and item destruction.

---

## Kit and locker

All owned items are either in the kit or in the locker. The kit is what's active: causality effects and stat modifiers only fire from equipped kit items. The locker is everything else. Any item not in the kit sits in the locker and generates passive FP.

There is no "locker item" category. Every item can be in the kit or the locker. The player decides what to equip based on what they need. An item in the locker is still valuable because of passive FP generation.

Start with 3 kit slots; slots can be expanded by court items. Swapping kit items is allowed at any time but costs FP and triggers a per-slot cooldown. Both the FP cost and cooldown duration are Make Fun Pass tuning targets. The combined cost means swapping is a real decision without being a hard lock.

---

## Permanent and temporary balls

Some items are physically balls (Training Ball, The Stray). Equipping a ball item in the kit places a permanent ball on the court. The ball count matches the number of ball items in the kit. Unequipping or lockering a ball item removes its permanent ball from the scene.

Item effects that spawn balls (e.g. The Stray's frenzy) create temporary balls on top of the permanent count. Temporary balls are cleared by their expiry condition (miss during frenzy, etc.). The permanent balls remain.

Example: Training Ball + The Stray in kit = two balls on court at all times. Frenzy triggers on personal best, spawning additional temporary balls. Miss during frenzy clears the temps, back to two.

---

## Court items

No slot cost. Active without occupying a kit slot. Visually present on the court rather than in the kit bag. Can be lockered or destroyed like any other item.

Some court items expand kit slot count. These are early priority purchases: meta-progression that unlocks more active capacity.

Destroying a court item at the Tinkerer is a heavy decision and carries the heaviest Tinkerer dialogue.

---

## Locker and passive FP

All owned items generate FP passively while in the locker. Rate scales with item cost or level -- investing in an item makes it a better bench earner even if it is never equipped. This gives every purchase value beyond its active effect and sustains the idle economy when the kit is locked in.

### Surface layer

Your gear earns FP just by being yours. You packed it, you own it, you care for it. A well-stocked locker is a kit that works for you even when you're not on the court. The bench contributes.

Passive FP is communicated through sound, not visuals. Late game the locker can be generating significant FP -- visual pops would become noise. Instead: a gentle ambient audio texture that grows denser as the locker fills. Not louder, richer. Individual item ticks are near-subaudible. The overall feel is atmosphere, not UI events.

### Signal layer

The items are proxies for relationships. The FP from the locker is ambient warmth -- the emotional residue of connection persisting through proximity and care. The player never needs to read this to understand the mechanic. It is for people paying attention.

The signal bleeds through in three places:

**Sound treatment.** Locker FP arrives differently from hit-earned FP. Hit FP pops. Locker FP glows. Different audio, different feeling. A player paying attention notices the game treats them differently without being told why.

**Partners.** Partners are who you are actually training with. They see your kit. They notice what you carry. Partner dialogue is where most of the locker signal layer lives -- a partner noticing you still wear something, recognising something in your bag, remarking on how much you have accumulated after a long run together. Surface: they know your gear. Signal: they can see how much you have held onto and what it means. The Tinkerer and Shopkeeper carry their own weight elsewhere; the locker belongs to the partner relationships.

**The Shopkeeper, once.** Late in pre-break, as the projection starts losing coherence, the Shopkeeper notices something in the locker. One line. Something like "I saw you kept that. You don't have to use it." Surface: friendly observation. Signal: the projection is aware of what the player is holding onto. After the break the player looks back and understands what that line meant.

After The Break: the warmth from the locker was always real. It just was not the friend's warmth. It was the main character's memory of it, still generating something in the absence.

---

## Destruction and secret items

Any item can be destroyed at the Tinkerer. Destroying specific items unlocks secret items that cannot be obtained any other way. This is not signposted. The Tinkerer's destruction dialogue does not hint at it. Most players will never find these.

Secret items are for die-hards: players who destroy things out of curiosity, who pay close attention to what the Tinkerer says, who experiment beyond the obvious loop. The reward is the discovery itself.

Most item destructions do not unlock anything. The partial FP refund and the Tinkerer's dialogue are the only return. Secret unlocks are rare by design -- one per specific item at most, and not every item has one.

Secret items entering the pool conditionally require the shop rotation system to support trigger-gated pool entries. See `04-upgrade-shop.md`.
