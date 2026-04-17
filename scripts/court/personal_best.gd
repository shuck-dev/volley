extends Label

@export var court: Court


func _ready() -> void:
	court.personal_volley_best_changed.connect(_on_personal_volley_best_changed)


func _on_personal_volley_best_changed(best: int) -> void:
	text = "PB: %d" % best
