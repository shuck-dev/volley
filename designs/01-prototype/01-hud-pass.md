# HUD Pass

## Goal
Complete the volley tracking system and display it properly in the HUD.

## Features

### 1. Volley reset on miss
- Detect when ball hits left or right wall (missed by paddle)
- Reset volley count to 0
- Ball signal: `ball_missed` emitted on left/right wall contact

### 2. High score tracking
- Track best volley streak across resets
- Update high score when current streak exceeds it
- Display in HUD alongside current volley count

### 3. VolleyTracker refactor
- Extract volley logic from `game.gd` into `scripts/volley_tracker.gd`
- Pure logic class (no node dependencies), unit-testable
- Responsibilities:
  - `hit()` — increment current streak
  - `reset()` — save high score if beaten, reset streak to 0
  - `current_streak: int` — current volley count
  - `high_score: int` — best streak
- `game.gd` calls VolleyTracker methods, updates HUD

### 4. HUD updates
- Add high score label to HUD scene
- Layout: volley count top center, high score below it
- HUD script exposes `update_volley(count: int)` and `update_high_score(score: int)`

## Architecture

```
VolleyTracker (scripts/volley_tracker.gd)
  - current_streak: int
  - high_score: int
  - hit() -> void
  - reset() -> void

Ball (scripts/ball.gd)
  - signal paddle_hit
  - signal ball_missed

HUD (scripts/hud/hud.gd)
  - update_volley(count: int)
  - update_high_score(score: int)

game.gd
  - Owns VolleyTracker instance
  - Connects ball signals to tracker
  - Updates HUD on changes
```

## Test plan
- Unit test VolleyTracker: hit increments, reset clears, high score persists across resets
- In-game: volley count increments on paddle hit, resets on wall hit, high score updates
