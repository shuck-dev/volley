extends GutTest

const _SETTINGS_SCRIPT := preload("res://scripts/core/settings.gd")
const _DEFAULTS_SCRIPT := preload("res://scripts/core/settings_defaults.gd")

var _settings: Node
var _tmp_path: String


func before_each() -> void:
	_tmp_path = "user://test_settings_%d.cfg" % randi()
	_settings = _SETTINGS_SCRIPT.new(_tmp_path)
	add_child_autofree(_settings)


func after_each() -> void:
	if FileAccess.file_exists(_tmp_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(_tmp_path))


func test_first_run_returns_default_master_volume() -> void:
	var defaults: Resource = _DEFAULTS_SCRIPT.new()
	var value: float = _settings.get_value("audio", "master_volume", defaults.default_master_volume)

	assert_almost_eq(
		value,
		defaults.default_master_volume,
		0.001,
		"first-run master volume falls back to default"
	)


func test_set_value_persists_across_reload() -> void:
	_settings.set_value("audio", "master_volume", 0.5)

	var reloaded: Node = _SETTINGS_SCRIPT.new(_tmp_path)
	add_child_autofree(reloaded)

	var value: float = reloaded.get_value("audio", "master_volume", 1.0)
	assert_almost_eq(value, 0.5, 0.001, "set value survives a fresh load from disk")


func test_settings_file_is_independent_of_save_manager() -> void:
	_settings.set_value("audio", "sfx_volume", 0.3)

	var save_path := "user://save_data.json"

	if FileAccess.file_exists(save_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))

	assert_false(FileAccess.file_exists(save_path), "save file absent after deletion")

	var value: float = _settings.get_value("audio", "sfx_volume", 1.0)
	assert_almost_eq(value, 0.3, 0.001, "setting survives save-file wipe")


func test_set_value_no_op_on_same_value() -> void:
	_settings.set_value("display", "fps_cap", 60)
	_settings.set_value("display", "fps_cap", 60)

	var value: int = _settings.get_value("display", "fps_cap", 0)
	assert_eq(value, 60, "repeated set with same value does not corrupt the stored value")


func test_set_value_updates_to_new_value() -> void:
	_settings.set_value("display", "fps_cap", 60)
	_settings.set_value("display", "fps_cap", 120)

	var value: int = _settings.get_value("display", "fps_cap", 0)
	assert_eq(value, 120, "set value replaces the previous value")
