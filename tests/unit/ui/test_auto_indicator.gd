extends GutTest

const AutoIndicator = preload("res://scripts/court/auto_indicator.gd")


func test_label_hidden_when_autoplay_off() -> void:
	var court: Court = autofree(Court.new())
	var label: Label = autofree(AutoIndicator.new())
	label.court = court
	add_child_autofree(label)
	court.auto_play_changed.emit(false, 0.5)
	assert_false(label.visible)


func test_label_visible_with_rate_when_autoplay_on() -> void:
	var court: Court = autofree(Court.new())
	var label: Label = autofree(AutoIndicator.new())
	label.court = court
	add_child_autofree(label)
	court.auto_play_changed.emit(true, 0.5)
	assert_true(label.visible)
	assert_eq(label.text, "AUTO (50% Friendship Points)")
