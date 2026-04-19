extends GutTest


func test_label_hidden_when_no_bonus() -> void:
	var court: Court = autofree(Court.new())
	var label: Label = autofree(load("res://scripts/court/fp_bonus.gd").new())
	label.court = court
	add_child_autofree(label)
	court.partner_changed.emit()
	assert_false(label.visible)
