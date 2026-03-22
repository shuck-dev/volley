# HUD Pass

## Goal
Complete the volley tracking system and display it properly in the HUD. This is the foundation that Progression System and Ball Scaling build on.

**Points:** 2
**Dependencies:** Pong Prototype (done)
**Unlocks:** Ball Scaling, Progression System (FP display, high score persistence)

## Current state
- Ball emits `paddle_hit` on paddle contact — working
- `game.gd` counts volleys inline and writes directly to a `CanvasLayer/Label` — bypasses `hud.gd`
- `hud.gd` exists with `update_volley_count()` but is not wired up
- No miss detection, no volley reset, no high score tracking
- No `VolleyTracker` class

## Scope

### In scope
1. Volley reset on miss
2. High score tracking (session only — persistence comes with Progression System)
3. VolleyTracker refactor
4. HUD wiring and high score display

### Out of scope
- FP display (Progression System)
- Streak-based visual feedback or animations (UI Polish in v0.5)
- Ball speed changes during streak (Ball Scaling)
- Save/load of high score (Progression System)

## Features

### 1. Volley reset on miss
**Design:** Define what counts as a miss — ball contacts the left or right wall.
**Tech:** Add `ball_missed` signal to `ball.gd`, emitted on left/right wall contact. `game.gd` connects this to reset the volley count.

### 2. High score tracking
**Design:** High score is the best volley streak in the current session. Resets when the game closes (persistence deferred to Progression System).
**Tech:** Track best streak, update when current streak exceeds it.

### 3. VolleyTracker refactor
**Tech:** Extract volley logic from `game.gd` into `scripts/volley_tracker.gd`. Pure logic class (no node dependencies), unit-testable.

- `hit()` — increment current streak
- `reset()` — save high score if beaten, reset streak to 0
- `current_streak: int` — current volley count
- `high_score: int` — best streak

`game.gd` owns a VolleyTracker instance, connects ball signals to it, and updates HUD on changes.

### 4. HUD wiring and high score display
**Design:** Layout — volley count top center, high score below it.
**Tech:**
- Add high score label to `hud.tscn`
- Wire `game.gd` to call `hud.gd` methods instead of writing to the label directly
- `hud.gd` exposes `update_volley(count: int)` and `update_high_score(score: int)`

## Architecture

```
VolleyTracker (scripts/volley_tracker.gd)
  - current_streak: int
  - high_score: int
  - hit() -> void
  - reset() -> void

Ball (scripts/ball.gd)
  - signal paddle_hit      (existing)
  - signal ball_missed      (new)

HUD (scripts/hud/hud.gd)
  - update_volley(count: int)
  - update_high_score(score: int)

game.gd
  - Owns VolleyTracker instance
  - Connects ball signals to tracker
  - Updates HUD on changes
```

## Test plan
- **Unit:** VolleyTracker — hit increments, reset clears streak, high score persists across resets, high score only updates when beaten
- **In-game:** volley count increments on paddle hit, resets on wall miss, high score updates and survives streak resets
- **Integration:** `game.gd` no longer writes to labels directly, all HUD updates go through `hud.gd`
