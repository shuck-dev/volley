extends CanvasLayer

@export var counter_label: Label
@export var personal_volley_best_label: Label
@export var friendship_total_label: Label


func update_volley_count(count: int) -> void:
	counter_label.text = "Volleys: %d" % count


func update_personal_volley_best(best: int) -> void:
	personal_volley_best_label.text = "PB: %d" % best


func update_friendship_total(friendship_total: int) -> void:
	friendship_total_label.text = "FP: %d" % friendship_total
