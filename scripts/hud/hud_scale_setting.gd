extends HBoxContainer

@export var scale_label: Label
@export var scale_slider: HSlider
@export var apply_button: Button

var _ui_scale_config: UIScaleConfig


func _ready() -> void:
	var scene_layout := _find_scene_layout()
	if scene_layout != null:
		_ui_scale_config = scene_layout.get_ui_scale_config()
	else:
		_ui_scale_config = UIScaleConfig.new()

	scale_slider.min_value = UIScaleConfig.MIN_SCALE
	scale_slider.max_value = UIScaleConfig.MAX_SCALE
	scale_slider.step = UIScaleConfig.STEP

	var saved_scale := _ui_scale_config.get_global_scale()
	scale_slider.value = saved_scale
	_update_label(saved_scale)
	apply_button.disabled = true

	scale_slider.value_changed.connect(_on_scale_changed)
	apply_button.pressed.connect(_on_apply_pressed)


func _on_scale_changed(value: float) -> void:
	_update_label(value)
	var current_scale := _ui_scale_config.get_global_scale()
	apply_button.disabled = is_equal_approx(value, current_scale)


func _on_apply_pressed() -> void:
	var value := scale_slider.value
	_ui_scale_config.set_global_scale(value)

	var scene_layout := _find_scene_layout()
	if scene_layout != null:
		scene_layout.apply_global_scale()

	apply_button.disabled = true


func _update_label(value: float) -> void:
	scale_label.text = "UI: %d%%" % roundi(value * 100)


func _find_scene_layout() -> SceneLayout:
	for child in get_tree().root.get_children():
		if child is SceneLayout:
			return child
	return null
