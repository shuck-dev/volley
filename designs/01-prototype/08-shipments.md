# Shipments

Catalog orders from the friend's shop arrive as shipments on the shipment mat. The tinkerer does not use shipments (see `08-tinkerer.md`).

**Dependencies:** Venue (`08-venue.md`), Shop (`08-shop.md`).

---

## `ShipmentManager` autoload

Persisted state.

```gdscript
class Shipment:
    var id: StringName
    var contents: Array[String]   # item keys from the catalog
    var arrive_at_unix: int       # wall-clock ready-at
    var opened: bool

signal shipment_arrived(shipment: Shipment)

func create(contents: Array[String], duration_seconds: int) -> StringName
func pending() -> Array[Shipment]
```

Wall-clock timing: shipments tick while the game is closed. On resume, any shipment past its `arrive_at_unix` fires `shipment_arrived` during court scene ready.

---

## Arrival

The box lands on the `ShipmentMat` in `venue.tscn`. The friend walks in from the shop, sets the box down, returns. Prototype uses a placeholder animation.

The wait is stewardship, not travel: the friend packs, adds a note, decides when to let it go. Per-order timing can carry meaning (a quick send-off vs. a slower, considered one).

---

## Milestones

Shipments in flight continue ticking through a milestone; the box arrives on the shipment mat in its new dressing.

---

## Tuning

```
shipment_friend_catalog_seconds: int = 30     # default catalog-to-court time
shipment_offline_cap_seconds: int = 28800     # 8h, matches kit catch-up cap
```

Per-item override: `ItemDefinition.shipment_seconds_override` (e.g. the bot ships slower as a narrative beat).

---

## Rough ticket outline

Not filing yet.

1. `ShipmentManager` autoload: wall-clock persistence, offline catch-up, arrival signal.
2. Friend-delivers-box animation.
3. `shipment_seconds_override` on `ItemDefinition`.
