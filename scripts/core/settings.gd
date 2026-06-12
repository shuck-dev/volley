extends Node

const _CFG_PATH := "user://settings.cfg"
const _SEC_DISPLAY := "display"
const _SEC_AUDIO := "audio"

var _config: ConfigFile
var _defaults: Resource

var _config_path: String = _CFG_PATH


func _init(config_path: String = _CFG_PATH) -> void:
	_config_path = config_path
	_config = ConfigFile.new()
	_defaults = load("res://scripts/core/settings_defaults.gd").new()


func _enter_tree() -> void:
	_config.load(_config_path)
	_apply_all()


func _exit_tree() -> void:
	_config.save(_config_path)


func set_value(section: String, key: String, value: Variant) -> void:
	if _config.has_section_key(section, key):
		var current: Variant = _config.get_value(section, key)

		if current == value:
			return

	_config.set_value(section, key, value)
	_apply(section, key, value)
	_config.save(_config_path)


func get_value(section: String, key: String, default: Variant = null) -> Variant:
	return _config.get_value(section, key, default)


func _apply_all() -> void:
	_apply_audio()
	_apply_display()


func _apply_audio() -> void:
	var master: float = _config.get_value(
		_SEC_AUDIO, "master_volume", _defaults.default_master_volume
	)
	var music: float = _config.get_value(_SEC_AUDIO, "music_volume", _defaults.default_music_volume)
	var sfx: float = _config.get_value(_SEC_AUDIO, "sfx_volume", _defaults.default_sfx_volume)

	_set_bus_volume("Master", master)
	_set_bus_volume("Music", music)
	_set_bus_volume("SFX", sfx)


func _apply_display() -> void:
	var mode: int = _config.get_value(_SEC_DISPLAY, "window_mode", _defaults.default_window_mode)
	var vsync: bool = _config.get_value(_SEC_DISPLAY, "vsync", _defaults.default_vsync)
	var fps_cap: int = _config.get_value(_SEC_DISPLAY, "fps_cap", _defaults.default_fps_cap)
	var size: Vector2i = _config.get_value(_SEC_DISPLAY, "resolution", Vector2i(1920, 1080))

	DisplayServer.window_set_mode(mode as DisplayServer.WindowMode)
	DisplayServer.window_set_vsync_mode(
		DisplayServer.VSYNC_ENABLED if vsync else DisplayServer.VSYNC_DISABLED
	)

	if mode == DisplayServer.WINDOW_MODE_WINDOWED:
		DisplayServer.window_set_size(size)

	Engine.max_fps = fps_cap


func _apply(section: String, key: String, value: Variant) -> void:
	match section:
		_SEC_AUDIO:
			_apply_audio_key(key, value)
		_SEC_DISPLAY:
			_apply_display_key(key, value)


func _apply_audio_key(key: String, value: Variant) -> void:
	match key:
		"master_volume":
			_set_bus_volume("Master", value)
		"music_volume":
			_set_bus_volume("Music", value)
		"sfx_volume":
			_set_bus_volume("SFX", value)


func _apply_display_key(key: String, value: Variant) -> void:
	match key:
		"window_mode":
			DisplayServer.window_set_mode(value as DisplayServer.WindowMode)
		"vsync":
			DisplayServer.window_set_vsync_mode(
				DisplayServer.VSYNC_ENABLED if value else DisplayServer.VSYNC_DISABLED
			)
		"fps_cap":
			Engine.max_fps = value
		"resolution":
			if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_WINDOWED:
				DisplayServer.window_set_size(value)


func _set_bus_volume(bus_name: String, linear: float) -> void:
	var index: int = AudioServer.get_bus_index(bus_name)

	if index == -1:
		return

	AudioServer.set_bus_volume_db(index, linear_to_db(linear))


func get_available_resolutions() -> Array[Vector2i]:
	var screen: Vector2i = DisplayServer.screen_get_size()
	var result: Array[Vector2i] = []

	for res: Vector2i in _defaults.resolution_list:
		if res.x <= screen.x and res.y <= screen.y:
			result.append(res)

	return result
