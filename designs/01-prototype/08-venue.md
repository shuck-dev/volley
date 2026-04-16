# The Venue

The venue is the single scene the player lives in. The court (play area), the friend's shop, the tinkerer's workshop, the ball rack, the gear rack, the shipment mat, and any unlocked characters all live in `venue.tscn`. The camera moves within the scene to focus each interaction.

Other 08 docs are details of systems that live inside this venue.

---

## The venue scene

`venue.tscn` (renamed from today's `main.tscn`) is the root.

```
venue.tscn
├── Court                      (play area; paddles, ball, walls)
│   ├── VolleyCounter          (diegetic scoreboard on the court)
│   ├── PersonalBest           (diegetic plaque on the court)
│   └── FriendshipPoints       (diegetic counter on the court)
├── BallRack                   (inactive balls; see 08-kit.md)
├── GearRack                   (inactive equipment; see 08-kit.md)
├── ShipmentMat                (where boxes land; see 08-shipments.md)
├── Shop                       (see 08-shop.md; hidden until friend unlocked)
│   ├── FriendCharacter
│   ├── ShopTable
│   ├── ShopCatalog
│   └── ShippingCounter
├── Workshop                   (see 08-tinkerer.md; hidden until tinkerer unlocked)
│   ├── TinkererCharacter
│   ├── Workbench
│   ├── DoneTray
│   └── DropOffBasket
├── Roles                      (court-fixture markers; see 08-roles.md)
├── DevHUD                     (CanvasLayer; screen-space dev overlay only)
└── Camera                     (single framing for the whole diorama)
```

Everything is reachable at all times by dragging from one area to another. Targets are always visible in the single frame; the player does not move a cursor-avatar.

Some actions require the main character to step off the court (equipping, dequipping). The player calls a timeout to do so; the rally plays out without a defender during the timeout.

---

## Single framing

One camera holds the whole venue as a readable diorama. Every interactive surface is visible at once; the camera does not pan between them.

---

## Diegetic signage on the court

Volley counter, personal best, and friendship-point balance live on the court as world-space elements: a scoreboard, a plaque, a counter. They are children of `Court`, so they ride with it through milestone redressing. Every one of these is a candidate for replacement by a later system (a partner announcing the streak, a character handing over FP, etc.); the court-children arrangement is the starting point, not the final form.

New-arrival cues (a shipment landing, a commission finishing, a character unlocking) also play in world space: a small pulse on the relevant object, no screen-space banner.

---

## Dev HUD

`DevHUD` is a `CanvasLayer` child of `venue.tscn`. Screen-space. Only the developer overlay (FPS counter, state inspection, dev-panel toggles) lives here. Player-facing game state does not.

Stretch: `canvas_items` with `keep` aspect ratio. Steam Deck and desktop receive the same root scene at their native aspect; the stretch handles letterboxing.

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

Starting state: empty court with the ball rack, the gear rack, and the shipment mat.

---

## Milestones

Migration redresses `venue.tscn` rather than relocating characters. Shipments and commissions in flight continue ticking through the dressing change.

---

## Two kinds of installed thing

- **Character areas** (shop, workshop). Gated by `unlocked_characters`. Top-level child scenes, hidden until unlock.
- **Item fixtures** (bot dock, jukebox). Gated by court presence of an item with a fixture. Spawned and freed by `FixtureManager` (see `08-fixtures.md`).

---

## Offline catch-up

All wall-clock systems (kit passive FP, shipments, tinkerer commissions) share a single offline cap constant:

```
offline_cap_seconds: int = 28800   # 8 hours
```

On resume, each system advances by `min(elapsed, offline_cap_seconds)`. Defined once here so future systems use the same value.

---

## Out of scope

- Windowed desktop mode: `SH-51` territory. Desktop is secondary.

---

## Open questions

1. **Visual density** once shop, workshop, bot dock, and partners are all unlocked. Leaning: camera framing tightens on the court during play; periphery rides the edges.

---

## Rough ticket outline

Not filing yet.

1. `venue.tscn` rebuild: court with diegetic signage children, ball rack, gear rack, shipment mat, character-area markers, role markers, camera, dev HUD.
2. Character unlock system: `unlocked_characters`, arrival beats, show/hide of child scenes.
3. Diorama layout pass.
4. Milestone migration hook.
