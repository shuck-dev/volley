extends CanvasLayer

@export var counter_label: Label
@export var personal_volley_best_label: Label
@export var friendship_point_balance_label: Label
@export var max_speed_label: Label
@export var auto_label: Label


func _ready() -> void:
	ItemManager.friendship_point_balance_changed.connect(update_friendship_point_balance)
	update_friendship_point_balance(ItemManager.get_friendship_point_balance())
	max_speed_label.visible = false
	auto_label.visible = false


func update_volley_count(count: int) -> void:
	counter_label.text = "Volleys: %d" % count


func update_personal_volley_best(best: int) -> void:
	personal_volley_best_label.text = "PB: %d" % best


func update_friendship_point_balance(friendship_point_balance: int) -> void:
	friendship_point_balance_label.text = "FP: %d" % friendship_point_balance


func update_max_speed(is_at_max: bool) -> void:
	max_speed_label.visible = is_at_max


func update_auto_play(is_active: bool, friendship_point_rate: float) -> void:
	auto_label.visible = is_active
	if is_active:
		auto_label.text = "AUTO (%.0f%% Friendship Points)" % (friendship_point_rate * 100)
