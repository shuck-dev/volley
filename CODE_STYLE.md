# Code Style

Welcome. This is the short list of GDScript conventions we follow in Volley!. `gdformat` and `gdlint` handle most of the mechanical stuff for you; this file is for the project-specific calls those tools cannot make.

None of this is meant to slow you down. The patterns here exist because they have repeatedly made the code easier to read, easier to refactor, and easier to onboard new contributors onto. If one does not fit your situation, open the PR and we will work it out.

## Blank line before every `if`

Leave a blank line above an `if` statement. It gives the predicate room to breathe and keeps dense bodies readable.

```gdscript
var remaining := target - current

if remaining <= step:
    return
```

rather than:

```gdscript
var remaining := target - current
if remaining <= step:
    return
```

## `@export` over `@onready` for child nodes

Wire child node references through `@export var name: NodeType` (or `@export var name: NodePath`) rather than `@onready var name = $Path`. Exports survive scene renames, fail loudly when the wire breaks, and show the dependency in the inspector, all of which save time the next time someone reorganises a scene.

```gdscript
@export var hit_sound: AudioStreamPlayer
@export var collision: CollisionShape2D
```

`@onready` still has its place: things the script genuinely owns, like a Timer it creates, or a value computed once at ready time.

## Full words

In file names, variable names, function names, and comments, write the word out. `paddle_velocity` reads better than `pdl_vel`; `current_state` reads better than `cur_st`. The few extra letters are easier to write than the guesswork is to read.

A handful of project-wide abbreviations have stuck (`id`, `url`, `ui`, `ms`) and are fine. If you are about to invent a new one, spell it out instead.

## Descriptive variable names

Name variables for what they represent in the system. `spawned_ball`, `elapsed_seconds`, `remaining_descent` will tell a reader what they are looking at; `b`, `t`, `n` will not.

Loop counters in a five-line block where the iteration variable is obvious (`for i in range(...)`) are fine as is. Longer or nested loops earn a real name.

## Comments: one line, WHY only

If a comment is needed at all, it is one line and it explains *why* the code looks the way it does. The reader can already see *what* it does from the code itself. Multi-line block comments and narrative explanations are wonderful in design docs; in code they tend to rot.

```gdscript
# Read placement state directly so a mid-drag overlay does not skew capacity.
var equipped_count := _count_equipped_from_state()
```

rather than:

```gdscript
# This function counts equipped items by iterating the item_placements
# dictionary and checking each placement against the EQUIPPED enum value.
# It returns the count as an integer.
var equipped_count := _count_equipped_from_state()
```

A quick test: if removing the comment would not confuse a future reader, you do not need it.

## Tunables live in data

Numbers, thresholds, durations, speeds. If a value might want tuning without a code edit, promote it to an `@export var`. When three or more related tunables move together (a movement profile: acceleration, top speed, decel, for instance), cluster them into a `Resource` subclass with its own `.tres` file so they can be edited from the inspector, shared across instances, and saved separately.

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

The script holds the defaults; the `.tres` holds whatever values are in play. Designers and contributors can tune values without touching the source.

## `Resource` subclass when a cluster forms

You will notice when you are reaching for the third related `@export` on a node that the values clearly belong together: a movement profile, a visual style block, an item definition. That is the moment to promote them to a `Resource` subclass and store the values in a `.tres`. Loose exports work for one or two values; once a cluster forms, they tend to scatter what should travel together.

A useful diagnostic: count the degrees of freedom. If most of the resource's fields are exercised by the live use cases, it earns its `Resource`. If only one or two ever vary, the cluster is premature, and keeping them as loose exports is the kinder call.
