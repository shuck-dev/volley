# Effect System

All gameplay modifiers in Volley flow through one system. Items, partners, and any future sources share the same data shape: a trigger, optional conditions, and one or more outcomes. Adding a new item means adding data; the evaluation loop is in one place.

## Architecture

```mermaid
classDiagram
    class ItemDefinition {
        +key: String
        +role: StringName
        +display_name: String
        +descriptions: String[]
        +base_cost: int
        +cost_scaling: float
        +max_level: int
        +effects: Effect[]
        +get_effects_for_level(level: int) Effect[]
        +get_key() String
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
        +level_scaling: float
    }

    class ItemManager {
        +items: ItemDefinition[]
        +get_level(item_key: String) int
        +calculate_cost(item_key: String) int
        +can_purchase(item_key: String) bool
        +purchase(item_key: String) bool
        +process_event(event_type: StringName) Array[StringName]
        +get_friendship_point_balance() int
        +add_friendship_points(points: int)
    }

    class EffectManager {
        +get_stat(key: StringName) float
        +get_base_stat(key: StringName) float
        +get_percentage_offset(key: StringName) float
        +register_source(source: Resource, level: int)
        +unregister_source(source: Resource)
        +process_event(event_type: StringName) Array[StringName]
        +process_frame(delta: float)
    }

    class EffectState {
        <<internal>>
        -base_values: Dictionary
        -add_modifiers: Array[StatModifier]
        -percentage_modifiers: Array[StatModifier]
        -multiply_modifiers: Array[StatModifier]
        +get_stat(key: StringName) float
        +get_base_stat(key: StringName) float
        +add_modifier(modifier: StatModifier)
        +remove_modifiers_by_source(source_key: String)
        +clear_temporary_modifiers()
    }

    class StatModifier {
        <<internal>>
        +source_key: String
        +stat_key: StringName
        +operation: Operation
        +value: float
        +range_stat_key: StringName
        +temporary: bool
    }

    ItemManager "1" --> "1" EffectManager
    ItemManager "1" --> "0..*" ItemDefinition
    ItemDefinition "1" --> "1..*" Effect
    Effect "1" --> "1" Trigger
    Effect "1" --> "0..*" Condition
    Effect "1" --> "1..*" Outcome
    EffectManager "1" --> "1" EffectState
    EffectState "1" --> "0..*" StatModifier
```

## Effect anatomy

Every effect is a `trigger + conditions + outcomes` rule authored as a Godot Resource. No per-item scripts.

```mermaid
flowchart LR
    T[Trigger\nwhen to fire] --> E{Conditions\ngate pass?}
    E -- yes --> O[Outcomes\nwhat happens]
    E -- no --> Skip[skip]
```

The trigger names when evaluation runs. Conditions filter whether the outcomes execute. Outcomes apply the change: a stat modifier, a game action, or an oscillation.

## Source registration

```mermaid
flowchart TD
    Activate[Player activates item] --> Register[EffectManager.register_source]
    Deactivate[Player deactivates item] --> Unregister[EffectManager.unregister_source]
    Partner[Partner joins session] --> Register
    PartnerLeave[Partner leaves] --> Unregister

    Register --> Active[Effects evaluated on game events]
    Unregister --> Inactive[Effects no longer evaluated]
    Unregister --> Cleanup[EffectState.remove_modifiers_by_source]
```

Every source follows the same path: register on activate, unregister on deactivate. No type-specific branching.

## Level scaling

Each outcome has a `level_scaling` property (default 1.0) that controls value growth across item levels.

```
effective_value = base_value * (1.0 + level_scaling * (level - 1))
```

Level 1 always applies the base value. Examples: `1.0` gives linear growth (×1, ×2, ×3); `0.5` gives half growth (×1, ×1.5, ×2); `0.0` gives the same value at every level.

## Godot integration

| Class | Godot type | Path |
|---|---|---|
| `ItemManager` | Autoload (Node) | `res://scripts/items/item_manager.gd` |
| `EffectManager` | Node (owned by ItemManager) | `res://scripts/items/effect/effect_manager.gd` |
| `EffectState` | RefCounted (internal) | `res://scripts/items/effect/effect_state.gd` |
| `Effect` | Resource | `res://scripts/items/effect/effect.gd` |
| `Trigger` | Resource (sub-resource) | `res://scripts/items/effect/trigger.gd` |
| `Condition` | Resource (sub-resource) | `res://scripts/items/effect/condition.gd` |
| `Outcome` | Resource (sub-resource, base class) | `res://scripts/items/effect/outcome.gd` |
| `StatModifier` | RefCounted (runtime) | `res://scripts/items/effect/stat_modifier.gd` |

Items and their effects are `.tres` resource files. Authored in data, loaded at runtime.

## Further reading

- [reference.md](reference.md): trigger, outcome, and condition types; stat key register; which are live and which are prototype ideas
- [runtime.md](runtime.md): event-to-outcome flow, stat resolution order, oscillation model, delayed effects
