# Paddle Bounce

Implementation spec for the post-bounce direction computed when the ball strikes a paddle. Court-bound mechanics live in [`01-court-control.md`](01-court-control.md); ball state transitions live in [`02-ball-lifecycle.md`](02-ball-lifecycle.md).

## Player goal

The paddle is a tool the player aims with. Where the ball touches the paddle decides where the ball goes. Moving the paddle while striking imparts motion the player can feel. Centre hits don't read as the ball ignoring the paddle, and edge hits don't read as the ball getting stuck against the back wall.

## Genre convention

Volley's bounce replaces the incoming angle rather than reflecting it. That's the natural shape for the genre; preserving the incoming angle is the unnatural one. See [`designs/research/paddle-bounce.md`](../../research/paddle-bounce.md) for the survey and citations.

## Geometry

Paddles are vertical bodies on the left and right of the court. A bounce produces:

- A **horizontal sign** away from the struck paddle (the ball heads back across the court).
- A **vertical component** signed by how far above or below paddle centre the contact landed, optionally biased by paddle motion.

The ball's speed magnitude is preserved through the bounce; only direction changes.

## Components of the post-bounce direction

The direction is built from three contributions:

### 1. Contact offset

Normalise the contact point against paddle half-height: `offset_norm = clamp((ball.y - paddle.y) / paddle.half_height, -1, +1)`. This is the primary aim signal. The mapping from `offset_norm` to the vertical component of the new direction is governed by `paddle_return_angle_max_degrees`, the steepest angle off horizontal an extreme edge hit can produce. Centre hit (`offset_norm = 0`) returns flat across the court; edge hit (`offset_norm = ±1`) returns at the configured max.

### 2. Paddle velocity at contact (english)

The paddle's vertical velocity at the moment of contact biases the return. A paddle moving upward into the ball adds upward bias; a paddle moving downward adds downward bias. The strength is the `paddle_english_coefficient` tunable: zero means contact offset is the only aim signal, higher values let a moving paddle pull or push the ball off the offset-only line. This is the signal that makes the paddle read as an active tool rather than a passive zone-strip.

Crucially, english does not sum into offset. When the paddle is moving, the final angle is forced into the english's hemisphere: `(|offset_angle| + |offset_english|) * sign(english)`. A downward-moving paddle striking the top edge bounces downward, never upward. The motivation is that a player swinging the paddle expects the bounce to follow the swing; an additive sum would let a strong offset cancel a swing the player can see and feel.

### 3. Minimum and maximum angle clamp

After combining offset and english, clamp the vertical component so the post-bounce direction never lands within a narrow band of pure horizontal or pure vertical. Pure horizontal at centre reads as "the ball ignored me." Pure vertical at the extreme edge reads as "I'm stuck bouncing off the back wall." A small floor on both ends (default 3° off horizontal, 87° off horizontal) keeps every bounce visibly directional without making the math non-monotonic in offset. On a true-zero angle (centre hit, paddle stationary) the incoming y-sign breaks the tie so the ball continues in the direction it was already travelling.

## Resulting math (sketch)

```
horizontal_sign = sign(ball.vx_at_contact)      # already points away from struck paddle
offset_norm     = clamp((ball.y - paddle.y) / paddle.half_height, -1, +1)
offset_angle    = offset_norm * deg_to_rad(paddle_return_angle_max_degrees)
english_angle   = paddle.velocity.y * paddle_english_coefficient
incoming_y_sign = sign(ball.vy_at_contact)
target_angle    = blend_english_into_offset(offset_angle, english_angle)
target_angle    = clamp_off_horizontal_and_vertical(target_angle, incoming_y_sign)
direction       = Vector2(horizontal_sign * cos(target_angle), sin(target_angle))
ball.linear_velocity = direction * ball.speed
```

`blend_english_into_offset` returns `offset_angle` when english is zero, otherwise `(|offset_angle| + |english_angle|) * sign(english_angle)`. `clamp_off_horizontal_and_vertical` enforces the min/max magnitude and uses `incoming_y_sign` as the tie-breaker on zero.

## Tunables

All four live on `PaddleConfig` and resolve through `Stats.resolve`, so items can modify them:

- `paddle_return_angle_max_degrees`: maximum angle off horizontal an extreme edge hit produces.
- `paddle_english_coefficient`: multiplier on paddle vertical velocity when computing the english bias (radians per pixel/sec).
- `paddle_bounce_min_angle_degrees`: dead-zone floor; default 3°.
- `paddle_bounce_max_angle_degrees`: dead-zone ceiling; default 87°.

Default min/max read as safety guards rather than gameplay levers, but they go through the same resolve path as the others; an item could legitimately push them.

## Out of scope

- Spin / curve in flight. The bounce computes a new direction at the contact frame; the ball travels in a straight line afterwards as today.
- Different bounce behaviour per ball type or per paddle role. Player paddle, partner paddle, and AI paddle all use the same bounce.
- Swing-timing or held-input direction selection (Wii / Lethal League pattern). The Volley paddle is positional, not swing-based.
