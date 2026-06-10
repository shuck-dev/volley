# Paddle sprite sizing is decoupled from gameplay sizing

Decision note. Continues `2026-06-06-paddle-animation-collision-spike.md` (the scaffold) and feeds the `PlayerSprite` dev panel.

## Problem

`paddle.gd::_apply_size()` read `paddle_size` and drove two concerns from one number: the collider height (gameplay) and the sprite scale (visual, via `_scale_sprite`). Tuning the look fought the hitbox; the sprite could not size independently because sizing was gameplay-owned shared state. Items modified `paddle_size` as a stat (`grip_tape` grew it, `wrist_brace` shrank it), so the coupling reached into item balance too.

## Decision

Two independent systems. The sprite never reads `paddle_size`; gameplay never reads sprite dimensions.

| Concern | Owner | Driven by | Persisted |
|---|---|---|---|
| Collider height | `paddle_size` on `PaddleConfig` | fixed config value | yes (config) |
| Sprite width + height | the paddle's sprite | the `PlayerSprite` dev panel | no (live tuning) |

## What changes

- **Retire the size effect.** `paddle_size` stops being a resolved stat. `grip_tape` (size-only effect) is deleted. `wrist_brace` keeps its ball-speed buff, loses its `paddle_size` penalty. `paddle_size_min` and the `_resolve` path for size are removed; the collider reads `paddle_size` directly as a fixed dimension.
- **Cut the seam.** Remove `_scale_sprite(new_size)` from `_apply_size()`. The collider path and the sprite path no longer call each other.
- **Sprite owns its size.** The sprite gets independent width and height inputs, panel-driven, indexed on its own dimensions, never on `paddle_size`.

## Alignment is by eye, not by code

The collider and the sprite are not kept in sync automatically. Art is drawn to read correctly around the hitbox; the panel's collider-visibility toggle exists to check they line up. Full independence, no default-derive leash.

## Two collision objects: ball bounce and wall contact are split

The paddle currently has one `CollisionShape2D` on the `CharacterBody2D`, doing both jobs at one size: the ball physically bounces off it (the ball's `physics_material` has `bounce = 1.0`, so the return is engine restitution, not code; `_on_body_entered` → `on_ball_hit` only registers the hit) and `move_and_slide` uses it against walls. One shape, so the whole footprint returns the ball.

The ball bounce and the wall contact need DIFFERENT SIZES (racket-zone vs character footprint) and the ball must bounce off ONLY the racket. A body's `collision_layer` is per-object, not per-shape, so two shapes on one body cannot sit on different layers. Therefore two collision OBJECTS:

- **Wall body.** The existing `CharacterBody2D`, footprint-sized, on its own layer that the ball does NOT mask. `move_and_slide` against walls via its mask; the ball passes through it.
- **Racket bounce body.** A child `AnimatableBody2D` (NOT an `Area2D`: restitution needs a solid body to reflect off, and `AnimatableBody2D` both bounces the ball and follows its parent). Racket-sized, mid-body, on the ball's layer so the ball physically bounces off it. Position and size are PANEL-TUNABLE.

Because the ball bounces off the racket body, the ball's `body_entered` reports that body, not the paddle. The racket body routes `on_ball_hit` up to the `Paddle` (script or signal) so hit registration still fires.

The two objects have independent layer/mask wiring: the ball bounces off the racket body only; walls stop the wall body only.

## Collider visibility draws at runtime

The panel's show-collider toggle must DRAW the shapes in the running game. `CollisionShape2D.visible` does not draw at runtime (it is an editor property); use `get_tree().debug_collisions_hint` or a custom `_draw`. The toggle exists so both new colliders can be seen and aligned during tuning.

## Temporary: the panel sizes the placeholder via Node2D scale

The `PlayerSprite` panel drives the placeholder sprite's size with `sprite.scale.x/y`. This violates [[feedback_no_node2d_scale]] (scale compounds coordinate-space, hit-rect, and physics math) and is **deliberate temporary scaffolding**, accepted only because the panel is a throwaway tuning instrument whose job is to find a target dimension by eye, then be discarded. The product is the dimension number, not the scaled placeholder.

Before the real paddle art lands, this must change to bounds-based sizing: the sprite is shown at its true size via SpriteFrames authored at the tuned dimensions, not by scaling the Node2D. Tracked as debt; do not let the scale path survive into shipped art.

## Out of scope

Redesigning `grip_tape` (deleted, not replaced). Rebalancing `wrist_brace` beyond removing the size penalty. The SpriteFrames-swap pipeline that lands real art at the chosen dimensions.
