class_name SoulFloatLayer
extends CanvasLayer

## Listens for soul reward signals from TierRewardHandler and spawns floating +N soul labels.

@export var float_scene: PackedScene
## Vertical offset applied on top of the signal anchor.
@export var anchor_offset: Vector2 = Vector2(0.0, -40.0)

var _handler: TierRewardHandler


func _ready() -> void:
	_handler = get_tree().get_first_node_in_group(&"tier_reward_handlers") as TierRewardHandler

	if _handler != null:
		_connect_handler(_handler)
	else:
		get_tree().node_added.connect(_on_node_added_waiting)


func _exit_tree() -> void:
	if is_inside_tree() and get_tree().node_added.is_connected(_on_node_added_waiting):
		get_tree().node_added.disconnect(_on_node_added_waiting)


func _on_node_added_waiting(node: Node) -> void:
	var handler := node as TierRewardHandler

	if handler == null:
		return

	get_tree().node_added.disconnect(_on_node_added_waiting)
	_handler = handler
	_connect_handler(_handler)


func _connect_handler(handler: TierRewardHandler) -> void:
	handler.soul_reward_earned.connect(_on_soul_reward_earned)
	handler.ball_upgrade_earned.connect(_on_ball_upgrade_earned)


func _on_soul_reward_earned(amount: int, anchor: Vector2) -> void:
	if float_scene == null:
		return

	var label: SoulFloat = float_scene.instantiate()
	label.text = "+%d soul" % amount
	label.position = anchor + anchor_offset
	add_child(label)


func _on_ball_upgrade_earned(anchor: Vector2) -> void:
	if float_scene == null:
		return

	var label: SoulFloat = float_scene.instantiate()
	label.text = "ball up!"
	label.position = anchor + anchor_offset
	add_child(label)
