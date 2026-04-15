# World as One Place

The venue is a single scene. The court sits at the centre; the friend's shop, the tinkerer's workshop, the kit room, the shipment mat, and any unlocked characters all live in the same `court.tscn`. The camera moves within this scene to focus each interaction. No window management, no scene switching, no travel transitions.

This doc owns the containing world: the scene tree, the camera, the HUD, the character-unlock system, and the starting state. Every other 08-prefix doc is a detail of something that lives inside this world.

---

## Pitch in one breath

There is one place: the venue. The court sits at the centre; the friend's shop is at one end; the tinkerer's workshop is at another; the kit room is at the player's end, a shared gear room where the player's items live when not on the court. The shipment mat is nearby. The camera moves within this scene to focus each interaction. Characters and their places arrive as the player unlocks them and travel with the venue as it migrates across milestones.

The player lives in one continuous space.

---

## The court scene

`court.tscn` (renamed from today's `main.tscn`) owns the whole playable world.

```
court.tscn
├── Arena                      (paddles, ball, walls)
├── KitPlace                   (see 08-kit.md — always present)
│   ├── BallRack
│   ├── GearArea
│   └── FloorSpace
├── ShipmentMat                (where arriving boxes land; see 08-shipments.md)
├── ShopPlace                  (see 08-shop.md — hidden until friend unlocked)
│   ├── FriendCharacter
│   ├── ShopTable
│   ├── ShopCatalog
│   └── ShippingCounter
├── WorkshopPlace              (see 08-tinkerer.md — hidden until tinkerer unlocked)
│   ├── TinkererCharacter
│   ├── Workbench
│   ├── DoneTray
│   └── DropOffBasket
├── Roles                      (authored role markers; see 08-roles.md)
├── HUD                        (CanvasLayer; screen-space)
└── Camera                     (single framing for the whole diorama)
```

The venue is one continuous space. The player attends to each place by looking toward it; the camera follows within the scene. Going to the kit room, the shop, or the workshop stops the rally; the player is away from the court. The bot holds the court in the player's absence when it is active (see `08-bot.md`). Interactions courtside (dropping something at the shipment mat, picking up from the done tray at the court edge) keep the rally live.

Each place stays visible and reachable at all times once present. The player carries items between places on foot within the scene: take an item from the kit room to the workshop drop-off basket, carry a shop table item to the kit room, drag a court item off the paddle back toward the kit room entrance. No gesture teleports items across the venue in one drag; the player physically moves between places.

---

## Single framing

The camera holds one framing that takes in the whole venue as a readable diorama. Arena at the centre, kit room at the player's end, shipment mat near the kit room entrance, shop at one side, workshop at another, bot dock and other fixtures at their authored positions. Everything legible at once.

Art discipline is what makes this work: the prototype layout places each place clearly within the frame without crowding, and the art pass later refines composition. The camera shifts focus within the same scene as the player moves between places; no cuts, no transitions.

---

## HUD and resolution

The HUD is a `CanvasLayer` child of `court.tscn`, rendering in screen space above the world. Volley counter, FP balance, personal best, pause/settings button, and new-arrival highlights live here. The HUD stays lean: the world speaks for itself through the diorama, so the HUD's job is indicators and system controls rather than navigation.

HUD elements use anchors so they hold their screen positions across resolutions. No HUD element is tied to a world-space node.

New-arrival highlights (a shipment arriving on the mat, a finished commission on the done tray, a character just unlocked) surface through a subtle HUD cue: a small pulse near the relevant world element or a brief label. The goal is to point the player's eye without pulling the camera or opening anything.

The project runs under Godot's `canvas_items` stretch mode with a `keep` aspect ratio. The court scene sizes itself to the viewport; the HUD `CanvasLayer` sizes itself to screen space. Steam Deck, desktop, and phone targets all receive the same root scene at their native aspect; the stretch mode handles the letterboxing.

---

## Character unlocks

The friend, the tinkerer, and future characters (partners aside) unlock on a partner-style track.

### `ProgressionData` addition

```gdscript
var unlocked_characters: Array[StringName] = []
```

Mirrors `unlocked_partners`. Persisted. Each character has a unique key (`&"friend"`, `&"tinkerer"`, etc.).

### Unlock flow

Each character has its own trigger. The prototype starts with three unlocks authored:

| Character | Trigger | Arrives with |
|---|---|---|
| Friend | First FP threshold, or scripted early beat | The shop (see `08-shop.md`) |
| Tinkerer | Later FP threshold or post-friend beat | The workshop (see `08-tinkerer.md`) |
| Partners | Existing partner track (see `11-first-partner-unlock.md`) | Themselves, in front of the right wall |

Unlocks are narrative moments, not menu events: the character walks in, sets up, the place becomes visible, the court stays busier from then on. The arriving animation plays once; future loads start with the character already present.

### Starting state

Early game: the player on an empty court with the arena, the kit room, and the shipment mat. No shop, no workshop, no partners. The quiet gives the friend's arrival somewhere to land.

---

## Milestones and migration

The court migrates across milestones. Since all places live in one scene, migration redresses the scene rather than relocating characters. Shipments in flight when a milestone fires continue ticking; the box arrives on the shipment mat as it now exists in the new milestone dressing. Tinkerer commissions continue at the workshop in its new dressing.

---

## Two kinds of installed thing

The court holds two distinct kinds of installed thing on different lifecycles:

- **Character places** (the shop, the workshop). Gated by `unlocked_characters`. Authored as top-level child scenes of `court.tscn`, hidden until unlock, visible from that moment on.
- **Item fixtures** (bot dock, jukebox). Gated by court presence of an item with a fixture. Spawned and freed by `FixtureManager` (see `08-fixtures.md`).

Both render into the same court scene. Role markers (see `08-roles.md`) position item fixtures; character places have their own dedicated positions authored into `court.tscn`.

---

## What lives in the venue (summary)

| Element | Always present? | Gating |
|---|---|---|
| Arena, paddles, ball | Yes | None |
| Kit room | Yes | None (see `08-kit.md`) |
| Shipment mat | Yes | None (see `08-shipments.md`) |
| HUD | Yes | None |
| Shop | No | `&"friend"` in `unlocked_characters` (see `08-shop.md`) |
| Workshop | No | `&"tinkerer"` in `unlocked_characters` (see `08-tinkerer.md`) |
| Bot dock | No | Bot item on the court (see `08-bot.md`) |
| Jukebox (future) | No | Jukebox item on the court |
| Partners | No | Existing partner unlock track |

---

## What this replaces

From earlier drafts (the old `08-scene-layout.md`, `08b-scene-layout-rethink.md`, earlier passes of this doc):

- `SceneLayout` tiling and sibling management: the prototype needs one scene.
- `TravelManager` and travel transitions: the player never leaves the court.
- Separate `clearance.tscn` / `workshop.tscn` scenes: child nodes of `court.tscn` instead.
- "Places travel with the player": the court migrates as a whole; redressing the scene is the mechanism.
- "Away" mode for the bot: idle is the only activation trigger.
- Wrapping `SubViewport` and `SubViewportContainer` for the playable area: the single-scene model needs neither.

What carries forward:

- Diegetic framing: the player sees the world, not a menu stack.
- The HUD is always available.
- The game fills whatever space the display gives it.
- Control-based drag-and-drop within a place (shop table, kit, catalog).

---

## Out of scope

- Windowed desktop mode and its multi-window behaviour: `SH-51` territory, builds on this root without replacing it. Desktop is secondary.

---

## Open design decisions

1. **Visual density.** Once shop + workshop + bot dock + partners are all unlocked, the court has a lot of characters. Does the camera zoom into the arena hide the periphery during play, or is the full cast always visible? [Camera framing keeps the arena tight during play; the periphery rides the edges.]

---

## Rough ticket outline

Not filing yet.

1. `court.tscn` rebuild: kit room, shipment mat, reserved markers for character places and role positions, single-framing camera, HUD as CanvasLayer.
2. Character unlock system: `unlocked_characters` on `ProgressionData`, arrival narrative beats, show/hide of child scenes.
3. Diorama layout pass: place the shop, workshop, kit room, shipment mat, and fixture markers so the whole venue reads clearly in one frame.
4. Milestone migration hook: scene redress on milestone change, character and commission state preserved.

Place-specific and system-specific tickets live in their respective docs.
