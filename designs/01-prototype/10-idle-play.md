# Idle Play

## Goal
Make the game play itself so it feels alive on your desktop, and reward the player for time away.

**Points:** 1 (Spike)
**Dependencies:** Progression System (FP economy, save/load), Ball Scaling (streak difficulty)
**Unlocks:** nothing directly, but enables passive FP accumulation as a game feel feature

## Current state

The paddle moves via `Input.get_axis("paddle_up", "paddle_down")` in `paddle.gd`. If no input is detected the paddle sits still. There is no AI, no idle detection, and no concept of FP rate multipliers.

## Scope

### In scope
1. Auto-play: paddle tracks the ball when the player is idle
2. Player takeover: manual input immediately resumes control
3. Idle FP rate: auto-play earns at a reduced rate
4. HUD indicator: "AUTO" label visible while auto-play is active
5. Background play: game keeps running and earning FP when the window is minimized or unfocused
6. Offline rewards: FP earned based on time away after closing the game, shown on next launch

### Out of scope
- AI difficulty scaling by upgrade level (deferred to Make Fun pass)
- Welcome back UI polish: animation, layout, milestone callouts (deferred to HUD pass)

## Features

### 1. Idle detection

The player toggles auto-play on/off with a dedicated button (e.g. spacebar, mapped to `"toggle_auto_play"` in the Input Map). Pressing it switches the paddle into auto-play mode; pressing it again returns control to the player.

No timeout or inactivity detection needed. The player explicitly opts in and out.

### 2. Auto-play AI

The AI moves the paddle toward the ball's Y position each frame. It is intentionally imperfect:

- **Reaction delay:** the AI targets where the ball *was* some frames ago, not its current position. Start with a 12-frame ring buffer.
- **Speed cap:** the AI uses a fraction of the paddle's full speed (start with `0.75`). This means it can miss fast balls and streaks end naturally.
- **No prediction:** the AI does not anticipate wall bounces. It just chases the Y. This produces natural-looking misses as speed increases.

The ball's position is already accessible via the `ball` export on `game.gd`. The auto-play logic needs a reference to the ball's Y.

### 3. FP rate in idle mode

`game.gd` currently awards `1 FP` per `paddle_hit`. Add an `_fp_multiplier: float` to `game.gd` that defaults to `1.0`. When the paddle is in auto-play mode, use `0.5`. The multiplier applies fractional FP via accumulation: track `_fp_accumulator: float`, add `1.0 * _fp_multiplier` each hit, award `floor(_fp_accumulator)` and keep the remainder.

### 4. HUD indicator

When auto-play is active, a label in the HUD shows "AUTO" (or similar). It is hidden by default and made visible on `idle_mode_changed(true)`, hidden again on `idle_mode_changed(false)`.

Follows the same pattern as `max_speed_label` in `hud.gd`: export the label, toggle `.visible` via an `update_auto_play(is_active: bool)` method. `game.gd` calls it when it receives `idle_mode_changed`.

### 5. Background play

When the window loses focus or is minimized, the game keeps running. Godot 4's default behavior is to pause physics when `application/run/pause_on_focus_loss` is enabled in Project Settings. This must be set to `false`.

The window focus state is tracked via `get_tree().get_root().focus_exited` / `focus_entered` signals (or `_notification(NOTIFICATION_WM_WINDOW_FOCUS_OUT/IN)`). When unfocused:

- Physics and auto-play AI keep running normally.
- FP continues accumulating at the idle rate.
- No visual changes are needed for prototype (the game just runs invisibly).

The idle FP rate is already lower than active play, so no separate background multiplier is needed.

### 6. Offline rewards

When the game launches, check how long the player was away and award FP for that time.

**Rate baseline:** track `idle_fp_per_minute: float` in `ProgressionData`. Update it periodically during auto-play (e.g. every 60s) by sampling the actual FP earned in idle mode. This makes the offline rate reflect the player's current paddle performance naturally.

**On quit:** save `last_quit_at: int` (Unix timestamp via `Time.get_unix_time_from_system()`) to `ProgressionData`.

**On load:** if `last_quit_at > 0`, calculate `seconds_away = now - last_quit_at`. Cap at `MAX_OFFLINE_SECONDS` (8 hours = 28800). Award `floor(seconds_away / 60.0 * idle_fp_per_minute)` FP. Reset `last_quit_at` to 0. Emit a `welcome_back(fp_earned: int, seconds_away: int)` signal from `SaveManager` so the HUD can show a summary.

**Welcome back display:** print a one-line message to the HUD: "Welcome back! +N FP". No animation, no popup. The polished version (fade, layout, milestone callouts) is deferred to a later HUD pass.

## Architecture

### Idle mode in `paddle.gd`

Add idle state directly to `paddle.gd` rather than a separate controller. The paddle already owns its own movement; idle mode is just a different movement source.

```
# paddle.gd additions
const AI_SPEED_FRACTION := 0.75
const AI_REACTION_FRAMES := 12

var _is_idle := false
var _ball_y_buffer: Array[float]   # ring buffer of ball Y positions
var _ball: Node2D                  # injected by game.gd
```

Add a `toggle_auto_play()` method that flips `_is_idle` and emits `idle_mode_changed`.

`_physics_process` flow:
1. If `_is_idle` is false: read input axis and move manually.
2. If `_is_idle` is true: push ball's current Y to ring buffer, target the oldest Y in the buffer, move toward it at `_paddle_speed * AI_SPEED_FRACTION`.

Emit a `idle_mode_changed(is_idle: bool)` signal so `game.gd` can adjust the FP multiplier.

### Changes to `game.gd`

- Connect to `paddle.idle_mode_changed` in `_ready`.
- On signal: set `_fp_multiplier` to `0.5` (idle) or `1.0` (manual).
- Replace `_upgrade_manager.add_friendship_points(1)` with fractional accumulation logic.

### Ball reference

`paddle.gd` needs a reference to the ball to read its Y position. Options:
- Export `var ball: RigidBody2D` on `paddle.gd` and wire it in the scene.
- Inject it from `game.gd` after `_ready` via a `set_ball(b: RigidBody2D)` method.

Prefer injection from `game.gd` since `game.gd` already owns both `ball` and `paddle` exports. This keeps the paddle's scene wiring minimal.

### Background play

Disable pause on focus loss in Project Settings: `application/run/pause_on_focus_loss = false`.

Connect to `get_tree().get_root().focus_exited` / `focus_entered` in `game.gd` to track focus state if needed for future visual changes. No other code changes required.

### Offline rewards

Add to `ProgressionData`:

```
var last_quit_at: int = 0          # Unix timestamp, 0 means no prior session
var idle_fp_per_minute: float = 0.0
```

Include both fields in `to_dict()` / `from_dict()`.

`SaveManager` gains a `calculate_offline_rewards() -> int` method called during `_ready` before emitting any ready signals. It reads `last_quit_at`, computes FP owed, adds it to `friendship_point_balance`, clears `last_quit_at`, and returns the FP awarded (0 if none). Emit a `welcome_back(fp_earned: int, seconds_away: int)` signal if `fp_earned > 0`.

`idle_fp_per_minute` is updated in `game.gd`: sample FP earned in idle mode over 60s intervals and write the result back to `ProgressionData` via `SaveManager`.

On quit (`_notification(NOTIFICATION_WM_CLOSE_REQUEST)` in `game.gd`): write `last_quit_at = Time.get_unix_time_from_system()` and call `save_to_disk()`.

## Test plan

- **Unit:** `toggle_auto_play`: switches to idle on first call, back to manual on second call
- **Unit:** AI movement: paddle moves toward delayed ball Y, does not exceed speed cap
- **Unit:** FP accumulation: `1.0 * 1.0` multiplier awards 1 FP per hit; `1.0 * 0.5` accumulates fractional FP correctly over multiple hits
- **Unit:** `idle_mode_changed` signal fires on transition in both directions
- **In-game:** press space, observe paddle tracking the ball
- **In-game:** press space again, confirm paddle returns to manual control
- **In-game:** verify FP increments slower during auto-play than during manual play
- **In-game:** minimize window, wait 30s, restore: FP should have incremented during background time
- **Unit:** `calculate_offline_rewards`: returns 0 when `last_quit_at` is 0; returns correct FP for a 1-hour gap; caps at 8 hours; clears `last_quit_at` after calculation
- **Unit:** `ProgressionData` round-trip includes `last_quit_at` and `idle_fp_per_minute`
- **In-game:** close game, wait a few minutes, reopen: welcome back label appears with correct FP amount

## Open questions

- `AI_SPEED_FRACTION` of 0.75 and `AI_REACTION_FRAMES` of 12 are starting values. Tune during Make Fun pass so the AI misses believably without feeling broken.
