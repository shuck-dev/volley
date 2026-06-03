# Surface Physics Ownership Spike

## Decision

Rest-roll damping is a property of the ball's rest state, not the court. It moves from `CourtConfig.rest_roll_damping` onto `BallStateConfig` (authored in `out_rest.tres`), and the imperative override in `Ball.enter_out_rest` retires. The surface bounce materials (`play.tres`, `rest.tres`) stay where they are: they are contact properties shared between the ball and the world body it strikes, not ball-only state. Collision-layer constants stay as they are; a named module is deferred. `CourtConfig.court_half_width` becomes `court_width`: width is width, stored full, with no derived role beyond the one consumer that reads it.

This finishes the cleanup #724 began. That fix pulled the apex bound out of `CourtConfig` (onto the `SoulBound` marker) while separating the court's collision floor from the apex wall. The remainder is the damping field and the question of who owns the surface materials.

## Why rest damping is ball state, not court

The current code asserts the opposite. `Ball.enter_out_rest` overrides the state config's damping from `court_config.rest_roll_damping`, with a comment calling damping "a court-tunable, not a ball-state-tunable." That assumption is wrong: the venue rolls and rests balls too, so resting is not exclusive to the court. A value scoped to the court leaves the venue case homeless.

Decide a ball-behaviour value's owner by where the behaviour happens. Resting happens in both court and venue, so damping belongs to the thing that travels with the ball across both: its rest state. `out_rest.tres` already drives the rest state's other physics flags (gravity, collision, material); damping joins them, and the `CourtConfig` field plus its override disappear.

## Why the surface material is not ball-only

A bounce is an interaction between two bodies. Godot 2D combines the materials of both contacts; with the engine defaults, an absent material on one side reads as bounce 0, and the combined restitution collapses toward zero. So `play.tres` (bounce 1) on the court walls is load-bearing: the ball's own material supplies one half of the bounce, the wall supplies the other. Removing the wall's material to make the ball "own" the surface would kill the bounce.

This combine reasoning follows Godot's documented material defaults and is not verified in a running scene here; confirming the exact restitution under combine is implementation-ride work, not part of this spike. The decision does not depend on the precise figure: removing a material can only reduce a bounce, never raise it, so the conclusion (keep the wall material) holds either way.

The kernel worth keeping from the original SurfaceConfig idea is real but lives on the world side, not the ball: a surface has a character (friction, bounce, and a roll damping the ball adopts while resting on it) that today has no single named source. That is a venue-surface concern, surfacing only once venues need to differ. It is out of scope here and files as its own work when a venue demands a distinct surface.

## Why width is stored full, not half

`CourtConfig` stores `court_half_width`, but its only consumer is `world_max_speed`, which immediately doubles it to recover the full crossing span. The docstring claims the half-value seeds spawns and miss zones, but nothing reads it for that: the spawns are literal positions in `court.tscn`, not derived from the field. So the half is a number nobody halves around, read once and doubled. The field becomes `court_width`, holding the full paddle-to-paddle span; `world_max_speed` reads it directly and the doubling drops. Width is width, with no derived role.

## Surfaces today

| Value | Lives in | Applied where |
|---|---|---|
| Bounce material (friction 0, bounce 1) | `resources/ball/play.tres` | `ball.tscn` default; ball `play_active` state; court walls and floor in `court.tscn` |
| Rest material (friction 1, bounce 0) | `resources/ball/rest.tres` | ball `out_rest` state (`out_rest.tres`) |
| Rest-roll damping | `CourtConfig.rest_roll_damping` | overridden onto the ball's `linear_damp` in `Ball.enter_out_rest` |
| Court geometry (`court_half_width`, crossing seconds, relock ramp) | `CourtConfig` | ball speed and relock logic |

After the change, `CourtConfig` holds only the geometry row (with `court_half_width` reshaped to a full `court_width`), and rest damping joins the rest material in `out_rest.tres`.

## Collision-layer constants: deferred

Two layers carry the game: world and items. The integer references spread across 14 sites in three artifact kinds (four imperative script callsites, three ball-state resources, seven baked scene nodes). A GDScript constants module can only reach the four script callsites; resources and scenes store raw integers and cannot reference a const. The hardest-to-audit sites, the scenes, stay raw either way. The layer names already live in `project.godot` (layer 1 world, layer 2 items), which is the engine's own legibility mechanism. A constants module is a partial win whose cost exceeds its benefit at two layers and stable semantics. Revisit if a third layer lands with real script consumers.

## Out of scope

- The single-source surface-character question (a venue's friction, bounce, and rest damping in one named resource). Files as its own work when venues need to differ.
- The collision-layer constants module. Deferred per above.
- Layer 4 on the venue side-bounds, used by no script. A venue-collision audit concern, not this.
