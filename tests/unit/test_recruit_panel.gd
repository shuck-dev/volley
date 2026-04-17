extends GutTest


func test_panel_hidden_on_ready() -> void:
	var panel: VBoxContainer = autofree(load("res://scenes/recruit_panel.tscn").instantiate())
	add_child_autofree(panel)
	assert_false(panel.visible)
