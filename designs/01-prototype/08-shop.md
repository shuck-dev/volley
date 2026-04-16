# The Shop

The friend's corner of the court: a table of small items, a catalog of bigger ones, a shipping counter.

**Dependencies:** World (`08-world.md`), Items (`08-items.md`), ItemManager (`08-item-manager.md`), Shipments (`08-shipments.md`), Shop Drag-and-Drop (`04-shop-drag-drop.md`), Upgrade Shop Mechanics (`05-upgrade-shop-mechanics.md`).

---

## Scene

```
Shop (child of court.tscn, hidden until friend unlocked)
├── FriendCharacter
├── ShopTable                 (pool-gated small items)
│   └── ShopItem instances
├── ClearanceBox              (drop target from 04-shop-drag-drop.md)
├── ShopCatalog               (browseable bigger items)
│   └── CatalogEntry instances
└── ShippingCounter           (sealed orders leaving for the shipment mat)
```

Gated by `&"friend"` in `unlocked_characters`. Everything is visible at all times once unlocked; drag input works across the whole scene.

---

## Table (grab-and-go)

Small items sit on the table. Pool rotation is in `05-upgrade-shop-mechanics.md`.

- Drag a `ShopItem` onto the `ClearanceBox` → `ItemManager.take(key)` → item enters the kit.
- Or carry it directly to the kit: same `take()` call, different path.

Acquisition is immediate. No shipping.

Unaffordable items show the display-case overlay from `04-shop-drag-drop.md`; cased items don't drag. Taken items hide in their slot; the slot refills on rotation.

---

## Catalog (shipped)

Bigger items: the bot, jukebox, training wall, paddle upgrades.

- Tap the catalog → opens inline (no camera move). Pages show art, name, description, price. Returning reopens on the last page.
- Confirm → FP deducted → `ShipmentManager.create(contents, duration_seconds)` starts a shipment.
- Friend walks the sealed box to the shipping counter; the box vanishes as the wall-clock countdown begins.
- On arrival, the box lands on the shipment mat; the player opens it and carries the item to the kit.

Multiple orders can be in flight at once. Catalog purchases never go directly to the court — order → ship → kit → carry.

Membership is authored per item via `catalog_only: bool` on `ItemDefinition`.

---

## Shipping counter

Non-interactive. Sealed orders sit here for a second or two as a delivery animation lead-in, then the shipment begins.

---

## Pool, rotation, discovery

Owned by `05-upgrade-shop-mechanics.md`. The table rotates through the pool; the catalog draws from the same pool filtered to catalog-eligible items.

---

## Interaction surfaces

- Drag table → `ClearanceBox` or kit.
- Tap catalog → inline browse → tap to order.
- Tap friend → greeting dialogue (dialogue system, later).

---

## Open questions

1. **Catalog UX.** Book, cards, framed stand? Leaning book or cards.
2. **Sold-out visuals.** Leaning greyed with a note from the friend.
3. **Does the friend react to browsing?** Alpha territory.

---

## Rough ticket outline

Not filing yet.

1. Shop child scene: table, `ClearanceBox`, catalog stub, shipping counter, friend placement.
2. Friend unlock beat, `unlocked_characters` gate, show/hide.
3. `catalog_only` flag on `ItemDefinition`; author one catalog item (the bot).
4. Catalog browse: inline open, paginate, tap to order, confirm, FP deduct.
5. Catalog ordering plumbing: `ShipmentManager.create`, friend-to-counter animation.
