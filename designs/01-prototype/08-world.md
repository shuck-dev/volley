# The Court

The court is a single scene. The arena, the friend's shop, the tinkerer's workshop, the kit, the shipment mat, and any unlocked characters all live in `court.tscn`. The camera moves within the scene to focus each interaction.

Other 08 docs are details of systems that live inside this scene.

---

## The court scene

`court.tscn` (renamed from today's `main.tscn`) is the root.

```
court.tscn
├── Arena                      (paddles, ball, walls)
├── BallRack                   (kit area — see 08-kit.md)
├── GearCase                   (kit area — see 08-kit.md)
├── Floor                      (kit area — see 08-kit.md)
├── ShipmentMat                (where boxes land; see 08-shipments.md)
├── Shop                       (see 08-shop.md — hidden until friend unlocked)
│   ├── FriendCharacter
│   ├── ShopTable
│   ├── ShopCatalog
│   └── ShippingCounter
├── Workshop                   (see 08-tinkerer.md — hidden until tinkerer unlocked)
│   ├── TinkererCharacter
│   ├── Workbench
│   ├── DoneTray
│   └── DropOffBasket
├── Roles                      (court-fixture markers; see 08-roles.md)
├── HUD                        (CanvasLayer; screen-space)
└── Camera                     (single framing for the whole diorama)
```

The player moves between areas on foot within the scene. Going to the kit, shop, or workshop stops the rally; the bot holds the arena if active. Courtside interactions (shipment mat, done tray) keep the rally live.

---

## Single framing

One camera holds the whole court as a readable diorama and shifts focus as the player moves. No cuts, no transitions.

---

## HUD

`CanvasLayer` child of `court.tscn`. Screen-space. Holds volley counter, FP balance, personal best, pause/settings, and new-arrival highlights (a small pulse near the relevant world element when a shipment lands, a commission finishes, or a character unlocks).

HUD elements use anchors and are never tied to world-space nodes.

Stretch: `canvas_items` with `keep` aspect ratio. Steam Deck, desktop, and phone all receive the same root scene at their native aspect; the stretch handles letterboxing.

---

## Character unlocks

```gdscript
var unlocked_characters: Array[StringName] = []
```

Persisted. Each character has a key (`&"friend"`, `&"tinkerer"`).

| Character | Trigger | Arrives with |
|---|---|---|
| Friend | First FP threshold, or scripted early beat | The shop |
| Tinkerer | Later FP threshold or post-friend beat | The workshop |
| Partners | Existing partner track (see `11-first-partner-unlock.md`) | Themselves |

On unlock: arrival animation plays once, the area becomes visible, future loads start with the character already present.

Starting state: empty arena with the kit and the shipment mat.

---

## Milestones

Migration redresses `court.tscn` rather than relocating characters. Shipments and commissions in flight continue ticking through the dressing change.

---

## Two kinds of installed thing

- **Character areas** (shop, workshop). Gated by `unlocked_characters`. Top-level child scenes, hidden until unlock.
- **Item fixtures** (bot dock, jukebox). Gated by court presence of an item with a fixture. Spawned and freed by `FixtureManager` (see `08-fixtures.md`).

---

## Out of scope

- Windowed desktop mode: `SH-51` territory. Desktop is secondary.

---

## Open questions

1. **Visual density** once shop, workshop, bot dock, and partners are all unlocked. Leaning: camera framing tightens on the arena during play; periphery rides the edges.

---

## Rough ticket outline

Not filing yet.

1. `court.tscn` rebuild: kit areas, shipment mat, character-area markers, role markers, camera, HUD.
2. Character unlock system: `unlocked_characters`, arrival beats, show/hide of child scenes.
3. Diorama layout pass.
4. Milestone migration hook.
