# Audio tech pipeline

How the bible's sound lives inside Godot. The seam between composition and engine.

## Hand-off

The composer delivers two layers per piece.

1. The piano reduction. A single stem, exported lossless, that the engine can play as the fall-back if the full mix is not yet built. The reduction is the version that has to hold up alone.
2. The full instrumentation. Stems by family (piano, percussion, the unusual instrument, the room), so the mix can branch by venue or by half without re-rendering.

Each delivery sits under `assets/audio/<half>/<venue-or-scene>/`. The half is `construction` or `reality`. The venue or scene names match the [art bible's](../art/bible.md) venue list.

## Format

Lossless source stems in WAV. Engine ingest is Ogg Vorbis at the import step (Godot's default for streaming). The lossless stems stay in the repo's audio asset folder so re-mixing does not need to find the originals elsewhere.

## Buses

Three top-level buses.

- **Score.** The composer's work. Carries the leitmotifs. Volume is the player's main music slider.
- **Sound design.** Diegetic and UI sound: the rally, the counter, the stall, the shop. Volume is the player's effects slider. ([Sound Design](sound-design.md) holds the canon.)
- **Voice.** Reserved. Volley does not currently have voice acting; the bus exists so it can be added without a rewire.

## The half-shift

The transition from Construction to Reality is a hard cut, not a crossfade. The break is silent, the room is the first thing the player hears, and the Reality theme arrives only when a person is in the frame. The engine handles this by stopping the Construction bus at the break event and not starting the Reality bus until the room scene is loaded.

## What we are not building

No middleware (Wwise, FMOD). Godot's native AudioStream is enough for the surface area. No procedural generation. No adaptive layering driven by gameplay state. The score is composed; the engine plays it.

## Owners

The composer owns the deliverables and the mix targets. The engine team owns the import settings, the bus graph, and the half-shift wiring. The bible holds the why; this doc holds the how.
