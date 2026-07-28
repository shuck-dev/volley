extends Label


func _ready() -> void:
	BallManager.soul_balance_changed.connect(_on_soul_balance_changed)
	_on_soul_balance_changed(BallManager.get_soul_balance())


func _on_soul_balance_changed(soul_balance: int) -> void:
	text = "Soul: %d" % soul_balance
