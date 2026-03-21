extends CanvasLayer

@export var counter_label: Label


func update_volley_count(count: int) -> void:
	counter_label.text = "Volleys: %d" % count
