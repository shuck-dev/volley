extends Node2D

@export var drop_area: Area2D
@export var upgrade_button: Button
@export var upgrade_cost_label: Label
@export var ball_reconciler: BallReconciler
@export var ball_rack: Node

var _item_manager: Node
var _docked_item_key: String = ""


func _ready() -> void:
	if _item_manager == null:
		_item_manager = ItemManager
	if upgrade_button != null:
		upgrade_button.pressed.connect(_on_upgrade_pressed)
	_hide_upgrade_ui()


func is_docked() -> bool:
	return not _docked_item_key.is_empty()


func dock_ball(item_key: String) -> void:
	if _item_manager == null or not _docked_item_key.is_empty():
		return
	_docked_item_key = item_key
	_item_manager.deactivate(item_key)
	_position_ball_at_self(item_key)
	_show_upgrade_ui()


func _show_upgrade_ui() -> void:
	if not _docked_item_key.is_empty():
		var definition: ItemDefinition = _get_definition(_docked_item_key)
		if definition != null:
			upgrade_cost_label.text = "Cost: %d" % definition.upgrade_cost
	upgrade_button.visible = true
	upgrade_cost_label.visible = true


func _hide_upgrade_ui() -> void:
	upgrade_button.visible = false
	upgrade_cost_label.visible = false


func _on_upgrade_pressed() -> void:
	if _docked_item_key.is_empty() or _item_manager == null:
		return
	var definition: ItemDefinition = _get_definition(_docked_item_key)
	if definition == null:
		return
	var cost: int = definition.upgrade_cost
	if _item_manager.get_soul_balance() < cost:
		return
	if not _item_manager.upgrade_ball(_docked_item_key):
		return
	_item_manager.subtract_soul(cost)
	_position_ball_on_rack(_docked_item_key)
	_docked_item_key = ""
	_hide_upgrade_ui()


func _position_ball_at_self(item_key: String) -> void:
	var ball: Node = _find_ball(item_key)
	if ball != null and ball.has_method("enter_stored"):
		ball.enter_stored()
	if ball != null and ball is Node2D:
		(ball as Node2D).global_position = global_position


func _position_ball_on_rack(item_key: String) -> void:
	var ball: Node = _find_ball(item_key)
	if ball == null:
		return
	if ball.has_method("enter_stored"):
		ball.enter_stored()
	var rack: Node = ball_rack
	if rack != null and rack.has_method("get_slot_position_for"):
		var slot_pos: Variant = rack.get_slot_position_for(item_key)
		if slot_pos is Vector2 and ball is Node2D:
			(ball as Node2D).global_position = slot_pos


func _find_ball(item_key: String) -> Node:
	var reconciler: Node = ball_reconciler
	if reconciler == null:
		return null
	if not reconciler.has_method("get_ball_for_key"):
		return null
	return reconciler.get_ball_for_key(item_key)


func _get_definition(item_key: String) -> ItemDefinition:
	if _item_manager == null:
		return null
	for item: ItemDefinition in _item_manager.items:
		if item.key == item_key:
			return item
	return null
