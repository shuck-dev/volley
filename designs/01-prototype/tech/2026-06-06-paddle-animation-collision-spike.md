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

### The FSM defers to TimeoutController, it does not replace it

`TimeoutController` (`timeout_controller.gd:14`) already runs a six-state machine
(IDLE, DESCENDING, WALKING_OFF, AT_EQUIP_POSE, WALKING_ON, ASCENDING) that drives the
paddle during a timeout and holds `drive_blocked` for the whole non-IDLE span. The two
most common non-idle paddle states (walk-off, walk-on) live there, so the new movement
FSM cannot ignore it. The relationship: the movement FSM reads `drive_blocked` (or
`TimeoutController.get_state()`) as its highest-priority input. While a timeout is
active, the FSM is in a `timeout` state that maps the controller's phase to an
animation (descending/ascending to a walk-cycle, at-equip to an idle-or-pose), and the
collider follows that. TimeoutController stays the locomotion authority during a
timeout; the FSM only translates its phase into animation-and-collider, the same
downstream-consumer role it has for the velocity-driven states. The full FSM transition
table is build-ticket work, but this priority (timeout phase outranks velocity) is the
constraint the build inherits, not a blank slate.

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

### The collider extent is a gameplay input, so the angle denominator stays fixed

The paddle collider is not only a presence test. `Paddle.get_half_height()`
(`paddle.gd:82-83`) returns the collider's half vertical extent, and the ball's return
angle uses it as the contact-offset denominator. So a per-state collider that is taller
during swing would silently change the return angle on swing hits, a feel bug with no
obvious cause ("edge hits feel off"). Decision: split the two concerns the single
`RectangleShape2D` currently collapses. The per-state shape that varies is the physics
extent (what the ball bounces off); the angle denominator stays a fixed reference
height, not whichever collider is active. `get_half_height()` returns that fixed
reference, not the live shape. A per-state swing collider may differ in physics extent
without touching the return-angle math.

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

`sprite` is already `@export` (`paddle.gd:13`); its only logic is `_apply_size()`
scaling `sprite.scale.y` to the collider (`paddle.gd:127`). The build swaps the
`Sprite2D` export to `AnimatedSprite2D` across `paddle.gd` and the three scenes, moves
the `_apply_size` scale to the new node, adds the per-state colliders, and wires the
movement FSM to drive both. Whether to wrap the AnimatedSprite2D and colliders in a
small reusable child node (instanced across the three scenes) or keep them as direct
children driven by `paddle.gd` is a build-time structural taste call, not load-bearing
here.

## Out of scope

- Real character art. Placeholder frames only; art swaps in later.
- New gameplay states. `ready` and `swing` are defined animation hooks the FSM can
  enter; the gameplay that triggers a held `ready` or a swing windup is separate work.
- The movement FSM's full design beyond what animation needs to read.
- Any `AnimationPlayer` or `AnimationTree` adoption. Both are additive later if
  blended locomotion or frame-synced multi-track events are ever wanted.
