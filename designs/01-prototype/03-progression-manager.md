# Progression Manager

## Goal

Centralise progression milestone checks into a single system that reacts to game state changes and unlocks features when conditions are met. The Progression Manager sits between the raw data (ProgressionData) and the features that gate on progression (clearance, future milestones). It owns the "when does X unlock?" question so that individual systems do not have to.

**Dependencies:** Progression System (ProgressionData, SaveManager), Item System (ItemManager signals)
**Unlocks:** Clearance UI (gated on clearance unlock), Milestone System (Beta, plugs into this manager)

---

## Why a separate manager

ProgressionData is a data bag: it holds state and serialises it. It does not watch signals or make decisions. SaveManager handles disk I/O. ItemManager handles items, effects, and FP balance. None of these should own "when the player crosses 50 FP, unlock the clearance," because that is a progression milestone, not an item concern or a persistence concern.

The Progression Manager listens to signals from other systems and checks milestone conditions. When a condition is met, it flips the flag in ProgressionData, persists, and emits a signal for the UI to react. This keeps milestone logic in one place and gives future milestones (competition levels, act transitions) a natural home.

---

## Prototype scope

For prototype, the only milestone is the clearance unlock. The manager is intentionally minimal: one signal connection, one threshold check. The architecture is set up so that adding milestones later is additive, not a refactor.

---

## Clearance unlock

The clearance unlocks when the player's friendship balance reaches the threshold for the first time. The unlock is permanent: it does not re-lock if the balance drops below the threshold (e.g. after taking items).

- **Threshold:** 50 FP (tuning target for Make Fun pass)
- **Trigger:** `ItemManager.friendship_point_balance_changed` signal
- **Persistence:** `ProgressionData.clearance_unlocked` boolean, backward-compatible with old saves (defaults to false)
- **Signal:** `clearance_unlocked_changed(is_unlocked: bool)` emitted once on unlock. Emitted via `call_deferred` on startup if already unlocked, so listeners that connect during `_ready` receive it.

---

## Future: milestone system

The milestone system (Beta) will extend the Progression Manager with:

- A list of milestone definitions (threshold, competition level, reward)
- Milestone-gated unlocks beyond the clearance (act transitions, narrative beats)
- Milestone UI integration (badges, competition level display)

The Progression Manager is the natural owner of this. The current clearance unlock is effectively milestone zero: same pattern (watch a value, check a threshold, flip a flag, emit a signal), just hardcoded for now.

## Configuration

Progression thresholds (e.g. clearance unlock at 50 FP) should live in a `ProgressionConfig` resource (`res://resources/progression_config.tres`), following the same pattern as `AutoPlayConfig`. This keeps tuning values out of code and editable in the Godot inspector. The config resource is exported on the ProgressionManager and holds all threshold values that the Make Fun pass will need to adjust.

For prototype, the config contains one field: `clearance_unlock_threshold`. As milestones are added, their thresholds go here too.

---

## Architecture

```
ProgressionManager (scripts/progression/progression_manager.gd)  [Autoload]
  Listens to:
    - ItemManager.friendship_point_balance_changed

  Owns:
    - clearance_unlocked_changed(is_unlocked: bool) signal
    - is_clearance_unlocked() -> bool
    - CLEARANCE_UNLOCK_THRESHOLD: int = 50

  Reads/writes:
    - ProgressionData.clearance_unlocked (via SaveManager.get_progression_data())

  Autoload order: after SaveManager and ItemManager
```

The HUD connects to `ProgressionManager.clearance_unlocked_changed` to show/hide the clearance button. The clearance panel does not need to know about the Progression Manager; it only needs ItemManager for purchasing.

---

## Test plan

- **Unit:** Clearance not unlocked by default
- **Unit:** Clearance unlocks when FP reaches threshold
- **Unit:** Clearance does not unlock below threshold
- **Unit:** Signal emitted on unlock, not emitted below threshold, not emitted twice
- **Unit:** Clearance stays unlocked when balance drops after a purchase
- **Unit:** ProgressionData round-trips clearance_unlocked through to_dict/from_dict
- **Unit:** Old save data without clearance_unlocked field defaults to false
