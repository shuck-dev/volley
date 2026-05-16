# Code Style

GDScript conventions used in Volley!. The lint pipeline (`gdformat`, `gdlint`) catches most of the mechanical stuff; this file covers the project-specific decisions that lint does not enforce.

## Blank line before every `if`

Always leave a blank line above an `if` statement. It separates the predicate from whatever set it up, and keeps the control flow readable in dense bodies.

```gdscript
var remaining := target - current

if remaining <= step:
    return
```

Not:

```gdscript
var remaining := target - current
if remaining <= step:
    return
```

## `@export` over `@onready` for child node references

Wire child node references through `@export var name: NodeType` (or `@export var name: NodePath`) instead of `@onready var name = $Path`. Exports survive scene renames, fail loud when the wire breaks, and document the dependency in the inspector.

```gdscript
@export var hit_sound: AudioStreamPlayer
@export var collision: CollisionShape2D
```

Reserve `@onready` for things genuinely owned by the script (a Timer the script creates, a value computed at ready time).

## Full words; no abbreviations

In file names, variable names, function names, and comments, write the word out. `paddle_velocity` over `pdl_vel`. `current_state` over `cur_st`. The reader does not gain anything from a guess; the writer does not lose anything by typing the extra letters.

Exceptions are unambiguous, project-wide abbreviations that have stuck: `id`, `url`, `ui`, `ms`. If you are about to invent a new one, write the word out instead.

## Descriptive variable names; no single letters

Single-letter names (`b`, `t`, `n`) and one-word reductions (`tmp`, `val`) hide intent. Name the thing for what it represents in the system: `spawned_ball`, `elapsed_seconds`, `remaining_descent`.

Loop counters in a five-line block where the iteration variable is obvious (`for i in range(...)`) are fine; longer or nested loops earn a real name.

## Comments: one line, WHY only

If a comment is needed at all, it is one line and it says *why* the code looks the way it does. The reader can already see *what* it does from the code. Multi-line block comments and narrative explanations belong in design docs, not in code.

```gdscript
# Read placement state directly so a mid-drag overlay does not skew capacity.
var equipped_count := _count_equipped_from_state()
```

Not:

```gdscript
# This function counts equipped items by iterating the item_placements
# dictionary and checking each placement against the EQUIPPED enum value.
# It returns the count as an integer.
var equipped_count := _count_equipped_from_state()
```

If removing the comment would not confuse a future reader, do not write it.

## Tunables live in data, not code

Numbers, thresholds, durations, speeds. If a value might want tuning without a code edit, promote it to `@export var`. If three or more related tunables move together (e.g. a movement profile: acceleration, top speed, decel), cluster them into a `Resource` subclass with its own `.tres` file.

```gdscript
@export var walk_speed: float = 200.0
```

For clusters:

```gdscript
class_name TimeoutConfig
extends Resource

@export var descent_speed: float = 1200.0
@export var walk_duration_seconds: float = 0.6
@export var equip_pose_offset_x: float = -192.0
```

The script holds defaults; the `.tres` overrides for live tuning. Designers and contributors can author values without editing source.

## `Resource` subclass over loose `@export` vars when clustered

When you find yourself adding the third `@export` to a node and the values clearly belong together (a movement profile, a visual style block, an item definition), promote to a `Resource` subclass and store the values in a `.tres`. Loose exports scale poorly: they bind the data to the node, they cannot be shared across instances, and they bury the cluster in the inspector.

The diagnostic: count the degrees of freedom. If most of the resource's fields are exercised by the live use cases, it earns its `Resource`. If only one or two fields ever vary, the cluster is premature; keep them as loose exports.
