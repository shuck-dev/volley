# Volley! Artist Tech Context

A companion to `artist-brief.md` and `artist-world-bible.md`. The brief is the deal; the bible is the world; this is the engine the world is painted into.

This doc is the practical context the brief leaves out: how the scene is layered, what the engine does with what you draw, where the protagonist's body goes when he steps off the court, and what the format asks of the line. Read it once, keep it nearby. Fifteen minutes, end to end.

---

## The scene is a place, not a flat plane

The first thing worth knowing: a Volley! venue is built to read as somewhere a person could walk into, not as a backdrop with figures on top.

It works through layered painted backgrounds set at different distances from the camera. A deep background drifts almost imperceptibly. A near background sits behind the rally. The court itself, where the paddles meet the ball, is a mid-ground plane. Then the foreground sits forward of the rally: a rack leg, a corner of the friend's stall awning, a tabletop edge, a vine catching on the camera. As the player's eye crosses the frame, those layers slide past each other at slightly different rates, and the venue acquires depth without ever leaving 2D.

Godot calls this a `Parallax2D` rig: a stack of painted layers, each scrolling at its own rate. The court already runs a single-layer version of this in `scenes/court.tscn`, which is the seed the rest grows from.

What this means for the work: when you paint a background, you are not painting a frame; you are painting a slice of the world at a specific distance. A near layer needs the kind of detail the player's eye lands on when the rally pauses. A deep layer can carry atmosphere with almost nothing in it: a wall of warm afternoon, a wash of submerged green, the suggestion of a tree. The friend's stall sits forward; a row of distant rooftops sits back; the wonder past the locked gate sits further back still.

You decide what lives at which depth. The depth read is one of the strongest tools the venue has for feeling like a place rather than a plane.

The illusion holds on consistency. Light direction is locked per venue before any layer goes into production: a backlit afternoon in the garden, sunlight filtering through water in the underwater venue, nebula glow from above on the meteor. Every layer is painted to the same source, characters included. Painted shadow on the friend's awning matches painted shadow on the paddle matches painted shadow on the back wall. Nothing in this rig depends on shaders or runtime lighting; the painting carries it.

---

## Canvas layers, in plain language

Three layers in the engine are worth knowing about by name, because they shape what kind of thing you are drawing.

**The world layer.** Almost everything sits here: the painted backgrounds, the court, the paddles, the ball, the friend's stall, the racks, the workshop, characters. This is where the rally lives. When the camera moves or zooms, everything in the world layer moves with it. Anything diegetic, anything inside the fiction, lives here.

**The background layer (or layers).** Inside the world, the painted backgrounds are themselves a stack. Parallax2D is the engine name; the substance is what we covered above. Their distinguishing trait is that they scroll at slow rates relative to the camera, so they sell distance.

**The screen-space dev overlay.** A separate layer, technically a `CanvasLayer`, that sits glued to the screen and ignores the camera. The only thing that lives here is a developer-only HUD: framerate, debug toggles, state inspection text. Player-facing game state never lives here. The volley counter is a wooden plaque on the court. The personal best is a sign on the wall. The friendship-point balance is a counter the friend keeps. The shipment landing is a thump and a small pulse on the mat. Banners, popups, and floating numbers across the player's field of view are not how Volley! talks to its player. The world tells the player what is happening, in objects the player can point at.

The shorthand: *system chrome on the screen-space layer, fiction chrome inside the world.*

---

## The protagonist on and off the court

The protagonist holds a paddle. That paddle is the constant. Items attach at named anchor points on it: a grip on the handle, a piece of equipment on the head, a tape across one side. The paddle stays the same shape across every venue.

What is worth understanding for character work: the paddle is not always at its lane. There are moments when the protagonist needs to step off court, equip an item or unequip one, and step back on. The mechanic is called a timeout, and it has a specific choreography:

1. **Descend.** The paddle is at its rally height somewhere up the lane. When a timeout begins, it lowers smoothly to the venue floor.
2. **Walk off.** Once grounded, it walks sideways out of the court, off into the venue, to a resting equip pose. The protagonist's hand is on it the whole time; we are watching a person walk to a workbench, not a sprite slide on a rail.
3. **Equip or unequip.** At the resting pose, the item is fitted to the paddle or removed from it. This is a held beat: the work of attaching the thing.
4. **Walk on.** The paddle walks back across the venue floor and rises into the lane.
5. **Rejoin.** Rally resumes with the paddle defending again.

While this happens the rally continues without the paddle on that side. Balls cross the miss line until the protagonist is back; the player called the timeout knowing that.

What the artist can hold in mind: the protagonist (and the paddle) lives in two states the player will see often. **In-rally:** floating somewhere up the lane, alert, defending. **On-the-walk:** on the venue floor, walking a short distance, paddle held more like a tool than a weapon. Plus a brief **at-the-equip-pose** moment off court where the item joins or leaves the paddle. The transitions between those states are where the protagonist's body language gets to come through: how he carries the paddle when he is not playing, how he stops, how the paddle settles when an item is being fitted.

The script that drives this lives at `scripts/core/timeout_controller.gd`; you do not need to read it. The shape above is what it does.

---

## Pong-shape, three-sided, open at the sides

The court is three-sided, not a closed box. Worth keeping in mind because it changes what the venue holds at any given moment.

- **Top edge.** The screen edge. A hard ceiling: the ball bounces off it.
- **Bottom edge.** The ground inside the court. A pong-style floor: the ball bounces off it. Hitting the ground does not end the rally.
- **Back wall.** Behind the protagonist's paddle. The miss line. A ball that crosses this line is a miss.
- **Sides.** Open. No side walls. The court visibly opens onto the rest of the venue.

A ball that leaves sideways without being returned is also a miss. The miss does not despawn the ball. The ball keeps its velocity, rolls out of the court, decelerates on the venue floor, and comes to rest wherever it stops. It stays there until the player picks it up and drags it back to the ball rack.

Resting balls render in the mid or foreground, over the shop and workshop areas. They stay visible. So at any given moment the venue might hold a couple of balls scattered at rest on the floor, the rally happening on the court, the friend at her stall, the tinkerer at the workshop, and racks holding inactive balls and equipment. The artist's read on the venue needs to leave room for that population.

The ball rack and the gear rack are the exception: a ball that rolls into a rack's footprint snaps into a slot rather than stopping on the floor. The racks are drop targets, with weight and presence.

---

## Format limitations the work has to survive

Volley! defaults to a small borderless desktop window. Web export is the primary distribution channel today. The work needs to read at sizes well below a feature-film frame.

The bible's calibration paragraph is the answer in one line: characters as simple as Ranking of Kings, painterly atmosphere across the backgrounds, the painterly feel sustained through layered depth and shared light rather than per-character full-render. Per-character Cuphead-level rendering is out of reach at this scale; the rendering load goes into the venue; the simple-shape discipline holds the characters.

This shapes a few practical asks:

- **Bold silhouettes.** A character's silhouette identifies them before the line does. If two characters could be confused at small size, one of their silhouettes changes.
- **Line that survives downscale.** The line has weight that holds when the asset is rendered into a small window. Mechanical-precise vector lines and per-character feathered detail both tend to soften badly at small scale.
- **Painterly backgrounds carry the world.** Atmosphere, depth, light belong to the painted layers. Characters belong against them, simply drawn, animated through body language.
- **Diegetic state.** Information lives on objects the player can point at. The volley counter is a thing in the world. The friendship-point balance is a thing in the world. The shipment beat is a thump and a pulse, not a banner.

The format is the bet, not a constraint sitting outside the work. The painterly atmosphere and the simple-shape discipline are what the format affords if we commit to them together.

---

## Engine-side DOs and DON'Ts

The bible covers the visual register. These are the engine-layer asks the bible cannot speak to.

**DO:**

- **Paint to a single locked light direction per venue.** Foreground props, characters, and backgrounds share one source so the layered illusion holds.
- **Keep the line heavy enough to survive downscale.** Web export and a small borderless window are the default sizes; per-character feathered detail and mechanical-precise vector lines both soften badly there.
- **Put player-facing state in the world.** A plaque on the court, a sign on the wall, a counter at the friend's stall, a thump on the mat. The world layer carries fiction; the screen-space overlay is dev-only.
- **Plan rendering load for the venue, not the character.** Painted backgrounds carry atmosphere and depth; characters stay in the simple-shape register so animation does the acting work.

**DON'T:**

- **Mismatch light direction across layers.** A foreground catching sun from one side while a background catches it from another flattens the illusion immediately.
- **Use screen-space banners, popups, or floating numbers** for anything the player needs to read about the rally, the economy, or progression. That layer is for framerate and debug toggles.
- **Reach for shaders or runtime lighting tricks** to fake depth. The painting carries it; the rig is layers, parallax, and shared light.

---

## A pointer to the other tech-art doc

The companion engineering-side doc is `designs/art/tech-pipeline.md`. It covers the asset-delivery side of the same conversation: file formats, import settings, folder structure, animation rigging, performance budgets, the integration-PR contract. If the present doc is *what the artist sees and how the engine paints it*, the pipeline doc is *how a finished asset travels from the artist's machine into the running game*.

You do not need to read the pipeline doc on day one. The integrator handles the import side, and per-asset briefs link back to the relevant pipeline sections. The two docs and the engine are one bet, made together. If something here pushes against your instincts on the work, push back.
