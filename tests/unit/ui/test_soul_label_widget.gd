extends GutTest

const SoulLabel = preload("res://scripts/court/soul.gd")


func test_label_shows_current_balance_on_ready() -> void:
	var starting_balance: int = ItemManager.get_soul_balance()
	var label: Label = autofree(SoulLabel.new())
	add_child_autofree(label)
	assert_eq(label.text, "Soul: %d" % starting_balance)


func test_label_updates_on_signal() -> void:
	var label: Label = autofree(SoulLabel.new())
	add_child_autofree(label)
	ItemManager.soul_balance_changed.emit(99)
	assert_eq(label.text, "Soul: 99")
