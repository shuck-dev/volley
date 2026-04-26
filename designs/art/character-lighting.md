# Character Lighting Pipeline

Post-prototype scope. Volley!'s prototype authors character lighting into the sprite per venue: the painted light is the light the characters see, and the characters are painted to match it. This doc captures the dynamic light-state pipeline planned for the full-pass art phase, so the direction is recorded without committing prototype time to implementation.

Partner document to the [Tech Art Pipeline](tech-pipeline.md) and [Art Bible](bible.md).

---

## Why a dynamic layer at all

The prototype's painted-first approach works because characters occupy a narrow spatial range per venue and the camera is near-static. Once venues grow traversal variety (entering from the lit side, moving under a window, exiting into shadow), a single painted state per character stops covering the venue's light. Two options: repaint the venue to flatten light, or layer cheap runtime tricks over carefully authored base art.

Other painted-first 2D games take the second route. Per Ori and the Blind Forest's GDC breakdowns, Moon Studios composite a 3D-rendered character onto painted backgrounds with an additive side-mask that fakes a directional source and flips with the sprite. Per the gamedeveloper.com "Dynamic 2D Character Lighting" write-up, a screen-space light map blurred against a character alpha mask is the common runtime layer for otherwise hand-painted worlds. Per Hyper Light Drifter's art-direction analyses, flat-colour pixel art takes a soft overlay gradient at low opacity to carry the venue's light without washing the sprite. Volley!'s painted-first brief precludes a 3D render, but the pattern holds: author the lighting into the sprite, lean on one or two runtime adjuncts to stitch the character into the painted venue.

---

## Pipeline

1. **Authored light states per venue.** Each character ships **3 to 5 painted light states** per venue they appear in: a base state matched to the venue's locked painted light, plus one state per traversal pose the animator flags during layout (e.g. "entering from the lit side", "under the window", "exiting into shadow"). States are `.tres` `SpriteFrames` animations named `<state>_<light>` (`idle_base`, `idle_window`, `enter_left`) under `resources/animations/<character>.tres`. The base state is mandatory; additional states are added only when layout demands them, not speculatively.
2. **Runtime selection.** A `CharacterLighting` node on each character scene reads a per-venue `LightingZone` hint (a small `Area2D` grid painted over the venue during integration, keyed to the relevant light state name) and switches the `AnimatedSprite2D` to the matching named animation when the character enters a zone. No zone overlap means fall through to the base state.
3. **Runtime blend.** Transitions between light states tween `modulate` over 150-250 ms while the animation frame list swaps, so the visual change is a soft colour ease rather than a cut. This is the only runtime colour operation on characters; no `Light2D` with `shadow_enabled`, no per-pixel recolour.
4. **Budget.** Per character per venue: base state, up to 4 additional light states, up to 5 total. A character appearing in 4 venues therefore ships up to 20 light-state sets across its lifetime. States are repaints of the base animation at the same frame count, so the marginal cost scales with animation length, not with venue count.
5. **Fallback.** If no authored state matches the character's position (new traversal pattern, late-added venue cue), the base state plays with a `modulate` pulled from the venue's `LightingZone` tint. This is visibly less accurate than an authored state and exists only to unblock gameplay integration while the painted state is authored.

`LightingZone` and `CharacterLighting` are specified here; implementation lands alongside the first venue that needs more than the base state. The bible's "silhouettes hold; only the light, colour, and line quality shift" rule covers the acceptable variation between states.
