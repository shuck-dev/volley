extends Label

@export var court: Court


func _ready() -> void:
	court.volley_count_changed.connect(_on_volley_count_changed)


func _on_volley_count_changed(count: int) -> void:
	text = "Volleys: %d" % count
