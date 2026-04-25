# Volley! Artist Tech Context

A companion to `artist-brief.md` and `artist-world-bible.md`. The brief is the deal; the bible is the world; this is the engine the world is painted into.

This doc is the practical context the brief leaves out: how the scene is layered, what the engine does with what you draw, and what the format asks of the line. Read it once, keep it nearby.

---

## Parallax 2D, in plain terms

A Volley! venue is built to read as somewhere a person could walk into, not as a backdrop with figures on top.

Godot calls the rig `Parallax2D`: a stack of painted layers, each scrolling at its own rate as the camera moves. A deep background drifts. A near background sits behind the rally. The court itself, where the partners meet the ball, is a mid-ground plane. The foreground sits forward of the rally: a feeder leg, a corner of the friend's stall awning, a tabletop edge, a vine catching on the camera. The court already runs a single-layer version of this in `scenes/court.tscn`, which is the seed the rest grows from.

When you paint a layer, you are painting a slice of the world at a specific distance. A near layer carries the kind of detail the player's eye lands on between rallies. A deep layer can carry atmosphere: a wall of warm afternoon, a wash of submerged green, the suggestion of a tree. The friend's stall sits forward; a row of distant rooftops sits back; the wonder past the locked gate sits further back still.

The illusion holds on consistency. Light direction is locked per venue before any layer goes into production: a backlit afternoon in the garden, sunlight filtering through water in the underwater venue, nebula glow from above on the meteor. Every layer paints to the same source, characters included. Painted shadow on the friend's awning matches painted shadow on the racquet matches painted shadow on the back wall. Nothing in this rig depends on shaders or runtime lighting; the painting carries it.

World-space mid and foreground layers are interactive. Resting balls, items the player drags, the friend at the stall, the tinkerer at the workshop: all live in the world layer and respond to the player's hand.

---

## The two layers in the engine

Two engine layers are worth knowing about by name, because they shape what kind of thing you are drawing.

**The world layer.** Almost everything sits here: the painted backgrounds, the court, the racquets, the ball, the friend's stall, the feeders, the workshop, characters. This is where the rally lives. When the camera moves or zooms, everything in the world layer moves with it. Anything diegetic, anything inside the fiction, lives here.

**The screen-space dev overlay.** A separate layer (`CanvasLayer`) that ignores the camera. Only the developer HUD lives here: framerate, debug toggles, state inspection text. Player-facing game state never lives here. The volley counter is a wooden plaque on the court. The personal best is a sign on the wall. The friendship-point balance is a counter the friend keeps. The shipment landing is a thump and a small pulse on the mat. The world tells the player what is happening, in objects the player can point at.

The shorthand: developer HUD on the screen-space layer, fiction in the world.

---

## Racquets, partners, anchor points

Partners hold racquets. The protagonist holds one. Martha holds one. Each later partner will. Characters and racquets are separate things: the racquet is a tool the partner picks up.

Items attach to a racquet at named anchor points: a grip on the handle, a piece of equipment on the head, a tape across one side. The artist's racquet design carries through the venues; the partner holding it changes with the cast.

---

## Court geometry, briefly

The bible covers this in full. For engine purposes:

- **Top edge.** A hard ceiling; the ball bounces.
- **Bottom edge.** Pong-style floor; the ball bounces. Hitting it does not end the rally.
- **Left side.** The protagonist's side, open behind them. A ball that passes is a miss.
- **Right side.** The partner's side (a wall before the first partner arrives), open behind them. A ball that passes is a miss.

When the ball misses, it does not despawn. It keeps its velocity, rolls out of the court, decelerates on the venue floor, and rests where physics drops it.

---

## The ball at rest, and why helpers exist

Balls do not naturally roll into the feeder. A miss leaves the ball wherever the floor and gravity decide; a stray ball at rest is the default state, not a bug. The venue can hold a couple of resting balls scattered across the mid and foreground, alongside the rally on court, the friend at her stall, the tinkerer at the workshop, and the racks of inactive equipment.

Helpers exist diegetically for exactly this reason. A dog can fetch a stray ball back. The player can pick one up and drop it into the feeder. The feeder and the gear rack are drop targets: a ball that crosses a feeder slot snaps into it; equipment that lands on the gear rack settles into a slot. The artist's read on the venue needs to leave room for that loose population and the small acts that gather it.

---

## Format: where the work lives

Volley! plays in a full window by default. A Desktop widget mode is an additional surface that pins a smaller view to the user's desktop; the rendering approach is the same in both. Web export is the primary distribution channel today.

The work needs to read at sizes well below a feature-film frame. The bible's calibration paragraph is the answer in one line: characters as simple as Ranking of Kings, painterly atmosphere across the backgrounds, the painterly feel sustained through layered depth and shared light rather than per-character full-render. Per-character Cuphead-level rendering is out of reach at this scale; the rendering load goes into the venue; the simple-shape discipline holds the characters.

This shapes a few practical asks:

- **Bold silhouettes.** A character's silhouette identifies them before the line does. If two characters could be confused at small size, one of their silhouettes changes.
- **Line that survives downscale.** The line has weight that holds when the asset is rendered into a small window. Mechanical-precise vector lines and per-character feathered detail both soften badly at small scale.
- **Painterly backgrounds carry the world.** Atmosphere, depth, light belong to the painted layers. Characters belong against them, simply drawn, animated through body language.
- **Diegetic state.** Information lives on objects the player can point at. The volley counter is a thing in the world. The friendship-point balance is a thing in the world.

---

## Engine-side DOs and DON'Ts

The bible covers the visual register. These are the engine-layer asks the bible cannot speak to.

**DO:**

- **Paint to a single locked light direction per venue.** Foreground props, characters, and backgrounds share one source so the layered illusion holds.
- **Keep the line heavy enough to survive downscale.** Web export and a smaller widget window are both possible, and per-character feathered detail and mechanical-precise vector lines both soften badly there.
- **Put player-facing state in the world.** A plaque on the court, a sign on the wall, a counter at the friend's stall, a thump on the mat. The world layer carries the fiction; the screen-space overlay is dev-only.
- **Plan rendering load for the venue, not the character.** Painted backgrounds carry atmosphere and depth; characters stay in the simple-shape register so animation does the acting work.

**DON'T:**

- **Mismatch light direction across layers.** A foreground catching sun from one side while a background catches it from another flattens the illusion.
- **Use screen-space banners, popups, or floating numbers** for anything the player needs to read about the rally, the economy, or progression. That layer is for framerate and debug toggles.
- **Reach for shaders or runtime lighting tricks** to fake depth. The painting carries it; the rig is layers, parallax, and shared light.

---

## A pointer to the other tech-art doc

The companion engineering-side doc is `designs/art/tech-pipeline.md`. It covers the asset-delivery side of the same conversation: file formats, import settings, folder structure, animation rigging, performance budgets, the integration-PR contract.

You do not need to read the pipeline doc on day one. The integrator handles the import side, and per-asset briefs link back to the relevant pipeline sections. If something here pushes against your instincts on the work, push back.
