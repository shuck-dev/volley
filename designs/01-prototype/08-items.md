# Items, the Court, and the Kit

Every owned thing is an item. All owned items together are **the kit**.

Each item is either **active** (on the court, effects running) or **inactive** (at rest, generating passive FP). Active and inactive are orthogonal to the kit: they describe the item's current state, not whether it's owned.

Two actors to keep straight:

- **Player**: the person at the mouse/keyboard. Performs drags, clicks, keypresses.
- **Main character**: the avatar on the court. Plays the rally. Wears equipment.

Details live in sibling docs:

- Where on the court: `08-roles.md`
- Physical props: `08-fixtures.md`
- Storage for inactive items, passive FP: `08-kit.md`
- Ball items: `08-balls.md`
- Runtime code: `08-item-manager.md`

---

## Active vs inactive

Active: effects register, the item is visible at its role on the court.

Inactive: effects stop, the item generates passive FP.

Role decides whether an item can be inactive:

- **Ball and equipment** can be either active or inactive. Inactive ones sit on the `BallRack` or in the `GearCase`.
- **Court** items are always active once acquired. They go straight from shipment onto the court and stay there until destroyed at the Tinkerer.

---

## Moving between states

The player drives every transition by drag-and-drop. Activation triggers a per-role cooldown (tuning knob). See `08-kit.md` for the flow per role.

---

## Destruction

Items are destroyed at the Tinkerer for a partial FP refund (mechanics: `08-tinkerer.md`).

Destroying specific items unlocks secret items that are otherwise unobtainable. Unsignposted. Most players never find them. One secret per eligible item at most; not every item has one.

Secret items entering the shop pool require trigger-gated pool entries (see `04-upgrade-shop.md`).
