extends HBoxContainer

signal scale_applied(value: float)

@export var scale_label: Label
@export var scale_slider: HSlider
@export var apply_button: Button

var _ui_scale_config: UIScaleConfig


func _ready() -> void:
	if _ui_scale_config == null:
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


func set_ui_scale_config(config: UIScaleConfig) -> void:
	_ui_scale_config = config


func _on_scale_changed(value: float) -> void:
	_update_label(value)
	var current_scale := _ui_scale_config.get_global_scale()
	apply_button.disabled = is_equal_approx(value, current_scale)


func _on_apply_pressed() -> void:
	var value := scale_slider.value
	_ui_scale_config.set_global_scale(value)
	scale_applied.emit(value)
	apply_button.disabled = true


func _update_label(value: float) -> void:
	scale_label.text = "UI: %d%%" % roundi(value * 100)
