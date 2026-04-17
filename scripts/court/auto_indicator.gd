extends Label

@export var court: Court


func _ready() -> void:
	visible = false
	court.auto_play_changed.connect(_on_auto_play_changed)


func _on_auto_play_changed(is_active: bool, friendship_point_rate: float) -> void:
	visible = is_active
	if is_active:
		text = "AUTO (%.0f%% Friendship Points)" % (friendship_point_rate * 100)
