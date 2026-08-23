# Godot known issues

Engine bugs we have hit, what they break, and the shape of code that works around them. Each entry
exists because the workaround looks like dead weight from the call site: someone reading the code
sees an indirection with no visible purpose and deletes it. The point of this page is that the
reason lives somewhere findable.

The unifying hazard is that two of the three break **only in an exported build**. The editor runs
fine, gdlint passes, GUT passes, CI goes green, and the failure appears when the game is packaged.
Passing tests are not evidence about these.

## Autoloads cannot parse a Resource's global class

[godotengine/godot#75582](https://github.com/godotengine/godot/issues/75582), open.

An autoload script that references a `class_name` belonging to a Resource script fails to parse in
exported builds with `Parse Error: Could not parse global class`. It is a load-order race between
resource preloading and autoload initialisation, so the editor never shows it.

The trigger needs all three: an autoload, a reference to a `class_name`, and that class extending
`Resource`. An autoload naming a `Node` subclass is fine, and a non-autoload naming a Resource
class is fine.

The workaround is to bind the class through an explicit path instead of the global registry:

```gdscript
# preload workaround for autoload class_name ordering (godotengine/godot#75582)
@warning_ignore("shadowed_global_identifier")
const PartnerDefinition = preload("res://scripts/partners/partner_definition.gd")
```

The `const` deliberately shadows the global name, which is what the `@warning_ignore` acknowledges.
Every use of `PartnerDefinition` in the file then resolves through the const. It lives in
`scripts/progression/progression_manager.gd` and, because it sits in the same parse-time reach,
`scripts/court/recruit_panel.gd`.

Deleting either line leaves a project that builds, lints, and tests clean, then fails to boot when
exported.

## Preload initialisers can cycle in the web export

No upstream issue filed; observed in this project.

A `var` initialised with `preload()` at parse time can form a dependency cycle the web export will
not tolerate, where desktop exports and the editor resolve it. Populating the same array in
`_ready` with `load()` moves the resolution to runtime and breaks the cycle.

```gdscript
## Populated in _ready via load() rather than a preload initializer, avoiding a parse-time cycle the web export can't tolerate.
var items: Array[BallDefinition] = []
```

Both `scripts/items/ball_manager.gd` and `scripts/progression/progression_manager.gd` populate their
definition arrays this way. The paths sit in a `const` array above each declaration; only the
loading is deferred.

## `--check-only` reports false compilation failures

[godotengine/godot#111515](https://github.com/godotengine/godot/issues/111515), open.

`godot --headless --check-only --script <file>` reports `Compilation failed` for any script naming
an autoload singleton or a global `class_name`, because the isolated check loads no autoloads.
`--debug` crashes outright. The script is fine.

Validate in project context instead: a GUT run loads every script with autoloads up. When an
isolated check disagrees with a green suite, trust the suite. This is also recorded in
[TESTING.md](../../tests/TESTING.md) where it affects how the suite is run.

## Adding an entry

Worth a section when an engine defect forces code that reads as pointless, and doubly so when the
failure is invisible outside an export. Give it the issue link if one exists, the exact trigger
conditions, the workaround as it appears in the codebase, and the file paths carrying it. Keep the
inline comment at the call site too: this page is where the reasoning lives, but the comment is what
stops the deletion.
