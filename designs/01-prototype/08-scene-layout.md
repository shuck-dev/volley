# Scene Layout

## Goal

Define how the game scene and secondary scenes (shop, kit/locker, compendium) share screen space in fullscreen mode. Inspired by Hyprland's tiling window manager: when a secondary scene opens, the game view compresses to make room rather than being overlaid. Each scene takes up as much space as it needs.

**Dependencies:** None (layout system is foundational)
**Unlocks:** Shop UI (SH-32), Kit/Locker UI, Item Compendium, Desktop Experience (fullscreen mode for portables)

---

## Core concept

The screen is a tiling layout with the game as the primary scene. All other scenes (shop, kit, compendium) are secondary scenes that appear alongside it. When a secondary scene opens, the game's SubViewport shrinks to accommodate it. When it closes, the SubViewport expands back.

This is the fullscreen/portable layout. On desktop, the multi-window experience (SH-51) uses actual OS windows instead of tiling.

---

## Layout rules

### Primary scene

The game is always the primary scene. It cannot be closed, minimised, or moved. It fills whatever space is left after secondary scenes claim theirs. The game's SubViewport and all its contents (ball, paddle, HUD CanvasLayer) scale to fit the reduced space.

### Secondary scenes

Each secondary scene declares its preferred size (width or height depending on split direction). The layout system grants it that size and compresses the primary SubViewport to compensate.

Secondary scenes are not fixed-size overlays. They are proper scenes with their own content: the shop has the shopkeeper and items, the kit has draggable equipment slots, the compendium has pages. They need enough room for their content to function.

### Split direction

Following Hyprland's dwindle approach: the split direction is determined by the aspect ratio of the available space.

- If the available width > height: split horizontally (new scene appears on the right)
- If the available height > width: split vertically (new scene appears on the bottom)

For a standard landscape display, the first secondary scene will almost always split horizontally (game on left, scene on right). A second secondary scene would evaluate the remaining space and split accordingly.

### Multiple scenes

Multiple secondary scenes can be open simultaneously. Each one claims its preferred size from the remaining space. The game always gets whatever is left. If too many scenes are open and the game would be compressed below a minimum size, the oldest secondary scene is closed to make room.

### Sibling behaviour

When multiple secondary scenes are open, they are siblings: they share the non-game space and split it among themselves using the same dwindle logic (aspect ratio determines split direction). No secondary scene has priority over another; they negotiate space equally.

### Preferred size

Each secondary scene exports its preferred dimensions:

- Preferred width (for horizontal splits)
- Preferred height (for vertical splits)
- Minimum width/height (floor, the scene will not be smaller than this)

The layout system reads these and allocates space. If the preferred size would compress the game below its minimum, the scene gets less than its preferred size (down to its minimum). If even the minimum would compress the game too far, the scene cannot open.

---

## Transitions

When a scene opens or closes, the layout change should be tweened, not instant. The game's SubViewport smoothly compresses or expands. The secondary scene slides in from the edge. This should feel physical, like rearranging objects on a desk.

Tween duration is a tuning target. Starting point: 0.3s ease-out.

---

## Game viewport scaling

When the game's SubViewport is compressed, its contents must scale correctly:

- The SubViewport renders at whatever size the SubViewportContainer gives it
- The paddle, ball, and court scale proportionally
- The HUD CanvasLayer repositions to fit the smaller SubViewport
- Physics and gameplay are unaffected because the SubViewport is its own coordinate space

This is the hardest technical challenge. The game currently assumes a fixed viewport. Making it responsive to dynamic resizing needs a spike.

---

## Prototype scope

For prototype, the tiling system is simplified to unblock the shop and kit/locker work. The full system (Alpha) builds on top of this without reworking it.

### Architecture

A `SceneLayout` Control node sits at the root of the scene tree, above the game. It manages two regions: the primary SubViewportContainer (game) and a secondary slot for scenes.

```
SceneLayout (Control)
  GameViewportContainer (SubViewportContainer)
    GameViewport (SubViewport)
      Game (the current main scene contents: ball, paddle, HUD, walls)
  SecondaryContainer (Control)
    [shop scene, kit scene, etc. instantiated here]
```

The game runs inside a SubViewport from the start, even in prototype. This is the cleanest way to resize the game without breaking physics or positions: the SubViewport renders at whatever size the SubViewportContainer gives it, and the game inside does not know or care that it has been resized. Physics coordinates are unaffected because the SubViewport is its own world.

### What the prototype delivers

- **One secondary scene at a time.** Opening a new scene closes the current one.
- **Horizontal split only.** Game on the left, secondary scene on the right. No vertical or dwindle logic.
- **Secondary scene declares preferred width.** The SceneLayout reads it and sizes the split accordingly. No negotiation or minimum-size fallbacks.
- **No tween.** Layout changes are instant. Tweened transitions are a Make Fun pass item.
- **HUD stays in the game SubViewport.** The HUD CanvasLayer is inside the SubViewport, so it scales with the game.
- **Game in SubViewport.** The game scene moves into a SubViewport. This is the foundational change that makes everything else work.

### SceneLayout responsibilities

- Holds the GameViewportContainer and SecondaryContainer as children
- Exposes `open_secondary(scene: PackedScene)` and `close_secondary()`
- On open: instantiates the scene, adds it to SecondaryContainer, resizes the split
- On close: removes the secondary scene, expands the GameViewportContainer back to full width
- Reads `preferred_width` from the secondary scene to determine split position

### Secondary scene interface

Each secondary scene (shop, kit, compendium) exports:

```gdscript
@export var preferred_width: int = 400
```

The SceneLayout reads this after instantiation to set the split. In Alpha, this expands to preferred height, minimum sizes, and dynamic negotiation.

### What changes for existing code

- **main.tscn** restructures: the current root Node2D (Game) moves inside a SubViewport. The new root is SceneLayout.
- **game.gd** is unchanged. It does not know about the layout.
- **hud.gd** is unchanged. The HUD CanvasLayer is inside the SubViewport and renders relative to the game.
- **Shop button signal** routes through SceneLayout instead of game.gd. The HUD emits `shop_button_pressed`, SceneLayout listens and calls `open_secondary(ShopScene)`.

### What this sets up for Alpha

The prototype SceneLayout is intentionally a subset of the full system:

| Prototype | Alpha |
|-----------|-------|
| One secondary scene | Multiple siblings |
| Horizontal split only | Dwindle (aspect ratio) |
| Reads preferred_width | Reads preferred width, height, min/max |
| Instant resize | Tweened transitions |
| No minimum game size | Minimum game size enforced |

The SubViewport approach carries forward unchanged. The layout logic gets smarter; the game inside the SubViewport does not change.

---

## Open questions

- What is the default preferred width for the shop? Starting point: 400px on a 1152x648 window (roughly 35% of width).
- Should the secondary scene have a close button, or only close via the HUD button toggle?
- What is the minimum game SubViewport size before gameplay becomes unplayable? Needs playtesting once the SubViewport is in place.
- Should scene arrangement be user-configurable (drag to resize splits) in Alpha, or always automatic?
