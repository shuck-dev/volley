extends GutTest

var _config: UIScaleConfig


func before_each() -> void:
	DirAccess.remove_absolute(UIScaleConfig.SAVE_PATH)
	_config = UIScaleConfig.new()


# --- global scale ---


func test_default_global_scale_is_one() -> void:
	assert_eq(_config.get_global_scale(), 1.0)


func test_set_global_scale_persists_value() -> void:
	_config.set_global_scale(1.5)
	assert_eq(_config.get_global_scale(), 1.5)


# --- viewport scale ---


func test_viewport_scale_returns_global_when_no_override() -> void:
	_config.set_global_scale(1.25)
	assert_eq(_config.get_viewport_scale(&"hud"), 1.25)


func test_viewport_override_replaces_global() -> void:
	_config.set_global_scale(1.5)
	_config.set_viewport_override(&"shop", 1.0)
	assert_eq(_config.get_viewport_scale(&"shop"), 1.0)


func test_clear_viewport_override_falls_back_to_global() -> void:
	_config.set_global_scale(1.5)
	_config.set_viewport_override(&"hud", 0.75)
	_config.clear_viewport_override(&"hud")
	assert_eq(_config.get_viewport_scale(&"hud"), 1.5)


func test_has_viewport_override_returns_false_by_default() -> void:
	assert_false(_config.has_viewport_override(&"hud"))


func test_has_viewport_override_returns_true_after_set() -> void:
	_config.set_viewport_override(&"hud", 1.0)
	assert_true(_config.has_viewport_override(&"hud"))


func test_has_viewport_override_returns_false_after_clear() -> void:
	_config.set_viewport_override(&"hud", 1.0)
	_config.clear_viewport_override(&"hud")
	assert_false(_config.has_viewport_override(&"hud"))


func test_clear_nonexistent_override_does_not_error() -> void:
	_config.clear_viewport_override(&"nonexistent")
	assert_false(_config.has_viewport_override(&"nonexistent"))


func test_multiple_viewport_overrides_are_independent() -> void:
	_config.set_global_scale(1.0)
	_config.set_viewport_override(&"hud", 1.5)
	_config.set_viewport_override(&"shop", 0.75)
	assert_eq(_config.get_viewport_scale(&"hud"), 1.5)
	assert_eq(_config.get_viewport_scale(&"shop"), 0.75)
	assert_eq(_config.get_viewport_scale(&"kit"), 1.0)
