# Paddle Animation and Collision Spike

Resolves the two paddle spikes [#587](https://github.com/shuck-dev/volley/issues/587)
(animation states) and [#865](https://github.com/shuck-dev/volley/issues/865)
(sprite collisions) as one decision, because both rework the same Sprite/collider
seam on `paddle.gd` and the collider question only has an answer once the animation
states exist.

## Decision

Paddles render through an `AnimatedSprite2D` whose `SpriteFrames` resource holds
named placeholder animations (idle, ready, swing, walk). A movement state machine
owns the paddle's gameplay state and drives the animation downstream; the
animation layer never holds gameplay state. Swing is a transient overlay action
composed in code on top of the current movement state, not a movement state of its
own. Collision uses a small set of per-state primitive shapes (a `CollisionShape2D`
sized for idle/walk, a wider/taller one for swing), toggled in code on state
change, never keyed off an `AnimationPlayer` track. No `AnimationTree`.

Real character art lands later as a `SpriteFrames` swap with matching animation
names; no GDScript changes. This satisfies [#587](https://github.com/shuck-dev/volley/issues/587)'s
acceptance criterion.

## Why AnimatedSprite2D, not AnimationPlayer or AnimationTree

The three Godot 4 ways to drive sprite animation, and why this picks the first:

| Approach | Fit | Verdict |
|---|---|---|
| AnimatedSprite2D + code state map | Self-contained; all frames in one `SpriteFrames`; swap art by swapping the resource | Chosen |
| AnimationPlayer owns sprite + tracks | One lockstep timeline (sprite, collider, audio) | Rejected: tracks live in the node, so new art means re-keying per sheet, breaking the swap-with-no-code-change goal |
| AnimationTree (state-machine mode) | Blended, composed locomotion | Rejected: no blending wanted; cannot natively drive AnimatedSprite2D ([proposal #567](https://github.com/godotengine/godot-proposals/issues/567)), so adopting it forces giving up the swap-friendly node for a feature we do not use |

AnimatedSprite2D is the only option where dropping in real art is a resource swap.
The official Godot tutorial introduces it as the primary tool for frame-based
sprite animation; it carries less per-instance overhead than AnimationPlayer
([2D sprite animation](https://docs.godotengine.org/en/stable/tutorials/2d/2d_sprite_animation.html)).

## Why the movement FSM is the source of truth

Gameplay state (idle / ready / walk, and the transient swing action) lives in a
movement state machine on the paddle. The animation layer is a downstream consumer:
the FSM decides the state, then tells the sprite which animation to play and which
collider to activate. State must never live in the animation, or the ball physics
(is the swing hitbox active) would depend on which sprite frame is showing, coupling
collision to art.

The paddle has no movement FSM today. State is implicit: `velocity.y != 0` reads as
moving, `== 0` as idle, and the only explicit machine is `TimeoutController`'s
walk-off/equip/walk-on enum, which sits outside the paddle and sets `drive_blocked`
(`timeout_controller.gd:14`). Wiring named animation states is the occasion to make
movement state explicit, with the FSM as the single owner the animation reads from.

### Finding: TimeoutController is the wrong shape and should decompose

`TimeoutController` (`scripts/core/timeout_controller.gd`) is a manager that reaches
into the paddle and performs world interaction directly: every physics frame it drives
`main_character.velocity` and calls `move_and_slide()` (`_step_descent`, `_step_ascent`,
`_step_horizontal_walk`) to walk the paddle around the venue. Moving a body through the
world is not a manager's place. A controller coordinates, it decides what should happen;
the world interaction itself belongs on the thing that lives in the world.

The decomposition follows from that rule, owner by where the behaviour happens:

1. **Movement is the paddle's.** Walking to a target, descending to the floor, ascending
   to the lane: this is the paddle (a `CharacterBody2D`, the world body) moving itself.
   It owns "move me to this venue target." This is also exactly what player movement
   around the venue needs, the paddle can move itself regardless of why, so the
   capability is reused, not duplicated.
2. **Control mode is the paddle's.** Whether the paddle is player-driven or following a
   scripted target (`drive_blocked`, `set_physics_process`, the collision-mask swap) is
   the paddle managing its own control modes, not a flag imposed from outside.
3. **The equip sequence is the coordinator's.** Go to the equip pose, be equipped,
   return, plus the lifecycle signals. This is the genuinely errand-specific part and the
   good first extraction: an `EquipController` that holds no `move_and_slide`, asks the
   paddle to move to the equip pose, and reacts when it arrives.

So a first cut is an `EquipController` (pure coordinator: equip sequence, signals,
policy) sitting on a paddle that owns its own venue movement. Timeout becomes the broader
mode under which equip is one errand; player venue-movement is another, both asking the
same paddle to move. The manager never touches `move_and_slide`.

### The FSM reads the paddle's own movement, not a controller

Given that the paddle owns its movement, the animation FSM's relationship is simple: it
reads the paddle's own movement state, the same single source whether the paddle is moving
under player input, AI, or an equip errand. No special-casing a controller's phase enum,
no FSM hard-wired to `TimeoutController.get_state()`. The equip coordinator and the FSM
are both downstream of the paddle's movement; neither owns the other, and neither owns the
movement.

The decomposition is build-and-refactor work the spike does not execute; it is a
sequenced refactor (plan via `impact_check` / `dependency_graph`) that lands before or
alongside the animation rig. The constraint the build inherits: do not couple the FSM
to the current `TimeoutController` class shape, because that class is splitting.

## Why swing is an overlay, not a state, and why no tree

Swing is a transient action that can fire while the paddle is idle or walking, not a
mode the paddle is wholly in. The hit is currently an instantaneous `paddle_hit`
signal with no held pose (`paddle.gd:53`), which is the overlay shape: a brief action
on top of a persistent movement state.

Overlay composition does not require an `AnimationTree`. A tree earns its cost when
the composition is blended and continuous (speed-graded locomotion, per-bone upper
body over lower body). Ours is discrete and orthogonal: one channel picks the body
animation, another toggles the swing collider and pose. Sprite frames cannot
meaningfully blend (a frame is a discrete picture), so a tree here would be a state
selector with extra ceremony, while also forcing the loss of AnimatedSprite2D.
Discrete orthogonal composition is a few lines in the FSM. Revisit a tree only if
blended locomotion or live multi-layer sprite compositing is ever wanted; both are
additive over this.

## Why per-state colliders, toggled in code

A ball must not pass through the character as the silhouette changes across states.
The options, with the shipped-game precedent that settles them:

| Option | Cost | Verdict |
|---|---|---|
| Per-frame `CollisionPolygon2D` from sprite alpha | 16-32 unique shapes to validate; every write invalidates the physics-server shape; concave is the slowest shape type | Rejected: impractical outside fighting games; no engine support ([proposal #829](https://github.com/shuck-dev/volley/issues/829) open, unmilestoned) |
| Per-state primitive shapes, toggled on state change | One shape per state, swap on transition | Chosen |
| Single static capsule | Cheapest, least accurate | Rejected: a capsule covering the swing extent feels too large at idle |

Shipped 2D action games near-universally avoid silhouette-tracking colliders.
Celeste and TowerFall use integer axis-aligned bounding boxes for every actor and
projectile ([Thorson](https://maddythorson.medium.com/celeste-and-towerfall-physics-d24bd2ae0fc5));
even Smash, the one genre with per-frame hitboxes, uses authored capsules on bone
positions, not pixel polygons ([Smash Wiki](https://www.ssbwiki.com/Hitbox)).
Player hitboxes are intentionally sized for feel, not pixel accuracy. For a fast
ball, tunnelling is solved by continuous collision detection, not polygon detail, so
a complex collider buys nothing the ball can use.

### The collider is authored independently of the sprite, not derived from it

Today the sprite and collider are coupled by derivation: `_apply_size()`
(`paddle.gd:127`) scales `sprite.scale.y` to match the collider. That coupling is
exactly what breaks once the sprite animates, the visual silhouette changes frame to
frame, and anything derived from it drifts with it. The paddle collider is also a
gameplay input, not only a presence test: `Paddle.get_half_height()`
(`paddle.gd:82-83`) feeds the ball's return-angle contact-offset denominator, so a
collider that tracked the sprite would make the bounce angle wobble with the art.

Decision: decouple the collider from the sprite. The collider is its own authored
shape, sized for gameplay feel, and the sprite is its own thing, sized for the art;
neither is calculated from the other, and the `_apply_size` sprite-from-collider
derivation retires. The sprite then varies freely across animation states and frames
without ever touching collision or the return angle, because the collision shape was
never derived from it. The contact reference for the bounce reads from the authored
collider, which is stable. A per-state collider that differs (a wider swing shape) is
then a deliberate authored choice, not a side effect of the sprite, and its effect on
the return angle, if any, is intended rather than incidental.

### Toggle the collider in `_physics_process`, not on an animation callback

The FSM drives the collider toggle in code (the AnimationPlayer caveat below). One
timing trap to honour: AnimatedSprite2D advances in `_process`, physics reads collider
shape in `_physics_process`, different loops. If the FSM flips the active collider from
a `_process`-side animation callback, a physics step can run before the next `_process`
and read the stale collider, so a ball hit in that one-frame window gets the wrong shape
and angle. Pin the toggle to `_physics_process` (drive the FSM there, or set the
collider state on the same physics tick the state changes), so the shape the ball reads
is never a frame behind the state.

### Caveat: do not key the collider toggle from an AnimationPlayer

The tempting pattern (an AnimationPlayer track keying `CollisionShape2D.disabled` per
frame) has a cluster of known Godot bugs: a call-function track cannot reliably
enable a CollisionShape2D ([#18824](https://github.com/godotengine/godot/issues/18824)),
and the `disabled` property toggled via animation has reported inverted-state and
re-enable-on-unpause behaviour ([#30383](https://github.com/godotengine/godot/issues/30383),
[forum](https://forum.godotengine.org/t/unpause-animationplayer-re-enables-disabled-collisionshape2d/38723)).
Drive the toggle from the FSM in code instead. The FSM already makes the state
decision; it flips the active collider in the same transition, so sprite and collider
cannot disagree.

## Frame delivery: individual images

Character art is authored as individual PNGs per frame, dropped into a `SpriteFrames`
resource. The project has no sprite art convention to inherit (nine PNGs today, all
single images, no spritesheets, no `SpriteFrames`), so this spike sets the
convention. Individual images are the most swap-friendly and artist-friendly path for
AnimatedSprite2D; a spritesheet would suit AnimationPlayer's region keying, which is
not the chosen node.

## The seam, today

Three paddle scenes, all 2D `CharacterBody2D`, share `paddle.gd`:

| Scene | Root | Visual node today |
|---|---|---|
| `scenes/player_paddle.tscn` | CharacterBody2D | child `Sprite2D` "Sprite", `PlaceholderTexture2D` |
| `scenes/partner_paddle.tscn` | CharacterBody2D | child `Sprite2D` "Sprite", `PlaceholderTexture2D` |
| `scenes/partners/martha_paddle.tscn` | CharacterBody2D | child `Sprite2D` "Sprite" + cosmetic "Bow" overlay |

`sprite` is already `@export` (`paddle.gd:13`); today its only logic is `_apply_size()`
scaling `sprite.scale.y` to the collider (`paddle.gd:127`). The build swaps the
`Sprite2D` export to `AnimatedSprite2D` across `paddle.gd` and the three scenes, retires
the `_apply_size` sprite-from-collider derivation (the sprite and collider are authored
independently, per the decouple decision above), adds the per-state colliders, and wires
the movement FSM to drive both. Note `TimeoutController` also reads the collider via
`_half_height()` to anchor the paddle's foot during in-pose resizes, and comments there
reference `_apply_size`'s foot-anchoring; retiring `_apply_size` is a cross-effect the
build must reconcile with that controller (another reason the decomposition above is
entangled with this rig). Whether to wrap the AnimatedSprite2D and colliders in a small
reusable child node (instanced across the three scenes) or keep them as direct children
driven by `paddle.gd` is a build-time structural taste call, not load-bearing here.

## Out of scope

- Real character art. Placeholder frames only; art swaps in later.
- New gameplay states. `ready` and `swing` are defined animation hooks the FSM can
  enter; the gameplay that triggers a held `ready` or a swing windup is separate work.
- The movement FSM's full design beyond what animation needs to read.
- Executing the `TimeoutController` decomposition. The spike surfaces it (world
  interaction is not a manager's place: movement and control-mode belong on the paddle,
  with an `EquipController` as a pure coordinator on top, and the FSM reads the paddle's
  own movement) and names it as a dependency the rig is entangled with. The sequenced
  refactor itself, planned via `impact_check` / `dependency_graph`, is its own work that
  lands before or alongside the build.
- Any `AnimationPlayer` or `AnimationTree` adoption. Both are additive later if
  blended locomotion or frame-synced multi-track events are ever wanted.
