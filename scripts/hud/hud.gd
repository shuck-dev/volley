extends CanvasLayer

@export var counter_label: Label
@export var personal_volley_best_label: Label


func update_volley_count(count: int) -> void:
	counter_label.text = "Volleys: %d" % count


func update_personal_volley_best(best: int) -> void:
	personal_volley_best_label.text = "Personal Volley Best: %d" % best
