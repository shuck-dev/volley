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

## Out of scope

Redesigning `grip_tape` (deleted, not replaced). Rebalancing `wrist_brace` beyond removing the size penalty. The SpriteFrames-swap pipeline that lands real art at the chosen dimensions.
