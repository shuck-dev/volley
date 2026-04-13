class_name UIScaleConfig
extends RefCounted

const SAVE_PATH: String = "user://ui_scale.cfg"
const MIN_SCALE: float = 0.5
const MAX_SCALE: float = 2.0
const STEP: float = 0.25
const DEFAULT_SCALE: float = 1.0

var _config := ConfigFile.new()


func _init() -> void:
	_config.load(SAVE_PATH)


func get_global_scale() -> float:
	return _config.get_value("ui_scale", "global", DEFAULT_SCALE)


func set_global_scale(value: float) -> void:
	_config.set_value("ui_scale", "global", value)
	_config.save(SAVE_PATH)


func get_viewport_scale(viewport_key: StringName) -> float:
	if _config.has_section_key("ui_scale", viewport_key):
		return _config.get_value("ui_scale", viewport_key)
	return get_global_scale()


func set_viewport_override(viewport_key: StringName, value: float) -> void:
	_config.set_value("ui_scale", viewport_key, value)
	_config.save(SAVE_PATH)


func clear_viewport_override(viewport_key: StringName) -> void:
	if _config.has_section_key("ui_scale", viewport_key):
		_config.erase_section_key("ui_scale", viewport_key)
		_config.save(SAVE_PATH)


func has_viewport_override(viewport_key: StringName) -> bool:
	return _config.has_section_key("ui_scale", viewport_key)
