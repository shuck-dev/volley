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

## Racket hit-detection is split from the physical bounce

Two separate concerns, conflated today on one collider:

- **Physical bounce + walls.** The existing `CharacterBody2D` collider. The ball physically bounces off it and `move_and_slide` uses it against walls. UNCHANGED. The physical bounce off the body footprint stays exactly as it is.
- **Racket hit-detection.** What counts as a registered hit (streak, sound, speed-up) must come only from the racket zone, not the whole body. This is DETECTION, not a bounce: a child `Area2D`, racket-sized, mid-body, that detects the ball entering and fires `on_ball_hit`. Position and size are PANEL-TUNABLE.

The racket `Area2D` carries its OWN `collision_layer`/`collision_mask`, separate from the body (layer/mask is per-CollisionObject, so the Area2D is its own object with its own channel). It masks the ball's layer so it detects the ball entering the racket zone; on its own layer so it is independent of the body's wall/bounce collision.

The `Area2D`'s `body_entered` fires when the ball enters; its handler routes `on_ball_hit` to the `Paddle`. The ball's physical bounce off the `CharacterBody2D` is untouched; the Area2D only changes WHAT REGISTERS as a hit.

## Collider visibility draws at runtime

The panel's show-collider toggle must DRAW the shapes in the running game. `CollisionShape2D.visible` does not draw at runtime (it is an editor property); use `get_tree().debug_collisions_hint` or a custom `_draw`. The toggle exists so both new colliders can be seen and aligned during tuning.

## Temporary: the panel sizes the placeholder via Node2D scale

The `PlayerSprite` panel drives the placeholder sprite's size with `sprite.scale.x/y`. This violates [[feedback_no_node2d_scale]] (scale compounds coordinate-space, hit-rect, and physics math) and is **deliberate temporary scaffolding**, accepted only because the panel is a throwaway tuning instrument whose job is to find a target dimension by eye, then be discarded. The product is the dimension number, not the scaled placeholder.

Before the real paddle art lands, this must change to bounds-based sizing: the sprite is shown at its true size via SpriteFrames authored at the tuned dimensions, not by scaling the Node2D. Tracked as debt; do not let the scale path survive into shipped art.

## Out of scope

Redesigning `grip_tape` (deleted, not replaced). Rebalancing `wrist_brace` beyond removing the size penalty. The SpriteFrames-swap pipeline that lands real art at the chosen dimensions.
