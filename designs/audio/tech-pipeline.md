# Audio tech pipeline

How the bible's sound lives inside Godot. The seam between composition and engine, at high level. The specifics will be argued through with the engineer who wires it; this doc holds the position, not the spec.

## The seam

The score is composed, not procedurally generated. The composer hands deliveries to the engine team; the engine plays them. The piano reduction is the canonical track until the full instrumentation lands (see the [bible's](bible.md) Form section), and the engine team holds the swap when it does.

Stems by family, when the full version arrives, so the mix can branch by venue or by half without re-rendering. The exact stem layout, the bus graph, the import format, the file conventions: all of these get settled when the engineer picks them up.

## What we are not building

No middleware (Wwise, FMOD). Godot's native audio is enough for the surface area. No procedural generation. No adaptive layering driven by gameplay state. The score is composed; the engine plays it.

## Owners

The composer owns the deliverables and the mix targets. The engine team owns the engine seam. The bible holds the why; this doc holds the position the engineering pass starts from.
