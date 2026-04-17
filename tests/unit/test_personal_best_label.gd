extends GutTest


func test_label_updates_on_signal() -> void:
	var court: Court = autofree(Court.new())
	var label: Label = autofree(load("res://scripts/court/personal_best.gd").new())
	label.court = court
	add_child_autofree(label)
	court.personal_volley_best_changed.emit(42)
	assert_eq(label.text, "PB: 42")
