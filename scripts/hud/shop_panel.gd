class_name ShopPanel
extends Node2D

@export var preferred_width: int = 400
@export var friendship_label: Label


func _ready() -> void:
	ItemManager.friendship_point_balance_changed.connect(_on_friendship_point_balance_changed)
	_update_friendship_label(ItemManager.get_friendship_point_balance())


func _update_friendship_label(balance: int) -> void:
	friendship_label.text = "Friendship: %d" % balance


func _on_friendship_point_balance_changed(balance: int) -> void:
	_update_friendship_label(balance)
