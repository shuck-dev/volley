extends CanvasLayer

signal shop_button_pressed

@export var counter_label: Label
@export var personal_volley_best_label: Label
@export var friendship_point_balance_label: Label
@export var speed_bar: Control
@export var auto_label: Label
@export var shop_button: Button


func _ready() -> void:
	ItemManager.friendship_point_balance_changed.connect(update_friendship_point_balance)
	update_friendship_point_balance(ItemManager.get_friendship_point_balance())
	auto_label.visible = false

	ProgressionManager.shop_unlocked_changed.connect(_on_shop_unlocked_changed)
	shop_button.visible = ProgressionManager.is_shop_unlocked()
	shop_button.pressed.connect(shop_button_pressed.emit)


func update_volley_count(count: int) -> void:
	counter_label.text = "Volleys: %d" % count


func update_personal_volley_best(best: int) -> void:
	personal_volley_best_label.text = "PB: %d" % best


func update_friendship_point_balance(friendship_point_balance: int) -> void:
	friendship_point_balance_label.text = "FP: %d" % friendship_point_balance


func update_speed(
	current_speed: float, min_speed: float, max_speed: float, permanent_max_speed: float
) -> void:
	speed_bar.update_speed(current_speed, min_speed, max_speed, permanent_max_speed)


func update_auto_play(is_active: bool, friendship_point_rate: float) -> void:
	auto_label.visible = is_active
	if is_active:
		auto_label.text = "AUTO (%.0f%% Friendship Points)" % (friendship_point_rate * 100)


func _on_shop_unlocked_changed(is_unlocked: bool) -> void:
	shop_button.visible = is_unlocked
