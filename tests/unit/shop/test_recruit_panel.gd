extends GutTest


func _make_panel() -> VBoxContainer:
	var panel: VBoxContainer = autofree(load("res://scenes/recruit_panel.tscn").instantiate())
	add_child_autofree(panel)
	return panel


func test_panel_hidden_on_ready() -> void:
	var panel: VBoxContainer = _make_panel()
	assert_false(panel.visible)


func test_panel_shows_on_recruit_available() -> void:
	var panel: VBoxContainer = _make_panel()
	var partner: PartnerDefinition = PartnerDefinition.new()
	partner.key = &"test_partner"
	partner.display_name = "Test Partner"
	partner.unlock_cost = 100
	ProgressionManager.partner_recruit_available.emit(partner)
	assert_true(panel.visible)
	assert_eq(panel.recruit_label.text, "Recruit Test Partner")
	assert_eq(panel.recruit_button.text, "100 FP")


func test_panel_hides_on_partner_recruited() -> void:
	var panel: VBoxContainer = _make_panel()
	var partner: PartnerDefinition = PartnerDefinition.new()
	partner.key = &"test_partner"
	partner.display_name = "Test Partner"
	partner.unlock_cost = 100
	ProgressionManager.partner_recruit_available.emit(partner)
	ProgressionManager.partner_recruited.emit(&"test_partner")
	assert_false(panel.visible)
