# Settings screen spike

Decision record for how Volley's settings screen enumerates, applies, and persists options.
Closes the spike (#906). Implementation is follow-up work, not part of this spike.

## Decision

A `Settings` autoload owns a separate `user://settings.cfg` (ConfigFile), loads and applies it at
`_enter_tree`, and exposes a setter that applies-then-saves. The screen is a TabContainer with Display
and Audio tabs. Settings are independent of the gameplay save system, so a save wipe leaves them intact.

## Options the screen holds

| Tab | Option | Notes |
|---|---|---|
| Display | Window mode | Windowed / Borderless Fullscreen / Exclusive Fullscreen |
| Display | Resolution | Windowed only. Hardcoded 16:9 list filtered to `<= DisplayServer.screen_get_size()` |
| Display | VSync | **On / Off only** (see renderer note) |
| Audio | Master / Music / SFX volume | Sliders, linear 0.0 to 1.0 |

## Display: enumerate and apply

Godot 4 has **no video-mode enumeration API**. `DisplayServer` exposes `screen_get_size()` and
`screen_get_refresh_rate()` (guard the latter, it returns `-1.0` on some platforms) but no list of
supported modes. So resolution is a hardcoded 16:9 list (1280x720, 1600x900, 1920x1080, 2560x1440,
3840x2160) filtered at startup to those fitting the detected screen.

Apply is three calls: `window_set_mode`, `window_set_size` (windowed only; a no-op in fullscreen),
`window_set_vsync_mode`.

The `canvas_items` stretch (1080p base, per #907) scales transparently when the window resizes; the 4K
path is exclusive fullscreen scaling the 1080p canvas up. No extra code. One catch: set
`content_scale_aspect = KEEP` on the root Window or a freely-resized window stretches content.

**Renderer note (decided against the live project):** Volley renders with `gl_compatibility`. Under the
Compatibility renderer, `VSYNC_ADAPTIVE` and `VSYNC_MAILBOX` silently fall back to `VSYNC_ENABLED`, so
exposing them would show the user a no-op. VSync is On/Off only unless the renderer changes.

## Audio: bus setup required first

Volley runs on the engine's implicit Master bus alone. The audio options need two more, created in the
editor Audio panel: `Music` and `SFX`, both sending to Master, with stream players routed by name. The
editor then writes `default_bus_layout.tres`.

Volume is the one thing every project gets wrong: **persist the linear slider value (0.0 to 1.0); apply
`linear_to_db()` only at the `AudioServer.set_bus_volume_db` call site; never store dB.** A mute toggle
uses `set_bus_mute`, not volume to `-inf`.

## Persistence lifecycle

`Settings` autoload (registered above the autoloads that consume settings, so its `_enter_tree` applies
first):

1. `_enter_tree`: `config.load("user://settings.cfg")`. A first-run miss returns a non-OK error, not a
   crash; ignore it and fall through to defaults via the third arg of `get_value(section, key, default)`.
2. Apply every value (AudioServer volumes, window mode/size/vsync).
3. Public `set(section, key, value)`: writes to memory, applies that domain, then `config.save(...)`.
4. Audio sliders apply immediately (real-time feedback); `save()` fires on confirmed close and again in
   `_exit_tree` as a safety net, not on every slider tick.
5. A reset-to-defaults button per tab writes each key's hardcoded default and saves.

## Follow-up (separate tickets, not this spike)

The `Settings` autoload, the `settings.tscn` TabContainer screen, the `Music`/`SFX` bus layout plus
player rerouting, and wiring the screen into the menu. Each AC above is an implementation surface.

## Citations
Godot 4 docs:
- DisplayServer (no mode-enumeration API; `screen_get_size`/`screen_get_refresh_rate`; window mode/size/vsync): https://github.com/godotengine/godot-docs/blob/master/classes/class_displayserver.md
- Window (`content_scale_aspect`): https://github.com/godotengine/godot-docs/blob/master/classes/class_window.md
- Viewports (`canvas_items` stretch scaling): https://github.com/godotengine/godot-docs/blob/master/tutorials/rendering/viewports.md
- ConfigFile (`load`/`get_value` default/`set_value`/`save`): https://github.com/godotengine/godot-docs/blob/master/classes/class_configfile.md
- AudioServer (`set_bus_volume_db`/`set_bus_mute`): https://github.com/godotengine/godot-docs/blob/master/classes/class_audioserver.md
- Audio buses (bus layout, `default_bus_layout.tres`): https://github.com/godotengine/godot-docs/blob/master/tutorials/audio/audio_buses.md
- `linear_to_db` (@GlobalScope): https://github.com/godotengine/godot-docs/blob/master/classes/class_@globalscope.md
- Singletons / Autoload (load order, `_enter_tree`): https://github.com/godotengine/godot-docs/blob/master/tutorials/scripting/singletons_autoload.md
