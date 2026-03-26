# Progression System

## Goal
Build the framework for persistent progression: earn FP from volleys, spend it on upgrades that make the paddle better, and save/load across sessions. This is the economic backbone everything else plugs into.

**Points:** 10 (Spike)
**Dependencies:** HUD Pass (volley tracking, high score), Ball Scaling (ball speed feeds into upgrade effects)
**Unlocks:** Idle Play (FP economy, save/load), First Partner Unlock (FP spending), Balance Pass (tuning)

## Current state
- `GameRules` has 3 constants: `BALL_SPEED_MIN`, `BALL_SPEED_MAX`, `PADDLE_SPEED` — no way to modify at runtime
- No FP system, no save/load, no upgrades
- No upgrade UI

## Scope

### In scope
1. Friendship points (FP) earning
2. Three starter upgrades: paddle speed, paddle size, ball start speed
3. Upgrade system framework (data-driven, extensible)
4. Save/load persistence
5. FP display in HUD
6. Upgrade shop UI (simple panel)
7. High score persistence (currently session-only from HUD Pass)

## Features

### 1. Friendship points (FP)
**Design:** FP is the single currency. Earned from volleys — 1 FP per paddle hit for prototype. Streak bonuses and multipliers are deferred to Balance Pass. FP should always be visible in the HUD so numbers are always going up.
**Tech:** FP tracked in `ProgressionData`. `game.gd` awards FP on `paddle_hit` signal. HUD displays current FP total.

### 2. Starter upgrades
**Design:** Three upgrades that the player can feel immediately. Each has multiple levels with increasing cost. The player should have a meaningful choice about what to upgrade next.

| Upgrade | Effect | Why it matters |
|---|---|---|
| Paddle Speed | Increases `PADDLE_SPEED` | Reach the ball in time |
| Paddle Size | Increases paddle collision rect | Easier to connect |

**Design decisions needed:**
- Max levels per upgrade (suggestion: 5-10)
- Base cost and scaling curve (suggestion: base 10 FP, 1.5x per level)
- Effect per level (e.g. +50 paddle speed per level)

**Tech:** Upgrades are `UpgradeDefinition` resources — data only, no code per upgrade. `UpgradeManager` applies effects by modifying `GameRules` values at runtime. Adding new upgrades later means adding data, not code.

### 3. Upgrade system framework
**Tech:** Data-driven system where each upgrade definition specifies which `GameRules` value it modifies and by how much. `GameRules` changes from constants to a class that returns base values modified by purchased upgrades.

This framework is built to support future systems:
- **Power-ups:** temporary modifiers using the same `effect_key` system
- **Partner abilities:** permanent effects that stack with upgrades
- **Prestige:** reset upgrades for a multiplier

### 4. Save/load
**Design:** Game saves automatically. Load on startup. The player should never lose progress. No manual save/load UI needed for prototype.
**Tech:** Save to `user://` filesystem using Godot's `FileAccess`. Data: FP balance, purchased upgrade levels, high score. Save triggers: on upgrade purchase, periodically (every 30s), on quit. JSON format for debuggability.

### 5. FP display in HUD
**Design:** FP count visible at all times in the HUD. Should feel like a number that's always climbing. Position near the volley counter so the player connects "hits = FP".
**Tech:** `hud.gd` gets `update_fp(amount: int)` method. `game.gd` calls it when FP changes.

### 6. Upgrade shop UI
**Design:** Simple panel accessible from a HUD button. Shows all upgrades with: name, current level, effect description, cost. Purchase button greys out when can't afford. Closing the shop returns to gameplay. No pause needed — the game keeps running behind it.
**Tech:** New scene `scenes/upgrade_shop.tscn` with a `VBoxContainer` of upgrade rows. Reads from `UpgradeManager` for data, calls `purchase()` on buy. Updates FP display on purchase.

## Architecture

```
ProgressionData (scripts/progression_data.gd)
  - fp: int
  - upgrades: Dictionary  # { upgrade_id: level }
  - high_score: int
  - save() -> void
  - load() -> void

UpgradeDefinition (scripts/upgrade_definition.gd)  [Resource]
  - id: String
  - display_name: String
  - description: String
  - max_level: int
  - base_cost: int
  - cost_scaling: float
  - effect_key: String  # which GameRules value it modifies
  - effect_per_level: float

UpgradeManager (scripts/upgrade_manager.gd)
  - definitions: Array[UpgradeDefinition]
  - progression: ProgressionData
  - can_purchase(id: String) -> bool
  - purchase(id: String) -> void
  - get_cost(id: String) -> int  # current cost at current level
  - get_modified_value(key: String, base: float) -> float

GameRules
  - Changes from const to functions that query UpgradeManager
  - get_paddle_speed() -> float
  - get_paddle_size() -> float

game.gd
  - Owns UpgradeManager (autoload candidate for later)
  - Awards FP on paddle hit
  - Updates HUD on FP change
```

## Test plan
- **Unit:** ProgressionData save/load round-trip, UpgradeManager purchase logic, cost scaling, can't over-purchase, can't go negative FP
- **Unit:** GameRules returns modified values after upgrades
- **In-game:** FP increments on hit, displayed in HUD, persists across restart
- **In-game:** Buy upgrade → feel the difference immediately (paddle faster/bigger/steadier)
- **In-game:** Upgrade cost increases per level, can't buy when broke
- **In-game:** Close game, reopen → FP, upgrades, high score all restored

## Open questions
- What's the right cost curve? Need playtesting to tune.
- Should the shop pause the game or overlay it?
- How many levels per upgrade before it feels "done"?
- Should there be a visual/audio cue when upgrading? (Probably deferred to UI Polish)
