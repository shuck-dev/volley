# Effect System Class Design

Technical design for the unified effect framework. All gameplay modifiers (items, partners, future sources) flow through one system.

---

## Core principle

Effects are data, not code. No per-item scripts. Every effect is a combination of trigger + conditions + outcomes defined in resources. The evaluation loop is centralized. Adding a new item means adding data, not writing a new class.

---

## Class diagram

```mermaid
classDiagram
    class ItemDefinition {
        +key: String
        +type: StringName
        +display_name: String
        +descriptions: String[]
        +base_cost: int
        +cost_scaling: float
        +max_level: int
        +effects: Effect[]
        +get_effects_for_level(level: int) Effect[]
        +get_key() String
    }

    class Partner {
        +key: String
        +relationship_level: int
        +effects: Effect[]
        +get_effects_for_level(level: int) Effect[]
    }

    class Effect {
        +trigger: Trigger
        +conditions: Condition[]
        +outcomes: Outcome[]
        +min_active_level: int
        +max_active_level: Variant
    }

    class Trigger {
        <<sub-resource>>
        +type: StringName
        +parameters: Dictionary
    }

    class Condition {
        <<sub-resource>>
        +type: StringName
        +parameters: Dictionary
    }

    class Outcome {
        <<sub-resource>>
        +type: StringName
        +parameters: Dictionary
    }

    class ItemManager {
        +items: ItemDefinition[]
        -progression: ProgressionData
        -effect_manager: EffectManager
        +get_level(item_key: String) int
        +calculate_cost(item_key: String) int
        +can_purchase(item_key: String) bool
        +purchase(item_key: String) bool
        +remove_level(item_key: String)
        +get_friendship_point_balance() int
        +add_friendship_points(points: int)
        +subtract_friendship_points(points: int)
    }

    class EffectManager {
        -effect_state: EffectState
        +get_stat(key: StringName) float
        +is_game_state_active(state: StringName) bool
        +register_source(source: ItemDefinition, level: int)
        +unregister_source(source: ItemDefinition)
        -apply_always_effect(effect: Effect, source_key: String)
    }

    class EffectState {
        <<internal>>
        -base_values: Dictionary[StringName, float]
        -add_modifiers: Array[StatModifier]
        -multiply_modifiers: Array[StatModifier]
        -active_states: Dictionary[StringName, String]
        +register_base_values(values: Dictionary)
        +get_stat(key: StringName) float
        +add_modifier(modifier: StatModifier)
        +remove_modifiers_by_source(source_key: String)
        +set_state(state: StringName, source_key: String)
        +clear_state(state: StringName)
        +is_state_active(state: StringName) bool
    }

    class StatModifier {
        <<internal>>
        +source_key: String
        +stat_key: StringName
        +operation: Operation
        +value: float
    }

    ItemManager "1" --> "0..*" ItemDefinition
    ItemManager "1" --> "1" EffectManager
    ItemDefinition "1" --> "1..*" Effect
    Partner "1" --> "1..*" Effect
    Effect "1" --> "1" Trigger
    Effect "1" --> "0..*" Condition
    Effect "1" --> "1..*" Outcome
    EffectManager "1" --> "1" EffectState
    EffectState "1" --> "0..*" StatModifier
```

| Class | Role |
|---|---|
| `ItemDefinition` | Pure data template (Resource): display info, cost formula, and effect definitions |
| `Partner` | NPC companion that provides effects scaled by relationship level |
| `Effect` | A single trigger + conditions + outcomes rule, gated by min/max active level |
| `Trigger` | When the effect fires (always, on_miss, on_hit, etc.). Type is a StringName, not an enum |
| `Condition` | Optional gate that must pass before outcomes execute. Type is a StringName |
| `Outcome` | What happens when the effect fires (modify_stat, spawn_ball, etc.). Type is a StringName |
| `ItemManager` | Ownership and economy: tracks what the player owns, levels, FP balance. Delegates stat effects to EffectManager on level change |
| `EffectManager` | Evaluation engine and public stat API: registers/unregisters effect sources, dispatches outcomes by trigger type, delegates stat queries to internal EffectState |
| `EffectState` | Internal to EffectManager: holds base values (from GameRules.BASE_STATS), flat modifier arrays, and named game states. Not a separate autoload |
| `StatModifier` | A single additive or multiplicative change to a stat, stored in flat typed arrays |

**Instance state note:** `ItemDefinition` is a pure data template, no level or state on the resource itself. Level is stored per-player in `ProgressionData` (keyed by item key). `ItemManager` calls `EffectManager.unregister_source` then `register_source` on every level change, passing the new level to `get_effects_for_level()`. Degradation is tracked per-item-key in `EffectState` and manipulated via the `increment_degradation` outcome and `degradation_at` condition. Broken state is derived: `degradation >= 100`.

---

## Type keys (StringName, not enums)

All type fields use `StringName` (e.g. `&"always"`, `&"modify_stat"`) for O(1) comparison and data-driven extensibility. New types are handled by adding dispatch branches in `EffectManager`, no enum changes needed.

### DescriptionState

```
default
power_revealed
narrative_revealed
```

Indexes into `Item.descriptions`. Current state per item is tracked in `ProgressionData`.

### TriggerType

```
always
on_miss
on_hit
on_personal_best
on_streak_start
on_streak_multiple
on_streak_milestone
on_edge_hit
on_max_speed_reached
on_ball_behind_paddle
```

### ConditionType

```
game_state_is
game_state_is_not
delay_random
degradation_at
degradation_below
```

### OutcomeType

```
modify_stat
modify_stat_until_miss
multiply_stat_temporary
spawn_ball
clear_extra_balls
set_game_state
deflect_ball
spawn_gravity_well
intensify_gravity_well
award_friendship_points
expand_kit_slots
increment_degradation
share_stats_with_partner
momentum_boost
oscillate_stat
roll_table
set_ball_speed
```

### ModifierOp

```
add
multiply
```

### ExpiryCondition

```
while_owned          # removed when source unequipped/destroyed
duration             # timer, removed after N seconds
until_miss           # cleared on next miss, stackable
until_state_exits    # cleared when a named game state ends
until_next_trigger   # cleared when the same effect fires again
```

---

## Evaluation flow

### Event to outcome

```mermaid
sequenceDiagram
    participant Game
    participant EffectManager
    participant EffectState

    Game->>EffectManager: on_game_event("on_miss", {})
    EffectManager->>EffectManager: collect matching effects (trigger + conditions)
    EffectManager->>EffectManager: execute outcomes for each match
    EffectManager->>EffectState: add/remove modifiers, set/clear states
    EffectManager->>Game: execute actions (spawn_ball, deflect, etc.)
    EffectManager-->>Game: emit presentation signals
    EffectState->>EffectState: clear_until_miss_modifiers()
```

### Outcome routing

Each outcome type routes to a different system. EffectManager handles the dispatch.

```mermaid
flowchart LR
    Outcome --> EffectState["<b>EffectState</b><br/>modify_stat<br/>multiply_stat_temporary<br/>modify_stat_until_miss<br/>oscillate_stat<br/>share_stats_with_partner<br/>momentum_boost<br/>set_game_state<br/>increment_degradation"]
    Outcome --> GameActions["<b>Game</b><br/>spawn_ball<br/>clear_extra_balls<br/>deflect_ball<br/>spawn_gravity_well<br/>intensify_gravity_well<br/>set_ball_speed"]
    Outcome --> ItemManager["<b>ItemManager</b><br/>expand_kit_slots"]
    Outcome --> Economy["<b>ItemManager</b><br/>award_friendship_points"]
    Outcome --> Self["<b>EffectManager</b><br/>roll_table (re-enters evaluation)"]
```

---

## Stat resolution

```mermaid
flowchart LR
    Base[Base value] --> Add[Sum add modifiers] --> Multiply[Apply multiply modifiers] --> Clamp[Clamp to valid range] --> Final[Final value]
```

`EffectManager.get_stat(key)` is called every frame or on-demand by game systems. The game never reads raw base values directly. All gameplay code queries EffectManager, which delegates to the internal EffectState.

**Resolution order matters.** Additive modifiers apply first, then multiplicative. This means a +50 add and a x2 multiply on a base of 500 gives (500 + 50) * 2 = 1100, not 500 * 2 + 50 = 1050.

### Prototype stat keys

EffectState is key-agnostic. Game systems register base values at startup. New keys can be added without touching EffectState. The prototype uses:

| Key | Base value | Unit |
|---|---|---|
| `paddle_speed` | 500.0 | px/s |
| `paddle_size` | 50.0 | px |
| `ball_speed_min` | 400.0 | px/s |
| `ball_speed_max` | 700.0 | px/s |
| `ball_speed_increment` | 15.0 | px/s |
| `friendship_points_per_hit` | 1.0 | FP |
| `ball_magnetism` | 0.0 | force |
| `return_angle_influence` | 0.0 | factor (0-1) |

All base values are defined in `GameRules.BASE_STATS` and registered by `EffectManager` on `_ready()`.

### Prototype named states

| State | Set by | Meaning |
|---|---|---|
| `frenzy` | The Stray | Multi-ball chaos mode, speed doubled, ends on miss |

---

## Delayed effects

Some conditions introduce a delay between trigger and outcome (e.g. `delay_random`).

```mermaid
stateDiagram-v2
    [*] --> Idle
    Idle --> Waiting: trigger fires, delay_random condition
    Waiting --> Executing: timer expires
    Waiting --> Idle: rally ends (miss) before timer
    Executing --> Idle: outcomes executed
```

`EffectManager` holds a list of `DelayedEffect` entries. Each tick, it decrements timers. If the invalidation event fires (e.g. miss) before the timer expires, the delayed effect is discarded.

---

## Item lifecycle

Standard items have a simple lifecycle. Degrading items (Seven Years) have an extended one.

### Standard item

```mermaid
stateDiagram-v2
    [*] --> Owned
    Owned --> Kit: equip
    Owned --> Locker: unequip / default
    Kit --> Locker: swap out
    Locker --> Kit: swap in
    Kit --> Destroyed: Tinkerer
    Locker --> Destroyed: Tinkerer
    Destroyed --> [*]

    state Kit {
        [*] --> Level1
        Level1 --> Level2: upgrade
        Level2 --> Level3: upgrade
    }
```

### Degrading item (Seven Years)

```mermaid
stateDiagram-v2
    [*] --> Whole

    state Whole {
        [*] --> Cracking
        Cracking --> Cracking: on_miss (increment degradation)
        Cracking --> Repaired: level up (reset cracks)
        Repaired --> Cracking: on_miss
    }

    Whole --> Broken: degradation reaches 100

    state Broken {
        [*] --> Cursed
        Cursed --> WorseCurse: Tinkerer "levels" it
    }

    Broken --> Destroyed: Tinkerer destroy
    Destroyed --> [*]

    note right of Broken: Cannot be repaired<br/>Level preserved from Whole state<br/>Curse scales with level
```

---

## Effect source registration

```mermaid
flowchart TD
    Equip[Player equips item to kit] --> Register[EffectManager.register_source]
    Unequip[Player moves item to locker] --> Unregister[EffectManager.unregister_source]
    Partner[Partner joins session] --> Register
    PartnerLeave[Partner leaves] --> Unregister

    Register --> Active[Effects evaluated on game events]
    Unregister --> Inactive[Effects no longer evaluated]
    Unregister --> Cleanup[EffectState.remove_modifiers_by_source]
```

Court items register on purchase and stay registered unless lockered or destroyed. Kit items register/unregister on swap.

---

## Signal emission

EffectManager emits signals after executing outcomes. Presentation layer subscribes to these, never to the raw game events.

```mermaid
flowchart LR
    EffectManager -->|game_state_entered| VFX
    EffectManager -->|ball_spawned| VFX
    EffectManager -->|ball_deflected| VFX
    EffectManager -->|item_buff_started| HUD
    EffectManager -->|item_buff_expired| HUD
    EffectManager -->|roll_result| HUD
    EffectManager -->|gravity_well_spawned| VFX
    EffectManager -->|gravity_well_intensified| VFX

    VFX[VFX / Audio]
    HUD[HUD / UI]
```

All signals include `item_key` so consumers can differentiate sources without knowing the effect system internals.

---

## Oscillation model

`oscillate_stat` is a continuous effect, not event-driven. EffectManager ticks it every frame.

```
value = base + amplitude * sin(time * frequency + phase_offset)
```

Frequency and phase offset are randomized per effect instance so oscillation feels unpredictable, not rhythmic. Amplitude scales with item level. The oscillation modifies the stat through EffectState like any other modifier, but the value updates every frame.

---

## Roll table resolution

`roll_table` picks one outcome from an equally weighted set and executes it. The roll is a single random selection, not sequential evaluation.

```mermaid
flowchart TD
    Trigger[Trigger fires + conditions pass] --> Roll[Random index 0..N-1]
    Roll --> O1[Outcome A]
    Roll --> O2[Outcome B]
    Roll --> O3[Outcome C]
    Roll --> ON[Outcome N]

    O1 --> Execute[Execute selected outcome normally]
    O2 --> Execute
    O3 --> Execute
    ON --> Execute
```

"Long Shot Pays" is a special outcome that re-executes all other positive outcomes in the table. Implementation: the outcome stores references to the other entries and calls `execute_outcomes` for each.

---

## Godot integration

| Class | Godot type | Location |
|---|---|---|
| `ItemManager` | Autoload (Node) | `res://scripts/items/item_manager.gd` |
| `EffectManager` | Autoload (Node) | `res://scripts/items/effect/effect_manager.gd` |
| `EffectState` | RefCounted (internal to EffectManager) | `res://scripts/items/effect/effect_state.gd` |
| `ItemDefinition` | Resource | `res://resources/items/*.tres` |
| `Effect` | Resource | `res://scripts/items/effect/effect.gd` |
| `Trigger` | Resource (sub-resource) | Inline in Effect resource |
| `Condition` | Resource (sub-resource) | Inline in Effect resource |
| `Outcome` | Resource (sub-resource) | Inline in Effect resource |
| `StatModifier` | RefCounted | Created at runtime by EffectManager |
| `GameRules` | RefCounted (static constants) | `res://scripts/core/game_rules.gd` |
| `Partner` | Resource (planned) | `res://data/partners/` |

Effects, items, and partners are `.tres` resource files. Authored in data, loaded at runtime. No per-item scripts.

---

## Notes

- `EffectManager` subscribes to game signals (`ball_missed`, `paddle_hit`, `streak_changed`, etc.) and translates them into `on_game_event` calls with the matching TriggerType.
- `always` trigger effects are evaluated once on registration and re-evaluated when the source changes (level up, degradation change).
- Court items call `register_source` on purchase automatically. Kit items call it on equip.
- `EffectManager.get_stat()` is the single source of truth for all gameplay values. Game systems must never hardcode stats.
- Degradation is a stat in EffectState, keyed per item (e.g. `degradation:seven_years`). The `increment_degradation` outcome is `modify_stat` on this key. The `degradation_at` and `degradation_below` conditions check it via `get_stat`.
- Partner effects use the same Effect resources. The only difference is the source: `Partner` provides `relationship_level` as the level parameter to `get_effects_for_level()`.
