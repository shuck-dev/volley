extends GutTest


func test_label_updates_on_signal() -> void:
	var court: Court = autofree(Court.new())
	var label: Label = autofree(load("res://scripts/court/volley_counter.gd").new())
	label.court = court
	add_child_autofree(label)
	court.volley_count_changed.emit(7)
	assert_eq(label.text, "Volleys: 7")
