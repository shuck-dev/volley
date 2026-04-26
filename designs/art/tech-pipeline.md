# Tech Art Pipeline

How Volley!'s visual direction becomes Godot. Partner document to the [Art Bible](bible.md): the bible says what the work feels like, this doc says how it gets built.

This is a living spike. Colours, typography, and per-character notes still route through the bible. Pipeline structure is locked here so contributors can deliver art against it before the final style guide lands.

---

## Game shape

Volley! is 2D throughout. Hand-drawn sprites, Control-node UI, Parallax2D backgrounds. Characters are simple and expressive; environments carry depth through layered, painted backgrounds. Two styles share the same assets where possible and diverge through palette, light, and edge treatment.

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

Deliverables target their intended on-screen role, with headroom for upscaling. The base resolution is 1080p, but 4K and ultrawide are first-class display targets: assets authored at exactly 1x will soften when the viewport scales up. The working rule:

- **Characters, props, UI marks**: author at **@2x the logical size** at 1080p. A paddle that reads as 40x200 logical pixels is delivered at 80x400. The runtime downscale is gentler than the 4K upscale, and the drawn line keeps its weight in both directions.
- **Backgrounds and layered parallax**: author at **@2x the visible range** of each layer (see [Backgrounds](#backgrounds)). A layer the camera sees 2000px of at 1080p is delivered at 4000px.
- **SVG marks** (graphic props, UI glyphs) stay vector where the bible's line allows.

Two authored scales ship alongside the @2x base:

- **@4x** for sprites that may appear zoomed (cutscenes, The Break reveal, marketing crops) or that must stay crisp on 4K displays where even the @2x base reveals softening.
- **@1x** only where an asset is shown much smaller in UI than in the world (item thumbnails) and aliasing at runtime-downscale is visible.

Default to @2x only. Add scales as the need shows up in review, not preemptively. The consistent rule is that artists author above target pixel density so the downscale path carries the weight, not the upscale path.

### Import

Each PNG has a sibling `.import` file committed to the repo. Import settings per sprite class:

| Class | Filter | Mipmaps | Fix alpha border | Notes |
|---|---|---|---|---|
| Characters | Linear | Off | On | The line must stay crisp; nearest-neighbour reads pixel-art, linear with mipmaps off reads drawn. |
| Surfaces (props, items, UI marks, signage) | Linear | Off | On | Same hand across world and HUD; render at roughly native scale, so mipmaps waste memory. |
| Backgrounds | Linear | On | On | Parallax2D layers may render at fractional scales; mipmaps prevent shimmer on slow drift. |

Filter is **linear, never nearest**. Volley! is not pixel art, and nearest-neighbour hardens the drawn line into something mechanical the bible explicitly rejects.

### Folder structure

The axis that matters is **how the asset behaves at runtime**, not who drew it or where it's shown. Props, items, and UI marks are drawn the same, animate the same, and reuse the same PNG across contexts; they are one folder. Backgrounds layer and parallax; they are their own folder. Characters have rigs and named animation states; they are their own folder. VFX are frame-burst effects; they are their own folder.

```
assets/
  characters/<name>/          sprites, animations, expressions for one character
  surfaces/                   props, items, UI marks, in-world signage (one PNG, reused across shop, kit, HUD, world)
  backgrounds/<venue>/        parallax layers, named layer_01_back to layer_NN_front
  vfx/                        hit sparks, miss reactions, streak glow
```

One asset, one canonical path. If the shop and the kit both show the same item, they reference the same PNG in `surfaces/`. If the pinboard shows it in the world and a HUD slot shows it as an icon, same file. Duplicated sprites rot separately.

File names are `lower_snake_case.png`. Animation frames suffix the state: `martha_idle_01.png`, `martha_idle_02.png`, `martha_hit.png`. Styles suffix the file: `kitchen_real.png` alongside `kitchen_constructed.png`. Each style ships its own painted asset (see [Style shift](#style-shift)).

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

Indicative budgets, framed in traditional animator terms. The base tick is **24 frames per second**, matching the century-old feature-animation standard: per traditional animation practice, fully animated films are drawn on twos (12 unique drawings per second) and step up to ones (24) for fast action, so 24 fps is the tick the drawings slot into rather than the drawing rate itself. Indie 2D game references sit on the same tick: per Cuphead's creators, StudioMDHR animate on ones at 24 fps while the game runs at 60; per Hollow Knight's art breakdowns and Rain World's rigging, hand-drawn states read at roughly 12 unique drawings per second even when the engine presents them at 60. Volley! picks 24 as the base tick and defaults to on-twos, stepping up or down per state.

"On ones" is every tick (24 dps), "on twos" is every other tick (12 dps), "on fours" every fourth (6 dps), "on sixes" every sixth (4 dps). Godot's `SpriteFrames` authors in FPS rather than step counts; the column below gives both so an animator and an integrator read the same row.

| State | Frames | Step | Equivalent FPS | Notes |
|---|---|---|---|---|
| Idle / breathing | 2-4 | on fours to sixes | 4-6 | Loop; small weight shift, not animation wallpaper. |
| Anticipation | 2-3 | on twos | 12 | Builds into contact. |
| Contact | 1-2 | held (step paused 2-4 ticks) | 24 while moving, held on impact | Time stretches on impact; holds are the animation. |
| Follow-through | 3-5 | on twos | 12 | Carries the energy out. |
| React (celebrate, sigh, shrug) | 4-8 | on twos to threes | 8-12 | Body language; character moment. |
| Enter / exit | 3-6 | on twos | 12 | Scene transitions. |

**Anticipation, contact, follow-through on every meaningful action.** The bible's rule; the numbers above are scaffolding for it. Steps may vary within a single state: an idle breathing on fours may drop to sixes at the end of the loop, a follow-through on twos may ease into fours as energy dissipates. Animators pick the step that reads; the table is the starting point, not the ceiling.

### Style-bend moments

The bible permits style to bend at emotional peaks. Those frames ship as their own animation state (`martha_hit_peak`) rather than in-line with the base state. This keeps the base read clean and lets the peak frame carry whatever loosening of line, palette, or perspective the moment wants without polluting the idle loop.

---

## Backgrounds

### Layering

Venues use **Parallax2D** (available since Godot 4.3; Volley! runs on 4.6.2, the version pinned in `project.godot`), already in use in `scenes/court.tscn`. Each venue has three to five layers, named by where they sit relative to the playing surface:

1. **Deep background.** Sky, distant silhouette. Slowest scroll.
2. **Background.** Far walls, windows, distant props.
3. **Playing surface.** Primary architecture. Scroll scale matches the camera 1:1 for gameplay layers.
4. **Near foreground.** Near props, foreground trim. Slightly faster than the playing surface.
5. **Foreground.** Occasional foreground pass (a beam, a curtain edge) that sells depth. Optional.

Scroll scales tune per venue. The court stays composed; The Break reveal uses a looser, slower parallax to mark the style shift.

Layers are authored as **separate PNGs sized to the layer's visible range** (at the @2x authoring density from [Sprites](#sprites)), not full-resolution panoramas. A background layer the camera only sees 2000 logical pixels of is authored at 4000px, not at 8000px or the full world width. Repeat, if needed, is handled by `Parallax2D.repeat_size`.

### Painting order

Backgrounds are painted **back-to-front with shared light and palette** (the bible's resolution to the "simple characters vs. rich worlds" tension). The light source is locked per venue before layers go into production; a layer painted against a different light has to be repainted.

### Interactive props in the background

Diegetic UI elements that live in the background layer (the pinboard, the shipment clipboard) are authored as **foreground sprites composed into the scene**, not painted into a background layer. This lets them animate, highlight, and receive input independently. The background layer provides the surface they sit on.

---

## Lighting

Volley!'s lighting is **painted first, runtime second.**

### Painted

Shadows, form lighting, and ambient occlusion are **painted into the sprites** by the artist. Oga's watercolour afternoons are not a shader; they are a painting. Runtime lighting cannot recover what the painting establishes, and fighting the painted light with runtime light produces the mechanical, over-rendered look the bible rejects.

This is tractable because characters occupy a narrow spatial range per venue: paddle positions are constrained, the ball's path is readable, and the camera is near-static. The painted light in a venue is the light the characters see, and the characters are painted to match it.

**Reference.** Two painted-first games set the pattern. Per Studio MDHR's public production notes and GDC Animation Bootcamp talk, Cuphead authors every frame on paper, inks by hand, then colours and shades each frame individually; backgrounds are actual watercolour paintings, and no runtime lighting is applied to the characters (all form light and shadow lives in the paint, with film-grain and cel-scratch passes layered on top as static grade). Per Team Cherry's Unity "Made with" case study and art breakdowns on 80.lv, Hollow Knight draws its sprites flat in Photoshop with shadow and form baked in, then uses Unity's 2D lights as atmosphere only: lamps and fireflies as local `Light2D`-style emitters, and a per-region coloured backlight tint that shifts mood from area to area without repainting the sprite. Volley! sits between the two: closer to Cuphead on character painting (shadow and form baked per state), closer to Hollow Knight on venue mood (localised runtime accents plus authored light states instead of a global tint).

### Character lighting

Character lighting is authored into the sprite per venue. The dynamic light-state pipeline (authored states, `LightingZone`, `CharacterLighting`, runtime blend) is post-prototype scope and lives in [character-lighting.md](character-lighting.md); the prototype ships a single painted base state per character per venue.

### Runtime

Runtime lighting is reserved for two roles:

1. **Rhythm accents.** `Light2D` on specific emitters (the scoreboard on a milestone hit, the ball at peak streak) adds felt pulses without repainting frames. Short bursts, low energy, tuned not to overwhelm the painted light.
2. **Mood timing.** Subtle scripted palette beats (a window filling with sun during a long idle, the court dimming when the player misses three in a row) are delivered through art-direction-approved modulation curves on specific layers, not a single colour pushed over the whole frame. Global tint turns the picture garish; the direction calls for targeted palette moves that respect the painted light.

`DirectionalLight2D` and `PointLight2D` with `shadow_enabled = true` are avoided; shadows come from painting. The ball's trail and hit spark FX are `GPUParticles2D` on an additive blend layer, not light.

### Style shift

**The constructed-to-real shift is a repaint.** This is the only way it actually looks good. Shader tricks and global tint cannot recover the reweighted line, the cooler pigments, the loosened edges that make the real style feel like the same world seen honestly; attempting to fake it produces the "filter over the same image" look the bible explicitly rejects.

Each venue ships two painted sets:

- **Constructed style.** Warm, saturated, arranged. The world as the player wants to see it.
- **Real style.** Cooler, muted, looser. Same silhouettes, same staging, repainted.

Characters follow the same rule: constructed and real sprite sets per character where the style shift is felt. The bible's "silhouettes hold across both styles; only the light, colour, and line quality shift" rule governs what stays and what moves.

At runtime the shift is a crossfade between the two painted sets, timed to the narrative beat, delivered through a `StyleManager` that swaps sprite textures on affected nodes and tweens opacity between them. Shaders and modulation are adjuncts used only where the repaint itself does not need help: a mild saturation ease on the frame during the crossfade, a brief dimming of over-arranged props as the real style settles in. The heavy lifting is paint.

The Break itself is the exception: a scripted, one-time transition with authored keyframes in an `AnimationPlayer`, permitting stronger visual disruption than the routine style shift.

---

## Shaders

Kept minimal. Every shader is a named resource under `resources/shaders/` with a one-line comment describing when to use it.

Shipping list (spike-time):

- **`style_shift.gdshader`:** CanvasItem shader used only as an easing adjunct during a style crossfade (saturation and edge-softness offsets driven by one float). The shift itself is the repaint; this shader smooths the transition while the painted sets swap.
- **`painted_outline.gdshader`:** CanvasItem shader that thickens and breaks the existing painted outline at a per-sprite modulation. Used sparingly on a handful of props whose silhouettes need to harden in the real style; disabled by default.
- **`streak_glow.gdshader`:** additive CanvasItem shader on the ball when streak count crosses thresholds.

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

1. **Brief.** The artist receives the bible, direction, this doc, and the ticket. Per-asset briefs reference the bible sections that apply rather than restating them.
2. **Draft.** Artist delivers WIP through the shared board (not the repo) until sign-off.
3. **Final.** Artist delivers the final PNG (and source file: `.psd`, `.ase`, `.clip`, `.procreate`) into a staging folder in the shared board. Source files are not committed to the repo; only the exported PNG is.
4. **Integration PR.** A Volley! contributor opens a PR that:
    - Places the PNG under the right `assets/...` path.
    - Commits the `.import` sidecar generated by opening Godot.
    - Wires the sprite into the relevant scene (`node_ops` + `save_scene`, never by hand-editing `.tscn`).
    - Adds an `AnimatedSprite2D` + `SpriteFrames` resource where animation is involved.
    - Verifies with `spatial_audit` and a smoke play.
5. **Review.** The PR carries the [`asset`](../process/labels.md#art) label (art, produce tier). Label-dispatched specialist reviewers pick it up from there; asset-pipeline checks import settings, path, and `.import` sidecar, and godot-scene checks scene wiring. Integration work that grows a new engine capability instead carries [`feature`](../process/labels.md#tech) (tech, produce); spikes like this document carry [`spike`](../process/labels.md#tech).

The artist does not open PRs. The integration PR is the contract: everything needed to get the asset into the game lives there, reviewable in one place.

### File naming at delivery

Artists deliver with the target path baked into the filename so the integrator can drop it in without guessing:

```
characters_martha_idle_01.png
backgrounds_kitchen_layer_02_mid.png
surfaces_grip_tape.png
vfx_hit_spark_frames.png
```

Underscore-separated; the first segment matches the folder under `assets/`. The integrator strips the prefix when committing.

Frame indexing is two-digit zero-padded (`_01`, `_02`, …, `_99`). If an animation runs past 99 frames, switch to letter indexing (`_a`, `_b`, …, `_z`, `_aa`, …) rather than widening to three digits; the letter sequence reads unambiguously and sorts correctly at any count, and 100+ frames on a single state is rare enough that the visual break from digits is a useful signal something has gone outside the frame budget.

### Source files

`.psd`, `.ase`, `.clip`, `.procreate` live in the shared board under a mirrored folder tree. Never committed to the repo. When an asset needs revision, the integrator links the PR to the source file path in the board; the artist edits the source, re-exports, re-delivers.

---

## Performance budgets

Indicative targets for a 1080p frame on the mobile renderer, idle-play load. These apply to **first-pass art shipped on the web build**, where the iOS Safari ceiling is the binding constraint. When full-pass art is authored, the web build is shelved; full-pass budgets target desktop only, where neither the 256 MB memory ceiling nor the per-venue 64 MB figure apply. Do not compress or downsample full-pass art to fit the web figures below.

- **Draw calls:** under 200 during gameplay. Parallax2D layers and per-character `AnimatedSprite2D` dominate; batching is mostly free. Arm's GPU Best Practices guide recommends staying under 500 per frame on OpenGL ES and under 1000 on Vulkan for mobile-class hardware; 200 keeps Volley! comfortably inside that envelope with headroom for the layer count a painted venue implies. Desktop-only full-pass art relaxes this ceiling.
- **Sprite memory:** under 256 MB at steady state for first-pass web. Characters and backgrounds together. Per-venue background set under 64 MB. The 256 MB ceiling sits below iOS Safari's observed WebGL/canvas pressure point (per Apple Developer Forums and the WebKit `Total canvas memory use exceeds the maximum limit (256mb)` error surfaced in Unity and Babylon.js WebGL threads, individual-tab allocations in that range push Mobile Safari toward GPU-process reload), leaving headroom for audio, code, and engine overhead inside the broader 2-3 GB per-tab envelope Safari allows. The 64 MB per-venue figure is sized against Godot 4's VRAM compression behaviour: ASTC 4x4 or ETC2 (per the Godot importer docs) takes a 4096x4096 RGBA layer from 64 MB uncompressed to roughly 16 MB on the GPU, so a venue with four to five @2x parallax layers stays well inside the envelope even before the painted sets and character states load. Full-pass art targets desktop only: no web ceiling applies, and per-venue allocation grows to whatever the desktop VRAM envelope supports. Budgets are indicative and re-verified with `perf_snapshot` once a full venue ships.
- **Particles alive:** under 500 at peak. A hit spark plus ambient motes sits near 100.
- **Animation updates:** `AnimatedSprite2D` runs at the animation's authored FPS, not the monitor refresh rate. A 4-FPS idle does not cost more because the monitor is 144 Hz.

Budgets are re-verified with `perf_snapshot` once representative content ships. They exist to catch regressions, not to gate delivery.

---

## Godot version and addons

Volley! targets **Godot 4.6.2** (the version pinned in `project.godot`). Parallax2D requires 4.3 or later; CanvasModulate, AnimatedSprite2D, and Light2D have been stable since 4.0.

Rendering-adjacent addons currently enabled: none. The pipeline above ships in core Godot. GodotIQ, GUT, config_hot_reload, gdfxr, and item_preview are authoring-side only and do not affect runtime rendering.

---

## Prototyping

The background layering approach described here is validated by `scenes/court.tscn`, which already uses `Parallax2D` with a `CourtBackground` root and a `BackgroundColor` `ColorRect`. Expanding that from one layer to a full three-to-five-layer venue is a scoped follow-up ticket; the pipeline does not wait on it.

---

## Open questions

- In-world text (signage, the ball rack's label strip) font treatment. Handled per-surface as those surfaces are authored, not as a pipeline-level decision; each surface picks a treatment that suits the painted context it sits in.

Resolved into tickets: per-register painted palettes ([SH-184](https://linear.app/shuck-games/issue/SH-184/per-register-painted-palettes)), UI theme typography ([SH-185](https://linear.app/shuck-games/issue/SH-185/ui-theme-typography)), VFX additive blend under the mobile renderer ([SH-186](https://linear.app/shuck-games/issue/SH-186/vfx-additive-blend-under-mobile-renderer)).
