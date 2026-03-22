# Ball Scaling

## Goal
Ball speeds up during a streak, creating a natural difficulty curve. The longer you rally, the harder it gets.

**Points:** 1
**Dependencies:** HUD Pass (volley tracking)
**Unlocks:** Progression System (upgrade effects interact with speed curve)

## Features

### 1. Streak-based speed increase
**Design:** Ball gets faster with each hit in a streak. Resets to base speed on miss. The ramp should feel gradual — the player shouldn't notice individual hits getting harder, but after 20+ hits the ball is noticeably fast.
**Tech:** On `paddle_hit`, increase ball speed by a fixed amount (e.g. +10-20 per hit), clamped to `BALL_SPEED_MAX`. On `ball_missed`, reset to `BALL_SPEED_MIN`.

### 2. Paddle hit sound
**Design:** Audio feedback on every paddle hit. Should feel satisfying and not annoying at high frequency. Consider pitch shifting up slightly as the streak builds for subtle tension.
**Tech:** `AudioStreamPlayer` on the ball or paddle, triggered on `paddle_hit`.

## Test plan
- Ball speed increases visibly over a long streak
- Ball resets to base speed after a miss
- Speed never exceeds `BALL_SPEED_MAX`
- Hit sound plays on every paddle contact
