extends Label


func _ready() -> void:
	ItemManager.soul_balance_changed.connect(_on_soul_balance_changed)
	_on_soul_balance_changed(ItemManager.get_soul_balance())


func _on_soul_balance_changed(soul_balance: int) -> void:
	text = "Soul: %d" % soul_balance
