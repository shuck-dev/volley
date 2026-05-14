# Save Versioning

Implementation spec for Volley's save model and the schema-migration plan that activates at v1. Persisted progression data is the only on-disk state; everything else is reconstructed from scenes and resources at runtime.

## Goals

- Every game system owns its own save shape. The save file is a flat dict of per-system slices.
- Adding a field never touches another system or a central registry.
- Schema breaks (rename, type change, cross-slice move) are visible in review and replayed on load without each system knowing the history.
- Open-source contributors and players running diverse versions can load any older save on any newer build without ceremony.

## Architecture

### Decentralised slices

Each game system that persists state exposes two methods:

```gdscript
func to_save_dict() -> Dictionary
func apply_save_dict(slice: Dictionary) -> void
```

`SaveManager` is a dumb coordinator. On save: walk the registered systems, collect each slice, build the top-level dict, stamp `schema_version`, JSON-stringify, write. On load: read, JSON-parse, run the migration chain, split into slices, hand each system its slice.

Systems do not know about each other on save or load. Each slice contains its own primitives and ID references; nothing in the save format references an object pointer that needs resolving.

### Save file shape

```json
{
    "schema_version": 3,
    "economy": { "fp_balance": 240, "total_earned": 1820 },
    "items": {
        "item_levels": { "training_ball": 2 },
        "item_placements": { "training_ball": 1 },
        "rack_slot_index_by_key": { "training_ball": 0 }
    },
    "partners": { "active": "martha", "unlocked": ["martha"] },
    "records": { "personal_volley_best": 17 },
    "venue": { "loose": [] }
}
```

Top-level keys are system names. Each value is that system's slice. `schema_version` is the only field outside a system slice.

### Load-order independence

Cross-references between slices are all ID-typed (`String` item keys, `StringName` partner names). No system needs another system's runtime objects in order to deserialize its own slice. Slices can be dispatched in any order; resolution happens at runtime the first time the data is asked for, not at load.

## Versioning

### When versioning activates

Prototype-phase Volley (today) carries no migrations, no compatibility shims, **and no `schema_version` field**. Schema changes wipe dev saves and the team accepts that. Once a version stamp lands on saves in the field, that version is an immutable contract; any subsequent schema change without a migration produces inconsistent v=N files with different shapes. The hedge of "stamp early just in case" defeats itself.

The migration infrastructure and the `schema_version` field both activate together at v1, with the first wave of stamped saves carrying `schema_version = 1`. Until then, the save is a plain nested dict-of-slices that breaks freely on schema change.

### The migration chain

`SaveManager` owns a `MIGRATIONS` map keyed by source version:

```gdscript
const SCHEMA_VERSION := 3

const MIGRATIONS := {
    1: _v1_to_v2,
    2: _v2_to_v3,
}

func _migrate(data: Dictionary) -> Dictionary:
    var v: int = data.get("schema_version", 0)
    while v < SCHEMA_VERSION:
        data = MIGRATIONS[v].call(data)
        v += 1
    data["schema_version"] = SCHEMA_VERSION
    return data
```

Each migration is a pure `Dictionary -> Dictionary` transform. Migrations chain one version at a time, so each function only needs to know about adjacent versions, never the whole history.

After `_migrate` returns, every system's `apply_save_dict` receives a slice in the **current** shape. No system ever sees a legacy shape.

### Sample migrations

```gdscript
# v1 -> v2: rename friendship_point_balance to fp_balance inside the economy slice.
static func _v1_to_v2(data: Dictionary) -> Dictionary:
    var economy: Dictionary = data.get("economy", {})
    if "friendship_point_balance" in economy:
        economy["fp_balance"] = economy["friendship_point_balance"]
        economy.erase("friendship_point_balance")
    data["economy"] = economy
    return data

# v2 -> v3: move loose_in_venue from items slice to new venue slice.
static func _v2_to_v3(data: Dictionary) -> Dictionary:
    var items: Dictionary = data.get("items", {})
    var venue: Dictionary = data.get("venue", {})
    if "loose_in_venue" in items:
        venue["loose"] = items["loose_in_venue"]
        items.erase("loose_in_venue")
    data["items"] = items
    data["venue"] = venue
    return data
```

### Properties that matter

- **Chained one at a time.** A player on v1 launching a v3 build runs `v1 -> v2 -> v3`. Skipping versions is forbidden.
- **Pure dict transforms.** No system code, no runtime side effects. Migrations are trivial to unit-test: feed a v1 dict, assert the v2 output.
- **Stamped on save.** Every save written by the current build carries `SCHEMA_VERSION`. A newer build reading an older save migrates; an older build reading a newer save refuses (a player-facing "this save is from a newer version of the game" prompt).
- **Migrations live forever in source.** A player can skip 12 updates and return; the chain runs from their saved version forward. Eventually a deliberate decision can declare a floor ("saves older than v5 must be opened with build 1.5 first") and drop older migrations, but that is opt-in, not routine cleanup.

### Immutability discipline

A migration that has shipped to players is frozen. If `_v2_to_v3` is wrong and the wrong shape is in the field, the fix is `_v3_to_v4` that compensates. Editing the original would leave players whose saves are already v3 with no migration path to the corrected shape.

This implies: review each migration carefully before shipping. A migration release notes line gives the next reviewer the chance to catch a logic error before it goes out.

## Adding a field

The common case stays trivial. A new field on an existing slice does not need a migration.

1. Add the field to the system's state (one var declaration).
2. Add the field to the system's `to_save_dict` (one line).
3. Add the field to the system's `apply_save_dict` with `data.get(key, default)` (one line).

`SCHEMA_VERSION` does not bump. Old saves load with the default value for the new field.

## Schema-breaking changes

Any change that is not additive triggers a `SCHEMA_VERSION` bump and a new migration:

- Renaming an existing field
- Changing a field's type in a way that JSON cannot coerce
- Moving a field from one slice to another
- Splitting one field into two, or merging two into one
- Removing a field that other code still expects to find (rare; the system can just stop reading and writing it)

The PR that introduces the break adds the migration in the same commit. CI verifies the migration runs on a fixture v(N-1) save.

## Validation

Optional but recommended: bolt a JSON Schema validator (`fimbul-works/GDSchema` or asset #3295) onto the post-migration step. Each system declares its slice schema; SaveManager validates the full migrated dict before dispatching. A schema drift between migration output and live system shape becomes a load-time error rather than a silent default-on-everything.

This is a tripwire, not a load gate. If validation fails, log loudly, fall back to default-initialise the offending slice, continue. The player keeps their other slices intact.

## What this does not do

- No backward compatibility. A v3 save will not load on a v2 build. Migrations are one-way.
- No partial-save atomicity. The whole save file is one JSON write; a crash mid-write leaves the previous save intact (atomic-via-rename) or, in the worst case, a corrupt file the next load detects and rejects.
- No cross-save merging. Multi-device cloud sync is out of scope for v1.

## References

- [Godot saving games tutorial](https://docs.godotengine.org/en/stable/tutorials/io/saving_games.html): official recommendation to "store a version number and write your own compatibility code", which Volley implements per this doc.
- [godot-proposals #7567](https://github.com/godotengine/godot-proposals/discussions/7567): discussion of first-class versioned Resources; not merged.
