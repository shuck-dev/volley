# Tech Art Pipeline

How Volley!'s visual direction becomes Godot. Partner document to the [Art Bible](bible.md) and [Style Workshop](style-workshop.md): the bible says what the work feels like, this doc says how it gets built.

This is a living spike. Colours, typography, and per-character notes still route through the bible. Pipeline structure is locked here so contributors can deliver art against it before the final style guide lands.

---

## Game shape

Volley! is 2D throughout. Hand-drawn sprites, Control-node UI, Parallax2D backgrounds. Characters are simple and expressive; environments carry depth through layered, painted backgrounds. Two registers share the same assets where possible and diverge through palette, light, and edge treatment.

The target resolution is **1920x1080**, set in `project.godot` under `window/size`. Stretch mode is `canvas_items`: the viewport scales to the window while Control and CanvasItem nodes keep crisp edges. All sprite and layout budgets in this doc assume that base.

---

## Renderer

**Mobile renderer, not Forward Plus.** Forward Plus is tuned for 3D clustered lighting; Volley! ships no 3D geometry, no SDFGI, no volumetric fog. Mobile gives the same CanvasItem pipeline at lower GPU cost and better laptop battery life, which matters for an idle game that might run for hours while the player works.

Switch via `project.godot` → `rendering/renderer/rendering_method` (and `rendering_method.mobile`). Confirm Parallax2D, CanvasModulate, Light2D, and the existing particle effects render identically before committing.

`project.godot` currently declares `Forward Plus` from the Godot default. That mismatch is the first cleanup this doc authorises.

---

## Sprites

### Authoring

Artists deliver **PNG, sRGB, 32-bit with alpha**. No interlacing, no colour profiles embedded (Godot strips them; exported profile mismatches cause subtle hue drift). SVG is acceptable for a handful of graphic props and UI marks that need to scale cleanly across resolutions (see the existing `assets/art/martha_bow.svg` and `assets/ui/friend_pick_note.svg`), but the default is PNG because the bible calls for line with life in it, and SVG renders the line mechanically.

Deliverables arrive at **1x authoring resolution** for their intended on-screen size at 1080p. A paddle that reads as 40x200 logical pixels is delivered at 40x200. Characters are delivered at the size they appear in-game, not oversized for downscaling. This keeps the drawn line weight consistent across the frame rather than varying with each artist's canvas choice.

Two authored scales ship alongside the base:

- **@2x** for sprites that may appear zoomed (cutscenes, The Break reveal, marketing crops).
- **@0.5x** only where an asset is shown much smaller in UI than in the world (item thumbnails) and aliasing at runtime-downscale is visible.

Default to base only. Add scales as the need shows up in review, not preemptively.

### Import

Each PNG has a sibling `.import` file committed to the repo. Import settings per sprite class:

| Class | Filter | Mipmaps | Fix alpha border | Notes |
|---|---|---|---|---|
| Characters and props | Linear | Off | On | The line must stay crisp; nearest-neighbour reads pixel-art, linear with mipmaps off reads drawn. |
| Backgrounds | Linear | On | On | Parallax2D layers may render at fractional scales; mipmaps prevent shimmer on slow drift. |
| UI | Linear | Off | On | UI sits at native scale; mipmaps waste memory. |
| Item thumbnails | Linear | Off | On | Icons render at fixed UI size. |

Filter is **linear, never nearest**. Volley! is not pixel art, and nearest-neighbour hardens the drawn line into something mechanical the bible explicitly rejects.

### Folder structure

```
assets/
  characters/<name>/          sprites, animations, expressions for one character
  items/                      item sprites (shop and kit reuse the same PNG)
  ui/                         hand-drawn UI elements
  backgrounds/<venue>/        parallax layers, named layer_01_back to layer_NN_front
  vfx/                        hit sparks, miss reactions, streak glow
  props/                      ball, paddle, rack, mat, compendium, other diegetic objects
```

One asset, one canonical path. If the shop and the kit both show an item, they reference the same PNG. Duplicated sprites rot separately.

File names are `lower_snake_case.png`. Animation frames suffix the state: `martha_idle_01.png`, `martha_idle_02.png`, `martha_hit.png`. Registers suffix the file: `kitchen_real.png` alongside `kitchen_constructed.png`. Prefer a single file with a runtime shift (see [Register shift](#register-shift)) over duplicated assets whenever the bible's "shifting" mark can be expressed through palette and edge treatment rather than repainting.

---

## Animation

Volley!'s animation philosophy is **fewer frames, better chosen**. Technical choice follows.

### Format

**Individual PNG frames**, not sprite sheets. Reasons:

- Artists iterate on single frames without re-exporting a whole sheet.
- Godot's `AnimatedSprite2D` + `SpriteFrames` resource assembles frames in the editor with no rebuild step.
- Frame reordering, insertion, and deletion are trivial in version control.
- Sheets only win on memory; at Volley!'s character count that saving is in the tens of MB.

Sprite sheets are appropriate for **short, high-frequency FX** (hit sparks, ball trails) where frame count is small and fixed. Authored in Aseprite or equivalent, delivered as a single PNG plus a JSON manifest, imported via `SpriteFrames`.

### Rig

Characters use **`AnimatedSprite2D` with a `SpriteFrames` resource per character**. Stored as `.tres` under `resources/animations/<character>.tres`, referenced by the character scene. Each animation state (idle, hit, miss, react, enter, exit) is a named animation in the resource with its own frame list and FPS.

**Not AnimationPlayer keying a Sprite2D texture.** AnimationPlayer is reserved for timing-critical composite animation: camera shake, UI transitions, multi-node choreographed sequences (the shipment mat opening, The Break reveal). Keying sprite swaps through AnimationPlayer works but diffuses the source of truth across two resources and makes a simple frame swap a two-file edit.

### Target frame counts

Indicative budgets; the bible governs what earns more frames.

| State | Frames | FPS | Notes |
|---|---|---|---|
| Idle / breathing | 2-4 | 4-6 | Loop; small weight shift, not animation wallpaper. |
| Anticipation | 2-3 | 12 | Builds into contact. |
| Contact | 1-2 | held 2-4 frames | Time stretches on impact; holds are the animation. |
| Follow-through | 3-5 | 12 | Carries the energy out. |
| React (celebrate, sigh, shrug) | 4-8 | 8-12 | Body language; character moment. |
| Enter / exit | 3-6 | 12 | Scene transitions. |

**Anticipation, contact, follow-through on every meaningful action.** The bible's rule; the numbers above are scaffolding for it.

### Style-bend moments

The bible permits style to bend at emotional peaks. Those frames ship as their own animation state (`martha_hit_peak`) rather than in-line with the base state. This keeps the base read clean and lets the peak frame carry whatever loosening of line, palette, or perspective the moment wants without polluting the idle loop.

---

## Backgrounds

### Layering

Venues use **Parallax2D** (Godot 4.3+), already in use in `scenes/court.tscn`. Each venue has three to five layers:

1. **Back** — sky, distant silhouette. Slowest scroll.
2. **Mid-back** — far walls, windows, distant props.
3. **Mid** — playing surface, primary architecture. Scroll scale matches the camera 1:1 for gameplay layers.
4. **Mid-front** — near props, foreground trim. Slightly faster than mid.
5. **Front** — occasional foreground pass (a beam, a curtain edge) that sells depth. Optional.

Scroll scales tune per venue. The court stays composed; The Break reveal uses a looser, slower parallax to mark the register shift.

Layers are authored as **separate PNGs sized to the layer's visible range**, not full-resolution panoramas. A back layer that the camera only sees 2000px of is authored at 2000px, not 8000. Repeat, if needed, is handled by `Parallax2D.repeat_size`.

### Painting order

Backgrounds are painted **back-to-front with shared light and palette** (the bible's resolution to the "simple characters vs. rich worlds" tension). The light source is locked per venue before layers go into production; a layer painted against a different light has to be repainted.

### Interactive props in the background

Diegetic UI elements that live in the background layer (the pinboard, the shipment clipboard) are authored as **foreground sprites composed into the scene**, not painted into a background layer. This lets them animate, highlight, and receive input independently. The background layer provides the surface they sit on.

---

## Lighting

Volley!'s lighting is **painted first, runtime second.**

### Painted

Shadows, form lighting, and ambient occlusion are **painted into the sprites** by the artist. Oga's watercolour afternoons are not a shader; they are a painting. Runtime lighting cannot recover what the painting establishes, and fighting the painted light with runtime light produces the mechanical, over-rendered look the bible rejects.

### Runtime

Runtime lighting is reserved for three roles:

1. **Register shift.** `CanvasModulate` applied per venue swaps the global tint between constructed (warm, saturated) and real (cooler, muted). One node, one property animation; the art underneath does not change.
2. **Rhythm accents.** `Light2D` on specific emitters (the scoreboard on a milestone hit, the ball at peak streak) adds felt pulses without repainting frames. Short bursts, low energy, tuned to not overwhelm the painted light.
3. **Post-Break / Peace shifts.** A second `CanvasModulate` palette for post-break venues and for Peace. Same mechanism, different target.

`DirectionalLight2D` and `PointLight2D` with `shadow_enabled = true` are avoided; shadows come from painting. The ball's trail and hit spark FX are `GPUParticles2D` on an additive blend layer, not light.

### Register shift

The constructed-to-real shift is not a repaint. It is:

- `CanvasModulate.color` from the constructed register palette to the real register palette.
- Optional mild desaturation via a `CanvasItem` material shader (see [Shaders](#shaders)) on select layers.
- Background layer opacity tweaks: the constructed register's most "arranged" props (curtains, bunting) fade slightly in the real register.

Characters do not redraw across registers. Same sprite, different global tint. The bible's rule — "silhouettes hold across both registers; only the light, colour, and line quality shift" — is the contract this runtime shift upholds.

The Break itself is the exception: a scripted, one-time transition with authored keyframes in an `AnimationPlayer`, permitting stronger visual disruption than the routine register shift.

---

## Shaders

Kept minimal. Every shader is a named resource under `resources/shaders/` with a one-line comment describing when to use it.

Shipping list (spike-time):

- **`register_shift.gdshader`** — CanvasItem shader; global saturation and edge-softness offsets driven by one float. Bound to the register manager.
- **`painted_outline.gdshader`** — CanvasItem shader that thickens and breaks the existing painted outline at a per-sprite modulation. Used sparingly on a handful of props whose silhouettes need to harden in the real register; disabled by default.
- **`streak_glow.gdshader`** — additive CanvasItem shader on the ball when streak count crosses thresholds.

No screen-space post-process stack. If an effect is universal enough to sit at the Viewport level, it is painted into the backgrounds instead.

---

## UI

### Approach

**Diegetic first, Control-node second.** The bible calls for catalogues, racks, pinboards, and clipboards over menus. These are implemented as in-world sprites (`Sprite2D`, `AnimatedSprite2D`) under the appropriate scene, picked up by `Area2D` input where clickable.

Menus that cannot be diegetic (settings, pause, system prompts) use **Control nodes with a theme that carries the same hand**. The theme lives at `resources/themes/default_theme.tres` (already committed) and brings in:

- Hand-drawn button and panel textures via `StyleBoxTexture`.
- Hand-drawn font (display face) for game-world text.
- Quieter reading face for system copy.

Both faces defer to the bible; the theme slots them in once they lock.

### HUD

The HUD sits in a `CanvasLayer` and uses Control nodes. Every element goes through the theme. If a HUD element crosses into "could be a diegetic object" (the volley counter as a physical number wheel), it moves from Control to in-world sprite and out of the CanvasLayer.

### Input handling

Control nodes handle focus, theme overrides, and system text. In-world diegetic elements use `Area2D` with `input_pickable = true` or are children of a body with an `input_event` handler. Mixed handling is fine; the rule is: Control for system-chrome, in-world for fiction-chrome.

---

## VFX

### Particles

`GPUParticles2D` for hit sparks, miss reactions, streak glow, and ambient motes. CPU particles only where GPU particles misbehave on target hardware (the mobile renderer will validate this).

Authored as a **scene per effect**, saved under `scenes/vfx/<effect>.tscn`. Instanced by code at the effect's origin, then freed on `finished`. Reuse via pooling only after a profiled hotspot shows allocation pressure.

### Shakes and flashes

Camera shake is an `AnimationPlayer` on the `Camera2D` with short named animations keyed by event. Flashes are tween-driven `modulate` changes on the affected node, not a screen overlay.

### Time stretch

The bible's "time stretches at the moment of impact" is implemented as `Engine.time_scale` briefly dipped, scoped by a tween. Frame holds in the animation itself (see [Animation](#animation)) do the same work for the character; the time-scale dip adds the global felt slowdown.

---

## Asset delivery pipeline

The workflow that takes a finished asset from an artist's machine to the game.

1. **Brief** — the artist receives the bible, direction, this doc, and the ticket. Per-asset briefs reference the bible sections that apply rather than restating them.
2. **Draft** — artist delivers WIP through the shared board (not the repo) until sign-off.
3. **Final** — artist delivers the final PNG (and source file: `.psd`, `.ase`, `.clip`, `.procreate`) into a staging folder in the shared board. Source files are not committed to the repo; only the exported PNG is.
4. **Integration PR** — a Volley! contributor opens a PR that:
    - Places the PNG under the right `assets/...` path.
    - Commits the `.import` sidecar generated by opening Godot.
    - Wires the sprite into the relevant scene (`node_ops` + `save_scene`, never by hand-editing `.tscn`).
    - Adds an `AnimatedSprite2D` + `SpriteFrames` resource where animation is involved.
    - Verifies with `spatial_audit` and a smoke play.
5. **Review** — `asset-pipeline` reviewer on the PR checks import settings, path, and `.import` sidecar; `godot-scene` reviewer checks scene wiring.

The artist does not open PRs. The integration PR is the contract: everything needed to get the asset into the game lives there, reviewable in one place.

### File naming at delivery

Artists deliver with the target path baked into the filename so the integrator can drop it in without guessing:

```
characters_martha_idle_01.png
backgrounds_kitchen_layer_02_mid.png
items_grip_tape.png
vfx_hit_spark_frames.png
```

Underscore-separated; the first segment matches the folder under `assets/`. The integrator strips the prefix when committing.

### Source files

`.psd`, `.ase`, `.clip`, `.procreate` live in the shared board under a mirrored folder tree. Never committed to the repo. When an asset needs revision, the integrator links the PR to the source file path in the board; the artist edits the source, re-exports, re-delivers.

---

## Performance budgets

Indicative targets for a 1080p frame on the mobile renderer, idle-play load:

- **Draw calls:** under 200 during gameplay. Parallax2D layers and per-character `AnimatedSprite2D` dominate; batching is mostly free.
- **Sprite memory:** under 256 MB at steady state. Characters and backgrounds together. Per-venue background set under 64 MB.
- **Particles alive:** under 500 at peak. A hit spark plus ambient motes sits near 100.
- **Animation updates:** `AnimatedSprite2D` runs at the animation's authored FPS, not the monitor refresh rate. A 4-FPS idle does not cost more because the monitor is 144 Hz.

Budgets are re-verified with `perf_snapshot` once representative content ships. They exist to catch regressions, not to gate delivery.

---

## Godot version and addons

Volley! targets **Godot 4.6**. Parallax2D requires 4.3 or later; CanvasModulate, AnimatedSprite2D, and Light2D have been stable since 4.0.

Rendering-adjacent addons currently enabled: none. The pipeline above ships in core Godot. GodotIQ, GUT, config_hot_reload, gdfxr, and item_preview are authoring-side only and do not affect runtime rendering.

---

## Prototyping

The background layering approach described here is validated by `scenes/court.tscn`, which already uses `Parallax2D` with a `CourtBackground` root and a `BackgroundColor` `ColorRect`. Expanding that from one layer to a full three-to-five-layer venue is a scoped follow-up ticket; the pipeline does not wait on it.

---

## Open questions

- Exact `CanvasModulate` values per register. Blocks on the bible's palette section.
- Display and reading fonts for the UI theme. Blocks on typography.
- Whether any in-world text (signage, the ball rack's label strip) needs a separate font treatment. Deferred until UI work begins.
- Whether VFX lives in the mobile renderer's additive blend path as well as it does under Forward Plus. Validated when the renderer is switched.

---

## Changelog

- **2026-04-21:** first pass. Spike authored alongside the bible; fills the pipeline side of the bible/pipeline pair.
