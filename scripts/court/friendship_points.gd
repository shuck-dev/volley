extends Label


func _ready() -> void:
	ItemManager.friendship_point_balance_changed.connect(_on_friendship_point_balance_changed)
	_on_friendship_point_balance_changed(ItemManager.get_friendship_point_balance())


func _on_friendship_point_balance_changed(friendship_point_balance: int) -> void:
	text = "FP: %d" % friendship_point_balance
