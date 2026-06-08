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
animation layer never holds gameplay state. Swing is reactive animation (the paddle
plays it because a hit happened, it is not a player input), so collision does not
change with it: the paddle has one fixed authored collider and the sprite animates
over it. No `AnimationTree`.

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
the FSM decides the state, then tells the sprite which animation to play. State must
never live in the animation, or the ball physics would depend on which sprite frame is
showing, coupling collision to art.

The paddle has no movement FSM today. State is implicit: `velocity.y != 0` reads as
moving, `== 0` as idle, and the only explicit machine is `TimeoutController`'s
walk-off/equip/walk-on enum, which sits outside the paddle and sets the paddle's
`drive_blocked` flag (declared on `paddle.gd`). Wiring named animation states is the occasion to make
movement state explicit, with the FSM as the single owner the animation reads from.

### The FSM reads paddle movement state, not a controller phase

The animation FSM consumes the paddle's movement state directly (velocity-driven idle vs
moving), not any controller's internal phase enum. During a timeout the paddle is still
moving, so the FSM animates that movement the same way; it does not need to be hard-wired
to `TimeoutController.get_state()`. The constraint the build inherits: do not couple the
FSM to `TimeoutController`'s current class shape, because that shape is under separate
review (the timeout/equip responsibilities are being re-homed by ownership in their own
refactor). Keying the FSM to paddle movement keeps it independent of how any errand is
orchestrated.

## Why swing is an overlay, not a state, and why no tree

Swing is a transient action that can fire while the paddle is idle or walking, not a
mode the paddle is wholly in. The hit is currently an instantaneous `paddle_hit`
signal with no held pose (`paddle.gd:53`), which is the overlay shape: a brief action
on top of a persistent movement state.

Overlay composition does not require an `AnimationTree`. A tree earns its cost when
the composition is blended and continuous (speed-graded locomotion, per-bone upper
body over lower body). Ours is discrete: the movement state picks the body animation,
and a swing plays its animation on top when a hit fires. Sprite frames cannot
meaningfully blend (a frame is a discrete picture), so a tree here would be a state
selector with extra ceremony, while also forcing the loss of AnimatedSprite2D.
Discrete composition is a few lines in the FSM. Revisit a tree only if blended
locomotion or live multi-layer sprite compositing is ever wanted; both are additive
over this.

## One fixed collider, the sprite animates over it

The collider does not change across animation states. Swing is not a player input;
it is reactive animation, the paddle plays a swing because a hit happened, not a
timed action that extends reach or alters the hitbox. The ball always strikes the
same body. So there is no per-state silhouette to track, no per-frame collision
shape, and nothing to toggle: the paddle has one authored collider, and the sprite
animates freely over it. (This argues `swing` specifically; if a future `ready` pose
ever extends the paddle's reach, the collider question reopens for that state alone.)

This also keeps the bounce stable. `Paddle.get_half_height()` (`paddle.gd`) feeds the
ball's return-angle contact-offset denominator; because the collider is one fixed
shape, that reference never moves with the animation. The sprite varies; the angle
does not.

The collider's only legitimate size change is the stat-driven loadout resize in
`_apply_size()` (item effects growing/shrinking the paddle), which is per-loadout, not
per-frame, and is the existing foot-anchor path, untouched by this work.

### Decouple the collider from the sprite

Today `_apply_size()` ends by scaling `sprite.scale.y` to match the collider, the one
line that couples the visual to the physics shape. Once the sprite animates, that
derivation drifts. The build removes that final sprite-scale line; the collider-resize
and the `position.y` foot-anchor in `_apply_size` stay untouched, so
`TimeoutController._half_height()` (which reads the collider, not the sprite) is
unaffected. After that, the collider is authored on its own and the sprite is authored
on its own; neither derives from the other.

## Frame delivery: individual images

Character art is authored as individual PNGs per frame, dropped into a `SpriteFrames`
resource. The project has no sprite art convention to inherit (nine PNGs today, all
single images, no spritesheets, no `SpriteFrames`), so this spike sets the
convention. Individual images are the most swap-friendly and artist-friendly path for
AnimatedSprite2D; a spritesheet would suit AnimationPlayer's region keying, which is
not the chosen node.

## Target resolution: two source tiers, downscale only

The game targets 1080p and 4K, so art is authored at both: a 1080p source set and a 4K
source set. Upscaling hand-drawn art reads blocky, so the rule is that a source is never
enlarged past its authored size. Every other resolution downscales from the nearest
higher tier: a 1440p or 1080p display takes the 4K source down, a sub-1080p window takes
the 1080p source down. Downscaling holds detail; only upscaling invents it and degrades.
Two authored tiers therefore cover the whole range by downscale, with 4K as the ceiling
nothing climbs above.

The stretch config (`canvas_items` at a 1920x1080 base, already set) renders the scene
at the physical window resolution, so the source that matches or exceeds the display
draws at or above 1:1 and the engine downscales the rest. The texture filter is
`linear_mipmap`, and the import pipeline enables mipmaps on every sprite (sources today
import with `mipmaps/generate=false`): the mipmap chain is what keeps a fractional
downscale, like 4K to 1440p, clean rather than aliased, so it is a precondition for any
real art tier, not an afterthought. The `window/stretch/aspect` setting is `expand` so
non-16:9 displays extend the canvas rather than distort; it is unset today and this
establishes it.
([Godot multiple-resolutions docs](https://docs.godotengine.org/en/stable/tutorials/rendering/multiple_resolutions.html).)

This is the art-and-import shape, not a scaffold concern: the scaffold stays
size-agnostic (a swappable `SpriteFrames`, no hardcoded frame dimensions), so a source
tier drops in as a resource. Loading the right tier for the current display is real work
the scaffold does not do, so a real build needs that selection wired before it ships, or
it loads one tier for every display and the foundation goes unused. That selection is its
own follow-up, tied to the resolution-settings spike and the level-of-detail decision. The font-text blur under `canvas_items` on resize (Godot #86563) is a
separate UI concern for whenever 4K text crispness is required.

## The seam, today

Three paddle scenes, all 2D `CharacterBody2D`, share `paddle.gd`:

| Scene | Root | Visual node today |
|---|---|---|
| `scenes/player_paddle.tscn` | CharacterBody2D | child `Sprite2D` "Sprite", `PlaceholderTexture2D` |
| `scenes/partner_paddle.tscn` | CharacterBody2D | child `Sprite2D` "Sprite", `PlaceholderTexture2D` |
| `scenes/partners/martha_paddle.tscn` | CharacterBody2D | child `Sprite2D` "Sprite" + cosmetic "Bow" overlay |

`sprite` is already `@export` (`paddle.gd`); today its only animation-relevant logic is
`_apply_size()` ending by scaling `sprite.scale.y` to the collider. The build swaps the
`Sprite2D` export to `AnimatedSprite2D` across `paddle.gd` and the three scenes, removes
that final sprite-scale line from `_apply_size` (the collider-resize and `position.y`
foot-anchor in `_apply_size` stay, so `TimeoutController._half_height()` is unaffected),
and wires the movement FSM to drive the animation. The single collider is untouched.
Whether to wrap the AnimatedSprite2D in a small reusable child node (instanced across the
three scenes) or keep it a direct child driven by `paddle.gd` is a build-time structural
taste call, not load-bearing here.

## Out of scope

- Real character art. Placeholder frames only; art swaps in later.
- New gameplay states. `ready` and `swing` are defined animation hooks the FSM can
  enter; the gameplay that triggers a held `ready` or a swing windup is separate work.
- The movement FSM's full design beyond what animation needs to read.
- The `TimeoutController` reshape. Its timeout/equip responsibilities are being re-homed
  by ownership under a separate refactor; the spike only constrains the FSM not to couple
  to that controller's current shape, and does not decide or execute the reshape.
- Any `AnimationPlayer` or `AnimationTree` adoption. Both are additive later if
  blended locomotion or frame-synced multi-track events are ever wanted.
