# Items, the Court, and the Kit

Every owned thing is an item. Items are either on the court (active) or in the kit (at rest, generating passive FP).

Details live in sibling docs:

- Where on the court: `08-roles.md`
- Physical props: `08-fixtures.md`
- Kit areas and passive FP: `08-kit.md`
- Ball items: `08-balls.md`
- Runtime code: `08-item-manager.md`

---

## The rule

On the court = active: effects register, prop (if any) appears at its role.

In the kit = at rest: effects stop, the item generates passive FP.

No separate equipment category, no counted slots. One rule for everything.

---

## Court and kit

The court is where items live when active. Each item has an authored role (`ball`, `court`, or `equipment`) that decides where it goes. The player chooses which items come out, not where they sit.

The kit is the at-rest store: three areas (ball rack, gear case, floor) at the player's end (see `08-kit.md`). Balls sit on the rack; equipment in the case; large court props on the floor.

Moving an item from the kit to the court costs FP and triggers a per-role cooldown. Both are tuning knobs.

---

## Destruction

Items are destroyed at the Tinkerer for a partial FP refund (mechanics: `08-tinkerer.md`).

Destroying specific items unlocks secret items that are otherwise unobtainable. Unsignposted. Most players never find them. One secret per eligible item at most; not every item has one.

Secret items entering the shop pool require trigger-gated pool entries (see `04-upgrade-shop.md`).
