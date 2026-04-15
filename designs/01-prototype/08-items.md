# Items, the Court, and the Kit

The player-facing model for items. Every owned thing is an item. Items are either on the court (active, working, visible) or in the kit (at rest, generating passive FP). That is the whole mechanic.

Other 08 docs are details:

- Where items physically go on the court: `08-roles.md`.
- What a physical prop is: `08-fixtures.md`.
- The kit room, passive FP, and offline catch-up: `08-kit.md`.
- The ball role specifically: `08-balls.md`.
- Runtime data and code: `08-item-manager.md`.

---

## One concept: items

All owned things are items. Every item has a physical place it belongs on the court, authored as its `role` (see `08-roles.md`). Placing an item on the court activates it; its effects register, and its visible form (if any) appears at its slot. Putting an item in the kit at-rests it; its effects stop and it begins generating passive FP instead.

No separate "kit" or "equipment" category, no counted slots, no type split between kit items and court items. One rule for all of them: on the court = active; in the kit = at rest.

---

## The court and the kit

The court is the physical world where items live when active. Items occupy authored places: some on the paddle, some as the ball, some at court-side spots (the bot dock, the jukebox stand, etc.), some as court surface treatments. Each item knows where it goes; the player does not choose a slot, they choose which items come out.

The kit is the at-rest store. Any item not currently on the court lives in the kit room (see `08-kit.md`): a shared gear room at the player's end of the venue, always present, always accessible. Balls sit in a ball rack; paddle gear and small items are on the gear shelving; larger props occupy the floor space. The player goes there to pick up items and bring them to the court, or to put things back after pulling them off.

Moving an item from the kit room onto the court costs FP and triggers a per-role cooldown. Both values are Make Fun Pass tuning targets. The cost keeps the loadout a real decision; the cooldown prevents spam.

---

## Destruction and secret items

Any item can be destroyed at the Tinkerer (mechanics: `08-tinkerer.md`). Destroying specific items unlocks secret items that cannot be obtained any other way. This is unsignposted. The Tinkerer's destruction dialogue holds its tongue. Most players will never find these.

Secret items are for die-hards: players who destroy things out of curiosity, who pay close attention to what the Tinkerer says, who experiment beyond the obvious loop. The reward is the discovery.

Most item destructions unlock nothing beyond the partial FP refund and the Tinkerer's dialogue. Secret unlocks are rare by design: one per specific item at most, and not every item has one.

Secret items entering the pool conditionally require the shop rotation system to support trigger-gated pool entries. See `04-upgrade-shop.md`.
