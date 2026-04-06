# Progression System

## Goal
Build the framework for persistent progression: earn FP from volleys, spend it on items that make the paddle better, and save/load across sessions. This is the economic backbone everything else plugs into.

**Points:** 10 (Spike)
**Dependencies:** HUD Pass (volley tracking, high score), Ball Scaling (ball speed feeds into upgrade effects)
**Unlocks:** Idle Play (FP economy, save/load), Upgrade Mechanics (item effects apply via this system), Upgrade Shop (FP spending)

## Current state

The attribute-based upgrade system is implemented: `UpgradeManager` owns `UpgradeDefinition` resources for paddle speed, paddle size, and ball start speed. Each has multiple levels with FP costs and per-level effect values. `GameRules` returns base values modified by purchased upgrade levels. FP earning, HUD display, save/load, and high score persistence are all working.

**Rework required:** The `UpgradeDefinition` / levelled attribute model is superseded by the item system (see `05-upgrade-mechanics.md`). `UpgradeManager` will be replaced by `ItemManager`. `GameRules` will query item effects instead of upgrade levels. The three starter upgrades will be removed and replaced with pre-break items. This rework is part of the Upgrade Mechanics ticket, not this one.

## Scope

### In scope
1. Friendship points (FP) earning
2. Save/load persistence
3. FP display in HUD
4. High score persistence

### Out of scope
- Item definitions and effects (Upgrade Mechanics)
- Shop UI and rotation (Upgrade Shop)
- Streak bonuses and FP multipliers (Balance Pass)

## Features

### 1. Friendship points (FP)
**Design:** FP is the single currency. Earned from volleys: 1 FP per paddle hit for prototype. Streak bonuses and multipliers are deferred to Balance Pass. FP should always be visible in the HUD so numbers are always going up.
**Tech:** FP tracked in `ProgressionData`. `game.gd` awards FP on `paddle_hit` signal. HUD displays current FP total.

### 2. Save/load
**Design:** Game saves automatically. Load on startup. The player should never lose progress. No manual save/load UI needed for prototype.
**Tech:** Save to `user://` filesystem using Godot's `FileAccess`. Data: FP balance, purchased items, high score. Save triggers: on item purchase, periodically (every 30s), on quit. JSON format for debuggability.

### 3. FP display in HUD
**Design:** FP count visible at all times in the HUD. Should feel like a number that's always climbing. Position near the volley counter so the player connects "hits = FP".
**Tech:** `hud.gd` exposes `update_friendship_point_balance(amount: int)`. `game.gd` calls it when FP changes.

### 4. High score persistence
**Design:** High score (best volley streak) persists across sessions. Previously session-only from HUD Pass.
**Tech:** Stored in `ProgressionData`, saved and loaded with the rest of progression state.

## Architecture

```
ProgressionData (scripts/progression/progression_data.gd)
  - friendship_point_balance: int
  - owned_item_ids: Array[String]
  - high_score: int
  - save() -> void
  - load() -> void

ItemManager (scripts/items/item_manager.gd)  [Autoload]
  - definitions: Array[ItemDefinition]
  - purchase(item_id: String) -> void
  - can_purchase(item_id: String) -> bool
  - is_owned(item_id: String) -> bool
  - get_modified_value(key: String, base: float) -> float
  - signal friendship_point_balance_changed(balance: int)

GameRules
  - get_paddle_speed() -> float   # queries ItemManager for stat modifiers
  - get_paddle_size() -> float
  - get_ball_speed_min() -> float

game.gd
  - Awards FP on paddle_hit signal
  - Updates HUD on FP change
```

## Test plan
- **Unit:** ProgressionData save/load round-trip, FP balance persists across restart, high score persists across restart
- **Unit:** ItemManager purchase logic, can't purchase when insufficient FP, owned items apply stat modifiers via GameRules
- **In-game:** FP increments on hit, displayed in HUD
- **In-game:** Close game, reopen: FP, owned items, and high score all restored

## Open questions
- FP per hit starts at 1 for prototype. Tune during Make Fun pass.
- Save interval of 30s is a starting point. Adjust if it causes perceptible hitches.
