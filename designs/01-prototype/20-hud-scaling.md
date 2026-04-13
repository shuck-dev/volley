# HUD Scaling

## Goal

Let the player adjust the size of UI elements without affecting game content. The setting should persist across sessions, work correctly with interactive elements (buttons, sliders, future drag-and-drop), and remain compatible with the tiling scene layout (design 08).

Each view (game, shop, kit, compendium) owns its own UI. Scaling applies per-view, not as a global overlay.

**Dependencies:** Stretch mode (`canvas_items` + `keep` aspect) must be set in project.godot.
**Unlocks:** Accessibility for players on high-DPI displays, small windows, or non-standard resolutions.

---

## Problem

UI elements live inside the same SubViewport as game content. Scaling that viewport scales everything: ball, paddles, text, and buttons together. Players need to scale UI independently from content.

A global HUD overlay (single viewport on top of all views) was tried and rejected: it breaks the model where each view owns its own UI. The shop has its own buttons and prices; the kit has its own drag slots. These are not HUD elements; they belong to their respective views.

---

## Approaches considered

### 1. content_scale_factor on root (rejected)

Scales everything in the root viewport, including all SubViewportContainers. Tested and confirmed.

### 2. Control.scale on a wrapper node (rejected)

Anchors do not account for scale (Godot issues #19068, #92786). Font rendering degrades. Docs say "mainly intended for animation purposes." Drag-and-drop coordinates may misalign.

### 3. CanvasLayer.transform (rejected)

Same anchor and coordinate issues as approach 2.

### 4. Single global HUD overlay viewport (rejected)

Moves HUD into its own SubViewport overlaying the entire screen. Works for the game HUD, but breaks the model: each view has its own UI (shop has buttons and prices, kit has drag slots). A single overlay cannot serve all views.

### 5. Paired content/UI viewports per view (chosen)

Each view slot contains two stacked SubViewports: one for content (game objects, shop background), one for UI (HUD, shop buttons). The UI viewport has `transparent_bg = true` and overlays the content viewport within the same slot. UI scaling uses `size_2d_override` on the UI viewport only.

- Pro: each view owns its own UI; no global overlay
- Pro: UI scales independently from content per-view
- Pro: tiling layout works naturally; each slot is self-contained
- Pro: input stays local to each viewport
- Pro: anchors work correctly in the UI viewport's own coordinate space
- Pro: future views (kit, compendium) follow the same pattern
- Con: double the SubViewports (2 per view)
- Con: slightly more wiring per view
- Con: content and UI viewports must stay in sync when the slot resizes

---

## Decision

**Use approach 5 (paired content/UI viewports per view).**

### Architecture

```
SceneLayout (Control, full-rect)
  HBoxContainer
    GameSlot (Control, size_flags_horizontal=expand_fill)
      GameContentContainer (SubViewportContainer, full-rect, stretch)
        GameContentViewport (SubViewport)
          Game (Node2D)
      GameUIContainer (SubViewportContainer, full-rect, stretch, mouse_filter=pass)
        GameUIViewport (SubViewport, transparent_bg=true)
          HUD (CanvasLayer)
    SecondaryContainer (Control)
      [dynamically created with same paired pattern]
```

Within each slot, the two SubViewportContainers overlap (both full-rect anchored). The content container renders first, the UI container renders on top with a transparent background. `mouse_filter = pass` on the UI container lets unhandled events reach the content viewport.

### How scaling works

`SubViewport` does not have `content_scale_factor` (that is a `Window`-only property). Instead, scaling uses `size_2d_override` with `size_2d_override_stretch = true`. Setting the 2D override to a smaller logical size makes the content render larger within the same pixel area. At 1.5x, a 1920x1080 viewport's logical 2D size becomes 1280x720, so all anchored elements reposition correctly for the smaller logical space and text/controls render at 1.5x their normal size.

Only UI viewports get `size_2d_override`. Content viewports are untouched.

### Implementation

1. Wrap the game's `SubViewportContainer` in a `GameSlot` Control node.
2. Add a second `SubViewportContainer` + `SubViewport` pair to `GameSlot` for the game UI (HUD).
3. `GameUIContainer`: full-rect, `stretch = true`, `mouse_filter = MOUSE_FILTER_PASS`.
4. `GameUIViewport`: `transparent_bg = true`, `handle_input_locally = false`.
5. `SceneLayout` instantiates the HUD scene into `GameUIViewport`.
6. `SceneLayout` wires game signals to HUD methods (option A: direct wiring for prototype).
7. `SceneLayout` applies `size_2d_override` to UI viewports based on `UIScaleConfig`.
8. When `open_secondary` creates a secondary view, it creates the same paired structure: content viewport + UI viewport.
9. `HudScaleSetting` calls `SceneLayout.apply_global_scale()` on apply.
10. Scale persisted to `user://ui_scale.cfg` via `UIScaleConfig`.

### Signal routing

`Game` emits signals (`volley_count_changed`, `personal_volley_best_changed`, etc.). `SceneLayout` connects them to HUD methods after instantiating both scenes. `Game` does not reference the HUD.

### Scale model: global default with per-viewport overrides

One **global UI scale** applies to all UI viewports. Each viewport supports an **override**.

```
Effective scale = override ?? global
```

Stored in `user://ui_scale.cfg`:

```
[ui_scale]
global = 1.5
game = null       ; uses global (1.5)
shop = 1.0        ; override: shop stays at 1.0
kit = null         ; uses global (1.5)
```

For the prototype, only the global slider ships. Per-viewport overrides are added when secondary scenes are playable and need tuning.

### Scope for future

- **Tiling layout (design 08):** each slot is self-contained. When the shop opens and the game slot shrinks, both the game content and game UI viewports resize together within the slot. The UI stays proportionally correct because `size_2d_override` is relative to the viewport's pixel size.
- **Drag-and-drop:** unaffected. Each UI viewport has its own coordinate space; `size_2d_override` adjusts it correctly.
- **Desktop multi-window (SH-51):** each OS window can follow the same paired pattern and read from the same config.
- **New views:** any new view (kit, compendium) creates the same paired structure. `SceneLayout` applies the correct scale automatically.

---

## References

- [Godot docs: Control.scale](https://docs.godotengine.org/en/stable/classes/class_control.html) (animation-only recommendation)
- [Godot issue #19068: Scaled Controls don't align properly](https://github.com/godotengine/godot/issues/19068)
- [Godot issue #92786: Anchor presets ignore scale](https://github.com/godotengine/godot/issues/92786)
- [Godot proposal #2841: Redesign Control scaling](https://github.com/godotengine/godot-proposals/issues/2841)
- [Godot docs: Multiple resolutions](https://docs.godotengine.org/en/stable/tutorials/rendering/multiple_resolutions.html)
- [Godot 4 SubViewport with scaling GUI](https://forum.godotengine.org/t/godot-4-how-do-i-make-a-subviewport-that-supports-both-scaling-gui-and-multiple-resolutions/4110)
- [Pixel art UI at different resolution](https://forum.godotengine.org/t/ui-and-screen-resolution-in-a-pixel-art-game/61949)
- [The simplest way to scale UI in Godot](https://humnom.net/thoughts/67b7374e-the-simplest-way-to-scale-ui-in-godot.html)
