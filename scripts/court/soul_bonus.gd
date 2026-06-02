extends Label

@export var court: Court


func _ready() -> void:
	court.partner_changed.connect(_refresh)
	ItemManager.item_level_changed.connect(_refresh.unbind(1))
	ItemManager.item_placement_changed.connect(_refresh.unbind(2))
	_refresh()


func _refresh() -> void:
	var percentage_offset: float = ItemManager.get_percentage_offset(&"soul_per_hit")
	if percentage_offset > 0.0:
		text = "+%.0f%% Soul" % (percentage_offset * 100)
		visible = true
	else:
		visible = false
