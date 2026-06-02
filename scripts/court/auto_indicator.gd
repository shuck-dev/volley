extends Label

@export var court: Court


func _ready() -> void:
	visible = false
	court.auto_play_changed.connect(_on_auto_play_changed)


func _on_auto_play_changed(is_active: bool, soul_rate: float) -> void:
	visible = is_active
	if is_active:
		text = "AUTO (%.0f%% Soul)" % (soul_rate * 100)
