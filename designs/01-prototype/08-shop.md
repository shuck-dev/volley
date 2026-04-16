# The Shop

The friend's corner of the court: a table of small items, a catalog of bigger ones, a shipping counter.

**Dependencies:** Venue (`08-venue.md`), Items (`08-items.md`), ItemManager (`08-item-manager.md`), Shipments (`08-shipments.md`), Shop Drag-and-Drop (`04-shop-drag-drop.md`), Upgrade Shop Mechanics (`05-upgrade-shop-mechanics.md`).

---

## Scene

```
Shop (child of venue.tscn, hidden until friend unlocked)
├── FriendCharacter
├── ShopTable                 (pool-gated small items)
│   └── ShopItem instances
├── ShopCatalog               (browseable bigger items)
│   └── CatalogEntry instances
└── ShippingCounter           (sealed orders leaving for the shipment mat)
```

Gated by `&"friend"` in `unlocked_characters`. Everything is visible at all times once unlocked; drag input works across the whole scene.

---

## Table (grab-and-go)

Small items sit on the table as physics objects. Pool rotation is in `05-upgrade-shop-mechanics.md`.

The player buys an item by dragging or pushing it outside the shop area. Once the item crosses the shop boundary, `ItemManager.take(key)` fires and the item is owned. From there the item lands wherever the player left it: on the `BallRack`, `GearRack`, or the venue floor.

Acquisition is immediate. No shipping.

Unaffordable items show the display-case overlay from `04-shop-drag-drop.md`; cased items don't drag. Taken items leave their slot; the slot refills on rotation.

---

## Catalog (shipped)

Bigger items: the bot, jukebox, training wall, paddle upgrades.

- Tap the catalog → opens inline (no camera move). Pages show art, name, description, price. Returning reopens on the last page.
- Confirm → FP deducted → `ShipmentManager.create(contents, duration_seconds)` starts a shipment.
- Friend walks the sealed box to the shipping counter; the box vanishes as the wall-clock countdown begins.
- On arrival, the box lands on the shipment mat. The player drags the item from the box: ball items into `BallRack`, equipment items into `GearRack`, court items (e.g. the bot) directly onto the court.

Multiple orders can be in flight at once.

Membership is authored per item via `catalog_only: bool` on `ItemDefinition`.

---

## Shipping counter

Non-interactive. Sealed orders sit here for a second or two as a delivery animation lead-in, then the shipment begins.

---

## Pool, rotation, discovery

Owned by `05-upgrade-shop-mechanics.md`. The table rotates through the pool; the catalog draws from the same pool filtered to catalog-eligible items.

---

## Interaction surfaces

- Drag or push table items outside the shop area to buy.
- Tap catalog → inline browse → tap to order.
- Tap friend → greeting dialogue (dialogue system, later).

---

## Resolved questions

1. **Catalog UX.** A pull-up menu styled as a physical catalog. Purchased items get a "sold" stamp or circle, the way you would mark off a Scholastic book order form.
2. **Sold-out visuals.** The sold stamp on the catalog entry doubles as the sold-out state. No separate greyed treatment needed.
3. **Does the friend react to browsing?** Sometimes, when it fits. Alpha scope.

---

## Rough ticket outline

Not filing yet.

1. Shop child scene: table, shop boundary trigger, catalog stub, shipping counter, friend placement.
2. Friend unlock beat, `unlocked_characters` gate, show/hide.
3. `catalog_only` flag on `ItemDefinition`; author one catalog item (the bot).
4. Catalog browse: inline open, paginate, tap to order, confirm, FP deduct.
5. Catalog ordering plumbing: `ShipmentManager.create`, friend-to-counter animation.
