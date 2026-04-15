# The Shop as a Place

The shop is the friend's corner of the court: a table of small items, a catalog of bigger ones, a shipping counter where orders leave for the player's shipment mat.

**Dependencies:** World (`08-world.md`), Items (`08-items.md`), ItemManager (`08-item-manager.md`), Shipments (`08-shipments.md`), Shop Drag-and-Drop (`04-shop-drag-drop.md`), Upgrade Shop Mechanics (`05-upgrade-shop-mechanics.md`).

---

## The shop place in the court

The shop is a child scene of `court.tscn`, gated by the friend's unlock (`&"friend"` in `unlocked_characters`; see `08-world.md`). Before the friend arrives, the shop is hidden and the court has a visibly empty corner. When the friend unlocks, the scene plays the arrival beat once and from then on the shop is a permanent part of the diorama.

```
ShopPlace (child of court.tscn, hidden until friend unlocked)
├── FriendCharacter
├── ShopTable                 (pool-gated small items)
│   └── ShopItem instances    (rotated by the shop mechanic in 05)
├── ClearanceBox              (existing Control-based drop target from 04-shop-drag-drop.md)
├── ShopCatalog               (browseable surface for bigger items)
│   └── CatalogEntry instances (one per catalog-eligible item)
└── ShippingCounter           (where sealed orders leave for the shipment mat)
```

Everything above is visible in the diorama at all times once the friend is unlocked. Drag input works across the whole scene; the shop is not a focus mode.

---

## The table (pool-gated, grab-and-go)

Small items sit on the friend's table as physical objects. The pool mechanic in `05-upgrade-shop-mechanics.md` decides which items from the full item pool are on the table at any given moment (rotation, discovery, pick slot, safety net).

### Acquisition

The interaction is specified in `04-shop-drag-drop.md` and already partially built:

- The player drags a `ShopItem` from the table.
- Dropping onto the `ClearanceBox` calls `ItemManager.take(key)`. The item enters the kit.
- The player can also carry the item directly to the kit room: `take()` runs, the item is in hand, the player walks it to the kit room.

Acquisition is immediate. No shipping for table items.

### Affordability

The display case overlay on each `ShopItem`, per `04-shop-drag-drop.md`, continues to gate unaffordable items. A cased item cannot be dragged; tapping it plays the "tink" sound. The gating is diegetic rather than a rejection dialog.

### Taken items

When a `ShopItem` is taken, it hides itself in its slot (the slot stays at the same index so the friend's pick slot does not shift). The pool rotation decides when the slot refills.

---

## The catalog (bigger items, shipped)

The catalog is the friend's binder (or book, or stack of cards; art choice) of bigger items. These are substantial purchases: a bot, a jukebox, a training wall, paddle upgrades. The player browses the catalog, places an order, and the friend ships it.

### Catalog membership

Per-item authoring. An item's `ItemDefinition` declares whether it appears on the table or in the catalog. Two reasonable mechanisms, pick one:

- **Cost threshold:** items above `catalog_cost_threshold` (config key) go to the catalog; below it, the table.
- **Explicit flag:** a `catalog_only: bool` on `ItemDefinition`.

Leaning toward the explicit flag, because some expensive items might still want to appear on the table for narrative reasons (a partner's gift, for example).

### Browsing

Tapping the catalog opens it in place (no camera move; everything happens within the diorama). Pages or cards show each catalog item with its art, name, description, and price. The player flips or swipes through.

Returning to the catalog after leaving mid-browse opens to the last page viewed. The friend holds the player's spot.

### Ordering

1. Player selects an item from the catalog.
2. FP is deducted on confirm. Catalog orders seal at purchase, not at a second gesture.
3. `ShipmentManager.create(contents, duration_seconds)` starts a shipment (see `08-shipments.md`).
4. The friend walks the sealed box to the shipping counter (one-shot animation). The box leaves the counter; the shipment is in flight.
5. After the shipping time, the box lands on the shipment mat near the kit room entrance. The player opens the box and carries the item into the kit room.

Multiple catalog orders can be in flight at once. Each is its own shipment; they do not queue at the shipping counter.

### Catalog orders never take directly to the court

Even for items that have a role and a fixture (a bot, a jukebox), the order flow is order → ship → kit. The player places the item on the court from the kit as a separate gesture. This keeps the shipment's fiction intact: the friend delivers to the home, the player unpacks.

---

## The shipping counter

A small visible surface at the shop where sealed orders sit briefly before leaving for the shipment mat. Used for the visual beat of the friend sealing an order; players see their purchase physically handed off.

Not interactive. Sealed orders appear here for a second or two (as a delivery animation lead-in), then vanish as the shipment begins its wall-clock countdown.

---

## Pool, rotation, and discovery

These live in `05-upgrade-shop-mechanics.md` and are unchanged. Summary of how they intersect with the shop place:

- The pool of available items is gated by the current act (act1, act2, act3, peace).
- The table rotates through the pool according to the shop's rotation rules.
- The pick slot is visually distinguished on the table.
- The catalog draws from the same pool, filtered to catalog-eligible items.
- The safety net, cursed items, second-chance variants: all apply to whatever surface an item appears on.

---

## Shop UI surfaces

There is no dedicated shop UI layer. Every interaction is a world-space drag or tap:

- Drag from the table → kit (or `ClearanceBox`).
- Tap the catalog → it opens inline as a prop.
- Drag from the catalog: optional future gesture if "drag the catalog entry onto the shipping counter" feels better than "tap to order." Prototype ships with tap-to-order.
- Tap the friend → greeting dialogue (reserved for the dialogue system).

---

## Open design decisions

1. **Catalog browsing UX.** A physical book, a stack of cards, a framed stand? Leaning toward a book or cards; a tablet-shaped prop would break the fiction.
2. **Catalog membership mechanic.** Cost threshold vs explicit flag? Leaning toward the explicit flag for narrative authoring flexibility.
3. **Drag-the-catalog-entry-to-counter gesture.** Nice diegetic detail, low priority for prototype. Tap-to-order ships first.
4. **Visual treatment of sold-out or unavailable items in the catalog.** Greyed, removed entirely, or an "out of stock" note? Leaning greyed with a note; the friend is apologetic about what she cannot offer.
5. **Does the friend react to browsing?** Dialogue lines when the player opens the catalog, when they linger on an item, when they close without buying. Reserved for Alpha; prototype has her standing quietly at the shop.
6. **Does the friend remember what you browsed?** Returning mid-browse opens to the last page, or resets? [Last page; the friend holds your spot.]
7. **Multiple catalog orders in flight?** One at a time, queued at the shipping counter, or parallel? [Parallel; each order is its own shipment.]

---

## Rough ticket outline

Not filing yet.

1. Shop child scene in `court.tscn`: table, `ClearanceBox`, catalog stub, shipping counter, friend character placement.
2. Friend unlock narrative beat + `unlocked_characters` gate + show/hide of the shop scene.
3. Catalog authoring: `catalog_only` flag (or cost threshold) on `ItemDefinition`, one authored catalog item (the bot).
4. Catalog browse interaction: open inline, paginate, tap to order, confirm dialog, FP deduction.
5. Catalog ordering plumbing: call into `ShipmentManager`, friend-to-counter animation, shipment in flight.
