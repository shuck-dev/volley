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

## Racket is an Area2D; the return is code-applied, not restitution

The ball must interact with ONLY a small racket zone, not the whole character body. The standard 2D idiom (fighting-game hitbox/hurtbox, bullet-hell) is: the `CharacterBody2D` handles terrain, and separate child `Area2D` nodes on their own layers handle hit-detection. A child `Area2D` carries independent `collision_layer`/`collision_mask` (per-CollisionObject), which is the normal, supported pattern. (A child physics BODY shares the parent's layer; an Area2D does not. That is why the racket is an Area2D, not a body.)

Today the ball returns by pure physics restitution (`bounce = 1.0`) off the paddle body, and the existing `paddle_return_angle_max_degrees` / `paddle_english_coefficient` / bounce min-max stats shape that engine reflection. Arcade ball games (Breakout, Pong, Arkanoid) conventionally CODE-APPLY the paddle return instead, because the return angle should depend on the contact point and paddle motion, which is exactly what those stats encode. So:

- **Wall body.** The `CharacterBody2D`, on a layer the ball does NOT mask. The ball passes through the character body entirely. `move_and_slide` against walls only.
- **Racket hitbox.** A child `Area2D`, racket-sized, mid-body, on its own layer, masking the ball. Detects the ball entering. Position and size PANEL-TUNABLE.
- **Code-applied return.** On racket detection, the ball's velocity is reflected in code using the existing return-angle, english, and bounce-clamp stats. Physics restitution off the paddle is RETIRED. The ball no longer bounces off any paddle collider; the racket Area2D detects and the return is computed.

## Collider visibility draws at runtime

The panel's show-collider toggle must DRAW the shapes in the running game. `CollisionShape2D.visible` does not draw at runtime (it is an editor property); use `get_tree().debug_collisions_hint` or a custom `_draw`. The toggle exists so both new colliders can be seen and aligned during tuning.

## Temporary: the panel sizes the placeholder via Node2D scale

The `PlayerSprite` panel drives the placeholder sprite's size with `sprite.scale.x/y`. This violates [[feedback_no_node2d_scale]] (scale compounds coordinate-space, hit-rect, and physics math) and is **deliberate temporary scaffolding**, accepted only because the panel is a throwaway tuning instrument whose job is to find a target dimension by eye, then be discarded. The product is the dimension number, not the scaled placeholder.

Before the real paddle art lands, this must change to bounds-based sizing: the sprite is shown at its true size via SpriteFrames authored at the tuned dimensions, not by scaling the Node2D. Tracked as debt; do not let the scale path survive into shipped art.

## Out of scope

Redesigning `grip_tape` (deleted, not replaced). Rebalancing `wrist_brace` beyond removing the size penalty. The SpriteFrames-swap pipeline that lands real art at the chosen dimensions.
