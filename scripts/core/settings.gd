extends Node

const _CONFIG_PATH := "user://settings.cfg"
const _SECTION_DISPLAY := "display"
const _SECTION_AUDIO := "audio"

var _config: ConfigFile
var _defaults: Resource

var _config_path: String = _CONFIG_PATH


func _init(config_path: String = _CONFIG_PATH) -> void:
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
	for key: String in ["master_volume", "music_volume", "sfx_volume"]:
		_apply_audio_key(key, _config.get_value(_SECTION_AUDIO, key, _audio_default(key)))


func _apply_display() -> void:
	for key: String in ["window_mode", "vsync", "fps_cap", "resolution"]:
		_apply_display_key(key, _config.get_value(_SECTION_DISPLAY, key, _display_default(key)))


func _audio_default(key: String) -> Variant:
	match key:
		"master_volume":
			return _defaults.default_master_volume
		"music_volume":
			return _defaults.default_music_volume
		"sfx_volume":
			return _defaults.default_sfx_volume
	return null


func _display_default(key: String) -> Variant:
	match key:
		"window_mode":
			return _defaults.default_window_mode
		"vsync":
			return _defaults.default_vsync
		"fps_cap":
			return _defaults.default_fps_cap
		"resolution":
			return _defaults.default_resolution
	return null


func _apply(section: String, key: String, value: Variant) -> void:
	match section:
		_SECTION_AUDIO:
			_apply_audio_key(key, value)
		_SECTION_DISPLAY:
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
