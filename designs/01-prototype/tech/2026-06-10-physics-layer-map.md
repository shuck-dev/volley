# Physics collision layer map

The 2D collision layers, what sits on each, and what masks what. Written because the layers were conflated (the ball, the floor, and the walls shared a layer), which made splitting paddle-ball contact from paddle-wall contact intractable until the real assignments were traced. `.tscn` stores the raw integer bitmask; this doc uses raw values (layer "4" = bit 3).

## The non-obvious bit: the ball's layer is set at RUNTIME

The ball's `collision_layer`/`collision_mask` are NOT the `ball.tscn` defaults. They are assigned per BALL STATE by `ball_state_config.gd` from the state resources:

- `play_active.tres`, `out_rest.tres`: layer 2, mask 3 (the in-play ball is on **layer 2**).
- `stored.tres`: 0 / 0 (inert while held).

So reading `ball.tscn` for the ball's layer is wrong; the state config is the source of truth.

## Current map (as traced)

| Raw layer | Role | Objects on it | Who masks it |
|---|---|---|---|
| 1 | Court environment | court floor, court walls, ceiling (all default-layer) | the ball (so it bounces off them); paddle body |
| 2 | In-play ball | the ball, while in play | miss zones (mask 2); paddle body (old mask 3) |
| 4 | Venue walls | venue left/right bounds | (venue movement) |
| 8 | Racket hitbox | paddle `RacketHitbox` Area2D | masks the ball |
| 16 | Paddle body | paddle `CharacterBody2D` | masks the environment |

## The conflation that caused the trouble

The paddle body's old `mask = 3` (layers 1+2) made it collide with BOTH the court environment (layer 1: floor, walls) AND the in-play ball (layer 2). One mask, two intents. The paddle stood on the floor (good) and physically bounced the ball off its whole footprint (the thing we are removing).

Dropping the ball contact is therefore: **paddle body masks 1 (environment), NOT 2 (ball).** The floor and walls stay collided with; the ball is ignored by the body. The `RacketHitbox` Area2D (layer 8, mask matching the in-play ball's layer 2) detects the ball instead, and the return is code-applied (`effect_processor`). See `2026-06-10-paddle-sprite-sizing-decouple.md`.

## Target map

| Raw layer | Role |
|---|---|
| 1 | Environment (floor, walls, ceiling) |
| 2 | In-play ball |
| 4 | Venue walls |
| 8 | Racket hitbox (detection) |
| 16 | Paddle body |

Wiring:
- **Ball** (in play): layer 2, masks 1 (bounce off environment) + the racket detection happens via the Area2D masking layer 2, not the ball masking the racket.
- **Paddle body**: layer 16, mask 1 (environment only). Stands on floor, stops at walls, ignores the ball.
- **Racket Area2D**: layer 8, mask 2 (the in-play ball). Detects, routes `hit_by_paddle`.
- **Environment** (floor/walls/ceiling): layer 1, static.
- **Miss zones**: mask 2 (the in-play ball). Unchanged.

## Correction needed

The racket Area2D was provisionally set to mask 1 (assuming the ball was on layer 1). The ball in play is on layer **2**, so the racket must mask **2**, not 1. The paddle body's mask must be **1** (environment), not 0 (which broke floor collision).
