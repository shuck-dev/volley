# Paddle Bounce

Implementation spec for the post-bounce direction computed when the ball strikes a paddle. Court-bound mechanics live in [`01-court-control.md`](01-court-control.md); ball state transitions live in [`02-ball-lifecycle.md`](02-ball-lifecycle.md).

## Player goal

The paddle is a tool the player aims with. Where the ball touches the paddle decides where the ball goes. Moving the paddle while striking imparts motion the player can feel. Centre hits don't read as the ball ignoring the paddle, and edge hits don't read as the ball getting stuck against the back wall.

## Genre convention

The reference games and tutorials surveyed (Pong 1972's 8-segment lookup, Breakout / Arkanoid family, MDN Phaser Breakout, CS50 Breakout, StudyPlan SDL2, MonoGame Breakernoid, Lethal League, Windjammers, Wii / Switch Sports tennis) all discard the incoming angle on paddle contact and compute the post-bounce direction from contact offset, player input at contact, or both. Pure mirror reflection is described in the source material as "boring" and "the most simplistic Pong" — the design Alcorn explicitly moved away from in 1972. Sources cited in `ai/scratchpads/paddle-bounce-research.md`.

So Volley's bounce replaces the incoming angle. That's the natural shape; preserving the incoming angle is the unnatural one.

## Geometry

Paddles are vertical bodies on the left and right of the court. A bounce produces:

- A **horizontal sign** away from the struck paddle (the ball heads back across the court).
- A **vertical component** signed by how far above or below paddle centre the contact landed.

The ball's speed magnitude is preserved through the bounce; only direction changes.

## Components of the post-bounce direction

The direction is built from three contributions:

### 1. Contact offset

Normalise the contact point against paddle half-height: `offset_norm = clamp((ball.y - paddle.y) / paddle.half_height, -1, +1)`. This is the primary aim signal. The mapping from `offset_norm` to the vertical component of the new direction is governed by `paddle_return_angle_max_degrees` — the steepest angle off horizontal an extreme edge hit can produce. Centre hit (`offset_norm = 0`) returns flat across the court; edge hit (`offset_norm = ±1`) returns at the configured max.

### 2. Paddle velocity at contact

The paddle's vertical velocity at the moment of contact biases the return. A paddle moving upward into the ball adds upward bias; a paddle moving downward adds downward bias. The strength is a tunable coefficient (working name `paddle_english`): zero means contact offset is the only aim signal, higher values let a moving paddle pull or push the ball off the offset-only line. This is the signal that makes the paddle read as an active tool rather than a passive zone-strip.

### 3. Minimum-angle clamp

After combining offset and english, clamp the vertical component so the post-bounce direction never lands within a narrow band of pure horizontal or pure vertical. Pure horizontal at centre reads as "the ball ignored me." Pure vertical at the extreme edge reads as "I'm stuck bouncing off the back wall." A small floor on both ends (working values: ≥3° off horizontal, ≤87° off horizontal) keeps every bounce visibly directional without making the math non-monotonic in offset.

## Resulting math (sketch)

```
sign_x        = sign(ball.vx_at_contact)        # away from paddle
offset_norm   = clamp((ball.y - paddle.y) / paddle.half_height, -1, +1)
offset_angle  = offset_norm * deg_to_rad(paddle_return_angle_max_degrees)
english_angle = paddle.linear_velocity.y * paddle_english_coefficient
target_angle  = offset_angle + english_angle
target_angle  = clamp_off_horizontal_and_vertical(target_angle)
direction     = Vector2(-sign_x * cos(target_angle), sin(target_angle))
ball.linear_velocity = direction * ball.speed
```

The exact form of `clamp_off_horizontal_and_vertical` and the units of `paddle_english_coefficient` are tuning decisions, not architectural ones — the implementer picks the cleanest forms and exposes them as tunables.

## Tunables

- `paddle_return_angle_max_degrees` — already on `BaseStatsConfig`. Maximum angle off horizontal an extreme edge hit produces.
- `paddle_english_coefficient` — new. Multiplier on paddle vertical velocity when computing the bounce angle bias.
- Min-angle floor and max-angle ceiling — new constants on the bounce module (not item-tunable; safety guards).

## Out of scope

- Spin / curve in flight. The bounce computes a new direction at the contact frame; the ball travels in a straight line afterwards as today.
- Different bounce behaviour per ball type or per paddle role. Player paddle, partner paddle, and AI paddle all use the same bounce.
- Swing-timing or held-input direction selection (Wii / Lethal League pattern). The Volley paddle is positional, not swing-based.
