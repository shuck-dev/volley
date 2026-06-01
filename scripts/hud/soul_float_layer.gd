class_name SoulFloatLayer
extends CanvasLayer

## Spawns floating +N soul labels on every per-hit soul award and ball upgrade events.

@export var float_scene: PackedScene
## Vertical offset applied on top of the signal anchor.
@export var anchor_offset: Vector2 = Vector2(0.0, -40.0)

var _court: Court
var _handler: TierRewardHandler


func _ready() -> void:
	_court = get_tree().get_first_node_in_group(&"courts") as Court
	_handler = get_tree().get_first_node_in_group(&"tier_reward_handlers") as TierRewardHandler

	if _court != null:
		_court.soul_earned.connect(_on_soul_earned)

	if _handler != null:
		_handler.ball_upgrade_earned.connect(_on_ball_upgrade_earned)

	if _court == null or _handler == null:
		get_tree().node_added.connect(_on_node_added_waiting)


func _exit_tree() -> void:
	if is_inside_tree() and get_tree().node_added.is_connected(_on_node_added_waiting):
		get_tree().node_added.disconnect(_on_node_added_waiting)
	if is_instance_valid(_court) and _court.soul_earned.is_connected(_on_soul_earned):
		_court.soul_earned.disconnect(_on_soul_earned)
	if (
		is_instance_valid(_handler)
		and _handler.ball_upgrade_earned.is_connected(_on_ball_upgrade_earned)
	):
		_handler.ball_upgrade_earned.disconnect(_on_ball_upgrade_earned)


func _on_node_added_waiting(node: Node) -> void:
	if _court == null:
		var court := node as Court
		if court != null:
			_court = court
			_court.soul_earned.connect(_on_soul_earned)

	if _handler == null:
		var handler := node as TierRewardHandler
		if handler != null:
			_handler = handler
			_handler.ball_upgrade_earned.connect(_on_ball_upgrade_earned)

	if _court != null and _handler != null:
		get_tree().node_added.disconnect(_on_node_added_waiting)


func _on_soul_earned(amount: int, anchor: Vector2) -> void:
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
