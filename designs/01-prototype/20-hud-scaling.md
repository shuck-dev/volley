# HUD Scaling

## Goal

Let the player adjust the size of HUD elements without affecting the game viewport. The setting should persist across sessions, work correctly with interactive elements (buttons, sliders, future drag-and-drop), and remain compatible with the tiling scene layout (design 08).

**Dependencies:** Stretch mode (`canvas_items` + `keep` aspect) must be set in project.godot.
**Unlocks:** Accessibility for players on high-DPI displays, small windows, or non-standard resolutions.

---

## Problem

The HUD currently lives inside the game's SubViewport as a CanvasLayer. At certain window sizes or DPI settings, text and buttons can be too small or too large to use comfortably. Players need a way to scale HUD elements independently of the game.

The HUD's position inside the game SubViewport also means it scales when the game viewport compresses for secondary scenes (shop, kit). This is undesirable: the HUD should remain at the player's chosen scale regardless of how much screen space the game gets.

---

## Approaches considered

### 1. content_scale_factor (rejected)

`get_tree().root.content_scale_factor` scales the entire root viewport uniformly. The SubViewportContainer is a child of the root viewport, so the game scales too. Tested and confirmed.

### 2. Control.scale on a wrapper node (rejected)

Wrap all HUD children in a full-rect Control and set its `scale` property.

- **Anchors do not account for scale.** Godot issue #19068 (open since 2018, confirmed in Godot 4). Children anchored to edges will offset incorrectly.
- **Font rendering degrades.** Scaling up causes blurriness with non-MSDF fonts. Godot docs explicitly state this.
- **Godot discourages it.** Docs say `Control.scale` is "mainly intended for animation purposes."
- **Drag-and-drop risk.** The `_get_drag_data` / `_can_drop_data` / `_drop_data` protocol uses local coordinates. Scaled parents may misalign `at_position` vectors.

### 3. CanvasLayer.transform (rejected)

Same anchor and coordinate issues as approach 2. CanvasLayer children resolve anchors in the viewport's coordinate space, not the layer's transform space.

### 4. Separate SubViewport for the HUD (chosen)

Move the HUD out of the game SubViewport into its own SubViewport with a transparent background, layered on top. Scale the HUD viewport independently using `content_scale_factor` on the HUD's SubViewport.

- Pro: true isolation between game and HUD scaling
- Pro: anchors work correctly because the HUD viewport has its own coordinate space
- Pro: input coordinates transform correctly through the SubViewportContainer
- Pro: consistent with the project's existing SubViewport architecture
- Pro: HUD no longer scales when the game viewport compresses for secondary scenes
- Pro: `content_scale_factor` on a SubViewport is well-supported and does not have the anchor bugs that `Control.scale` has
- Con: HUD moves out of the game scene; communication becomes cross-viewport (signals via autoloads still work, node paths break)
- Con: minor SubViewport overhead (negligible for 2D UI)

### 5. Theme font size scaling (rejected for now)

Override `theme_override_font_sizes` on HUD elements proportionally. Zero coordinate issues, but only scales text; icons, spacing, and art need separate handling. Does not solve the secondary problem of HUD scaling with game viewport compression.

---

## Decision

**Use approach 4 (separate HUD SubViewport).** The project already uses a SubViewport architecture for the game and secondary scenes. Adding a HUD viewport is a natural extension, not a new pattern. It solves both problems: independent scale control and decoupling the HUD from game viewport compression.

### Architecture

```
SceneLayout (Control, full-rect)
  HBoxContainer
    GameViewportContainer (SubViewportContainer, stretch)
      GameViewport (SubViewport, 1920x1080)
        Game (Node2D, no longer contains HUD)
    SecondaryContainer (Control)
      [shop, kit, etc.]
  HudViewportContainer (SubViewportContainer, stretch, full-rect, mouse_filter=ignore)
    HudViewport (SubViewport, transparent_bg=true)
      HUD (CanvasLayer)
        [all HUD elements]
        HudScaleSetting
```

The `HudViewportContainer` overlays the entire screen (full-rect anchors, above the HBoxContainer in z-order). Its `mouse_filter` is set to `ignore` on the container so clicks pass through to the game, but individual HUD Controls (buttons, sliders) still receive input because they're inside the SubViewport.

### How scaling works

`HudViewport.content_scale_factor` scales everything inside the HUD viewport uniformly. At 1.5x, the viewport's coordinate space becomes 1280x720 (1920/1.5 x 1080/1.5), so all anchored elements reposition correctly for the smaller logical space, and text/controls render at 1.5x their normal size.

### Implementation

1. Move HUD from `Game` scene to `SceneLayout` in its own SubViewport.
2. `HudViewportContainer`: full-rect, `stretch = true`, `mouse_filter = MOUSE_FILTER_IGNORE`.
3. `HudViewport`: `transparent_bg = true`, `size = Vector2i(1920, 1080)`.
4. `HudScaleSetting` sets `hud_viewport.content_scale_factor` on apply.
5. Persist scale to `user://hud_scale.cfg` via ConfigFile.
6. Load and apply on `_ready`.
7. Route signals: `Game` no longer has direct access to HUD. Use autoloads or signals through `SceneLayout` to connect game events (volley count, FP changes) to HUD updates.

### Signal routing after the move

Currently `game.gd` calls HUD methods directly (`hud.update_volley_count()` etc.) via an `@export var hud`. After the move:

- Option A: `SceneLayout` wires the connection, passing the HUD reference to `Game` after both are instantiated.
- Option B: Game emits signals, HUD listens via autoloads (already the pattern for `ProgressionManager`, `ItemManager`).

Option A is simpler for prototype. Option B is cleaner long-term. Use A for now; refactor to B when the HUD grows.

### Scale model: global default with per-viewport overrides

There is one **global UI scale** setting that applies to all UI viewports (HUD, shop, kit, compendium). Each viewport also supports an **override** that replaces the global value for that viewport only.

```
Effective scale = override ?? global
```

Stored in `user://ui_scale.cfg`:

```
[ui_scale]
global = 1.5
hud = null        ; uses global (1.5)
shop = 1.0        ; override: shop stays at 1.0
kit = null         ; uses global (1.5)
```

This means:

- A player who just wants everything bigger sets the global and is done.
- A player who finds the shop too cramped at 1.5x can override it back to 1.0 without affecting the HUD.
- New viewports automatically inherit the global scale with no extra config.

The settings UI lives in the HUD. It shows a "UI Scale" slider for the global value. Per-viewport overrides are optional: expose them only when there is a clear reason (e.g. a secondary scene feels wrong at the global scale). For the prototype, only the global slider ships; overrides are added when secondary scenes are playable and need tuning.

At runtime, `SceneLayout` applies the global `content_scale_factor` to every UI SubViewport it manages. When a viewport has an override, that value is used instead. When a secondary scene is opened, `SceneLayout` reads the config and applies the correct scale to its viewport before the scene is visible.

### Scope for future

- **Tiling layout (design 08):** the HUD overlay is independent of game viewport compression. When the shop opens and the game shrinks, the HUD stays full-screen at the player's chosen scale.
- **Drag-and-drop:** unaffected. The HUD viewport has its own coordinate space; `content_scale_factor` adjusts it correctly.
- **Desktop multi-window (SH-51):** the HUD viewport approach works identically in both fullscreen and windowed modes. Each OS window can read from the same config.
- **Secondary scene UIs:** shop, kit, and compendium each get their own SubViewport. `SceneLayout` applies the global scale (or override) to each viewport's `content_scale_factor` when it's created.

---

## References

- [Godot docs: Control.scale](https://docs.godotengine.org/en/stable/classes/class_control.html) (animation-only recommendation)
- [Godot issue #19068: Scaled Controls don't align properly](https://github.com/godotengine/godot/issues/19068)
- [Godot issue #92786: Anchor presets ignore scale](https://github.com/godotengine/godot/issues/92786)
- [Godot proposal #2841: Redesign Control scaling](https://github.com/godotengine/godot-proposals/issues/2841)
- [Godot docs: Multiple resolutions](https://docs.godotengine.org/en/stable/tutorials/rendering/multiple_resolutions.html)
- [The simplest way to scale UI in Godot](https://humnom.net/thoughts/67b7374e-the-simplest-way-to-scale-ui-in-godot.html)
