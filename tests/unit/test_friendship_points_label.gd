extends GutTest

const FriendshipPointsLabel = preload("res://scripts/court/friendship_points.gd")


func test_label_shows_current_balance_on_ready() -> void:
	var starting_balance: int = ItemManager.get_friendship_point_balance()
	var label: Label = autofree(FriendshipPointsLabel.new())
	add_child_autofree(label)
	assert_eq(label.text, "FP: %d" % starting_balance)


func test_label_updates_on_signal() -> void:
	var label: Label = autofree(FriendshipPointsLabel.new())
	add_child_autofree(label)
	ItemManager.friendship_point_balance_changed.emit(99)
	assert_eq(label.text, "FP: 99")
