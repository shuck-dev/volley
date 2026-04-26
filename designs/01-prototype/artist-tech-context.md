# Volley! Artist Tech Context

A companion to `artist-brief.md` and `artist-world-bible.md`. The brief is the deal; the bible is the world; this is the engine the world is painted into.

The rig is Godot 4. The camera is 2D. Depth comes from layered painted planes scrolling at different rates, not from 3D geometry or runtime lighting. The bible covers tone and visual canon; this doc covers the format the work has to read at and the rules the rig holds it to.

---

## Two layers, one diegetic

The engine has two layers, and they do different jobs.

The world layer holds the fiction. Painted backgrounds, the court, the racquets, the ball, the friend at her stall, the feeders, the workshop, the characters: all of it sits in the world layer, and the camera carries the layer with it as it moves and zooms. Anything the player can see in-fiction lives here.

The screen-space layer is a separate `CanvasLayer` that ignores the camera. Only the developer HUD sits on it: framerate, debug toggles, state inspection. Player-facing state never lives there. The volley counter is a wooden plaque on the court. The personal best is a sign on the wall. The friendship-point balance is a counter the friend keeps. A shipment landing is a thump and a small pulse on the mat. The world tells the player what is happening, in objects the player can point at.

---

## Parallax 2D

Each venue is a `Parallax2D` rig: a stack of painted layers, each scrolling at its own rate as the camera moves. A deep background drifts. A near background sits behind the rally. The court itself, where the partners meet the ball, is a mid-ground plane. Forward of the rally sits a foreground layer: a feeder leg, a corner of an awning, a tabletop edge, a vine catching on the camera. The court already runs a single-layer version of this in `scenes/court.tscn`; the rest grows from that seed.

Depth comes from the layering. A near layer carries the detail the eye lands on between rallies. A deep layer carries atmosphere: a wash of warm afternoon, submerged green, the suggestion of a tree behind a wall. The friend's stall sits forward; the row of distant rooftops sits back; what lies past the locked gate sits further back still.

Light direction is locked per venue before any layer goes into production. A backlit afternoon in the garden, sunlight filtering down through water in the underwater venue, nebula glow from above on the meteor. Every layer paints to the same source, characters included; painted shadow on the awning matches painted shadow on the racquet matches painted shadow on the back wall. The rig leans on no runtime lighting; the painting carries it.

The mid and foreground layers are interactive. Resting balls, draggable items, the friend at her stall, the tinkerer at the workshop: all live in the world layer and respond to the player's hand.

---

## Court geometry

The bible covers the court in full. For engine purposes: the court has a hard top edge and a hard bottom edge that bounce the ball, an open left side and an open right side where a ball that passes is a miss. A miss does not despawn. The ball keeps its velocity, rolls out of the court, decelerates on the venue floor, and rests where physics drops it.

A stray ball at rest is the default state, not a bug. A venue can hold a couple of them scattered across the mid and foreground, alongside the rally on court, the friend at her stall, the tinkerer at the workshop, and the racks of inactive equipment.

Helpers exist diegetically for exactly this reason. A dog can fetch a stray ball back. The player can pick one up and drop it into the feeder. The feeder and the gear rack are drop targets: a ball that crosses a feeder slot snaps into it; equipment that lands on the gear rack settles into a slot. The venue read leaves room for that loose population and the small acts that gather it.

---

## Anchor points

Partners hold racquets; characters and racquets are separate things. The protagonist holds one. Martha holds one. Each later partner will. The racquet is a tool the partner picks up.

Items attach to a racquet at named anchor points: a grip on the handle, a piece of equipment on the head, a tape across one side. The racquet design carries through the venues; the partner holding it changes with the cast.

---

## Format

Volley! plays in a full window by default. A Desktop widget mode pins a smaller view to the user's desktop; the rendering approach is the same in both. Web export is the primary distribution channel today.

That asks two things of the work. The line carries weight that holds when the asset renders into a small window; mechanical-precise vector lines and per-character feathered detail both soften badly there. Silhouettes identify a character before the line does, so two characters who could be confused at small size carry distinct shapes.

The bible's calibration paragraph is the answer in one line: characters as simple as Ranking of Kings, painterly atmosphere across the backgrounds, the painterly feel sustained through layered depth and shared light rather than per-character full-render. Per-character Cuphead-level rendering is out of reach at this scale. The rendering load goes into the venue; the simple-shape discipline holds the characters.

---

## Reality is a different rig

Reality, the second style, is a different game with different tooling. It is not pong. It is interaction-driven scenes in the protagonist's hometown: walking into a room, doing small attentive things, leaving. The interaction surfaces, scene state, and dialogue layering are downstream design (`SH-279`); none of the Construction rig described above carries over directly. The artist work for Reality lands once that tooling exists.

---

The asset-delivery side of the same conversation, with file formats, import settings, folder structure, animation rigging, and performance budgets, lives in `designs/art/tech-pipeline.md`.
