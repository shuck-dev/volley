# Idle Progression

## Goal
Build the framework for persistent progression that power-ups, modifiers, and upgrades can plug into later.

## Features

### 1. Friendship points
- Earn friendship points (FP) from volleys (e.g. 1 per hit, bonus for streaks)
- Persistent across sessions (save/load)
- Display in HUD

### 2. Upgrade system framework
- Data-driven upgrade definitions (cost, effect, max level)
- Purchase upgrades with friendship points (FP)
- Upgrades modify game rules (paddle speed, ball speed, etc.)
- Extensible — new upgrades are just data, no new code needed

### 3. Save/load
- Save progression to user filesystem
- Load on game start
- Data: friendship points (FP), purchased upgrades, high score

### 4. Upgrade shop UI
- Simple menu/panel to browse and buy upgrades
- Shows cost, current level, effect description
- Accessible from HUD or pause menu

## Architecture

```
ProgressionData (scripts/progression_data.gd)
  - fp: int
  - upgrades: Dictionary  # { upgrade_id: level }
  - high_score: int
  - save() -> void
  - load() -> void

UpgradeDefinition (scripts/upgrade_definition.gd)
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
  - can_purchase(id) -> bool
  - purchase(id) -> void
  - get_modified_value(key, base) -> float  # applies upgrade effects

GameRules
  - Extended to read modified values from UpgradeManager
```

## Extension points
- **Power-ups**: temporary modifiers using the same effect_key system
- **Modifiers**: permanent effects that stack with upgrades
- **Auto-play**: upgrade that enables AI paddle control
- **Prestige**: reset upgrades for a multiplier (future)

## Dependencies
- HUD pass (volley tracking, high score)
