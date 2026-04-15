# Shipments

The shipment system carries catalog orders from the friend's shop to the court. That is the whole of its role. The tinkerer does not use shipments; his work happens in view at his own place (see `08-tinkerer.md`).

**Dependencies:** World (`08-world.md`), Shop (`08-shop.md`).

---

## `ShipmentManager` autoload

Persisted state. Survives quitting and reloading.

```gdscript
class Shipment:
    var id: StringName
    var contents: Array[String]  # item keys from the catalog
    var arrive_at_unix: int      # wall-clock ready-at
    var opened: bool             # landed but not yet unpacked

signal shipment_arrived(shipment: Shipment)

func create(contents: Array[String], duration_seconds: int) -> StringName
func pending() -> Array[Shipment]
```

Wall-clock timing: shipments tick while the game is closed. On resume, any shipment whose `arrive_at_unix` has passed fires `shipment_arrived` in order during court scene ready.

---

## Why the wait, with no distance

The shop is a short walk away in-frame. The wait is about stewardship, not travel: the friend packs the order, adds a note, decides when to let it go, and carries it over. The delay is the friend taking care of the handover. That framing fits a friend who remembers each item they give you, and it lets per-order timing carry meaning: a quick send-off vs. a slower, more considered one.

---

## Visual delivery

When a box lands, the friend appears with it: walks in from the shop side, sets the box down, returns to their place. Seeing the friend place the box reinforces that someone did the work, that the wait was on their behalf. Prototype can use a placeholder animation (friend fades in near the mat, box appears, friend fades out); art passes later.

The box lands on the `ShipmentMat` node in `court.tscn`, near the kit room entrance (see `08-world.md`). The player opens the box and carries the item into the kit room.

---

## Milestones

The court migrates across milestones. Since all places live in one scene, migration redresses the scene rather than relocating characters (see `08-world.md`). Shipments in flight when a milestone fires continue ticking; the box arrives on the shipment mat as it now exists in the new milestone dressing.

---

## Tuning knobs

```
shipment_friend_catalog_seconds: int = 30     # Default catalog-to-court time
shipment_offline_cap_seconds: int = 28800     # 8 hours, mirrors kit catch-up cap
```

Per-item overrides possible through `ItemDefinition.shipment_seconds_override` if a catalog item wants its own shipping time (e.g. the bot ships slower as a narrative beat).

---

## Rough ticket outline

Not filing yet.

1. `ShipmentManager` autoload: wall-clock persistence, offline catch-up, arrival signal firing on scene ready.
2. Friend-delivers-box animation on arrival.
3. Per-item `shipment_seconds_override` field on `ItemDefinition`.
