# Resource Hot Reload

A two-part Godot 4 addon for live-tuning `Resource` exports during development. Edit a `.tres` in the inspector, see the change in the running game within milliseconds, no scene restart.

## What it does

- **Editor plugin**: auto-saves any disk-backed `Resource` the moment you commit a property edit in the inspector (no more hunting for a save button).
- **Runtime autoload**: polls the files that nodes in the `hot_reloadable_config` group depend on, detects mtime changes, loads fresh copies via `CACHE_MODE_REPLACE`, reassigns the property, and calls `on_config_reloaded()` on the owning node so it can re-apply visuals.

## Installation

1. Copy `addons/config_hot_reload/` into your project's `addons/` folder.
2. In `Project → Project Settings → Plugins`, enable **Resource Hot Reload**.
3. In `Project → Project Settings → AutoLoad`, add `res://addons/config_hot_reload/config_hot_reload.gd` as a singleton named `ConfigHotReload`.

## Usage

Mark the node that holds the Resource exports as hot-reloadable:

**Option A — editor** (zero code): in the scene dock, select the node, open the **Node** tab, **Groups** section, add the group `hot_reloadable_config`. You can also predeclare it as a global group in `Project Settings → Global Groups` for autocomplete.

**Option B — script**:

```gdscript
func _init() -> void:
    add_to_group(&"hot_reloadable_config")
```

Both work the same at runtime.

Then, optionally, implement a callback for when the resource reloads:

```gdscript
@export var config: MyConfigResource

func on_config_reloaded() -> void:
    ## Re-apply anything that depends on config values
    _rebuild_visuals()
    _reposition_children()
```

The autoload always re-assigns the property itself; `on_config_reloaded()` is only for the cascading refresh logic on your side.

## How it works

```
┌─────────────────────┐      ┌────────────────────┐      ┌──────────────────┐
│  Editor process     │      │  Filesystem        │      │  Game process    │
│                     │      │                    │      │                  │
│  Inspector edit ───►│ plugin.gd saves via       │      │                  │
│                     │ ResourceSaver             │      │                  │
│                     │   ────► .tres             │      │                  │
│                     │         updated mtime ────────►  │ config_hot_reload│
│                     │                           │      │ polls mtime      │
│                     │                           │      │   │              │
│                     │                           │      │   ▼              │
│                     │                           │      │ Reload via       │
│                     │                           │      │ CACHE_MODE_REPLACE│
│                     │                           │      │   │              │
│                     │                           │      │   ▼              │
│                     │                           │      │ Re-assign prop + │
│                     │                           │      │ on_config_reloaded│
└─────────────────────┘      └────────────────────┘      └──────────────────┘
```

The editor half and the game half run in different processes and communicate via the filesystem (file mtimes + resource reload). No IPC, no remote-debugger hooks.

## Configuration

Current constants live in `config_hot_reload.gd`:

- `POLL_INTERVAL = 0.25` — how often (seconds) to check watched files
- `GROUP_NAME = "hot_reloadable_config"` — the opt-in group

Tweak these directly if you need a different cadence or group naming.

## Limitations

- **Debug builds only.** Both halves gate on `OS.is_debug_build()`, so there's zero runtime overhead in release exports.
- **Top-level resource only.** If your Resource references another Resource (nested), edits to the nested one aren't detected — only the top-level file's mtime is watched.
- **Text field edits commit on focus loss.** Godot's inspector emits `property_edited` (and calls `Resource.set()`) only when a numeric/text field is committed — pressing Enter, Tab, or clicking elsewhere. Slider drags commit live.
- **The running game needs to be visible** for you to see the change, not just focused. Hide the game behind the editor and you won't see it update until you look at it.
- **No nested resource autosave.** The auto-save plugin only saves the top-level edited Resource. Sub-resources edited inside a parent's inspector share the parent's file, so they get saved together.

## License

Public domain / do whatever you want with it.
