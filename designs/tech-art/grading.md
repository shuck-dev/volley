# Colour Grade Pipeline

The garden in late afternoon is warm, saturated, gleaming. The same garden in Reality is cooler, looser, weather in the air. Same silhouettes, same staging, different register. Volley! ships both, and the seam where the artist's neutral PNG becomes a registered surface is a runtime colour grade.

This document fixes the grading contract: what the artist delivers, what the engine applies, and where each style's grade lives.

## Why a grade lives in code

Each Construction venue and Reality scene has its own colour register, locked per the canon in [the world bible](../art/bible.md) Section 3 and Section 15. Construction holds saturated colour and generous warm light; Reality pulls cooler, plainer, more atmospheric. Reconstruction is the arc between the two, not a third style; a Reconstruction scene renders in whichever style it sits inside.

Authoring every sprite twice, once for each style, is the path the bible already takes for character renders and venue paintings where the style shift is felt. Repainting is right when the line-weight, edge treatment, and pigment selection have to change with the style. Grading is right when the same painted surface needs to read warmer here, cooler there, without the artist redoing the work. Most surfaces sit in the second category: a prop on the workshop bench, a stray ball at rest, a gear-rack item, the friend's stall. The grade carries those.

## Authoring contract

The artist delivers neutral sprites against the rules already named in [the tech pipeline](../art/tech-pipeline.md): PNG, sRGB, 32-bit with alpha, no embedded profile, painted at the @2x density the pipeline calls for. Painted shadow and form lighting stay in the sprite; the grade does not replace them. The painting carries the light direction, the modelling, the weight; the grade shifts the colour temperature, the saturation, the contrast curve.

Per-character variation rides the grade rather than fighting it. A particular outfit colour is authored against the neutral baseline; the LUT modulates everything in the frame uniformly, so a character whose blue sits a notch warmer than the cast in Construction sits a notch warmer than the cast in Reality too. The relationship holds across styles because the grade is uniform.

Surfaces that need to stay colour-stable across every style live outside the graded layer. A UI mark whose meaning is its colour, a key prop that has to read the same in Construction and Reality, both sit on a separate `CanvasLayer` that the grade does not touch. The Six Marks rule that silhouettes hold while light, colour, and line quality shift gets its colour-stable counterpart from this exemption: a few surfaces are exempt from the shift on purpose.

## Per-style LUT

Construction and Reality each carry one LUT. Construction's pushes saturation and warmth, holds shadows warm, lifts the midtone toward the gold-and-honey range the bible names. Reality's pulls toward the naturalistic: a notch of saturation off, a cooler shadow, a midtone that lets weather sit in the air.

Reconstruction does not get a LUT. Construction venues across Reconstruction wear the Construction LUT and the bible's "weathering" effect is delivered through the LUT itself easing toward a slightly muted variant as the arc progresses; Reality scenes wear the Reality LUT throughout. The two styles stay distinct in code as they do in the canon.

## Per-venue overrides

Each Construction venue layers a venue-tinted LUT on top of, or in place of, the base Construction LUT. The underwater venue greens; the meteor venue oranges and pinks under nebula glow; the canopy venue pulls honey through leaves. The base Construction LUT carries the register; the venue LUT carries the local light. Stacking is the default because most venues want the Construction warmth held under the venue tint; replacement is reserved for venues whose colour is so specific that the base would fight it.

Reality scenes work the same way. The closed shop sits under one tint, the cliff under another, the sister's place under a third. Each tint is small; the bible's "atmosphere over drama" rule for Reality applies to the grade as much as to the painting.

## Godot implementation

The grade lives in a fragment shader on a `CanvasLayer` above the world layer and below the screen-space HUD. The shader samples a 3D LUT texture, or a 2D LUT strip image where the texture format is not available. The shader itself is small and rarely changes; the LUT asset is the variable. Switching style means swapping the LUT asset, not rewriting the shader. Switching venue swaps the venue tint, layered through the same shader.

The screen-space HUD CanvasLayer sits above the graded layer so the developer HUD and any colour-stable UI escape the grade by construction. Diegetic surfaces inside the world (the volley counter on its plaque, the catalogue on the friend's table) wear the grade with the rest of the venue, which is the right answer; they are part of the world the player sees.

## LUT authoring

LUTs are authored in any tool that supports them: Photoshop, Affinity Photo, DaVinci Resolve, free tools like LUT Calculator. The artist works in their tool of choice, exports as a 3D LUT (`.cube`) or as a 2D strip image readable by Godot, and the integrator commits the LUT asset under `resources/grades/` with the rest of the rendering resources. The pipeline that places a sprite under `assets/...` places a LUT under `resources/grades/` with the same care.

Iteration is fast because the LUT is the variable. A grade tweak ships as one file; the sprites stay where they are.

## Limits

A LUT is a uniform colour transform. It cannot do per-element colour swaps or selective hue isolation; a sprite that needs its red turned green while everything else holds is not a grade problem, it is a repaint or a per-sprite shader problem. Surfaces that need to remain colour-stable across all styles live above the graded layer or carry an inverse grade applied per-sprite to cancel the layer they sit inside.

The grade also cannot recover what the painting establishes. A sprite painted with cool light cannot be made warm by a warm LUT; the painted shadows fight the grade and the result reads wrong. This is why the painting carries the form light and the grade carries only the style shift. The bible's note that runtime lighting cannot recover what the painting establishes applies to the grade too: paint first, grade second.

The constructed-to-real shift inside a venue, where the same place is rendered in both styles, remains a repaint per [the tech pipeline](../art/tech-pipeline.md). The grade handles the per-style shift; the repaint handles the per-meaning shift. They are different jobs.

---

For broader tech context the artist works against, see [the artist tech context](../01-prototype/artist-tech-context.md). For the asset delivery pipeline the LUT slots into, see [the tech pipeline](../art/tech-pipeline.md). For the per-style colour canon the grades implement, see [the world bible](../art/bible.md) Section 3 and Section 15.
