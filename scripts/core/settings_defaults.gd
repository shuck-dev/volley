class_name SettingsDefaults
extends Resource

## Default window mode index into DisplayServer.WindowMode (0=windowed, 1=minimized, 2=maximized, 3=fullscreen, 4=exclusive_fullscreen).
@export var default_window_mode: int = 0

## Default VSync enabled (true = on, false = off). Compatibility renderer only supports on/off.
@export var default_vsync: bool = true

## Default FPS cap; 0 means uncapped.
@export var default_fps_cap: int = 0

## Ordered list of available FPS cap choices (0 = uncapped).
@export var fps_cap_options: Array[int] = [0, 30, 60, 120, 144, 165, 240]

## Hardcoded 16:9 resolutions filtered at runtime against screen size.
@export var resolution_list: Array[Vector2i] = [
	Vector2i(1280, 720),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440),
	Vector2i(3840, 2160),
]

## Default linear volume for Master bus (0.0 to 1.0).
@export_range(0.0, 1.0) var default_master_volume: float = 1.0

## Default linear volume for Music bus (0.0 to 1.0).
@export_range(0.0, 1.0) var default_music_volume: float = 1.0

## Default linear volume for SFX bus (0.0 to 1.0).
@export_range(0.0, 1.0) var default_sfx_volume: float = 1.0
