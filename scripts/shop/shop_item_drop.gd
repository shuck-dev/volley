class_name ShopItemDrop
extends Node

## A drop in progress: rides the falling HeldBody, settles on rest, notifies the originating ShopItem.

@export var tuning: ShopDragTuning

var _body: HeldBody
var _shop_item: Object
var _slow_frames: int = 0
var _elapsed: float = 0.0


func configure(body: HeldBody, shop_item: Object) -> void:
	_body = body
	_shop_item = shop_item


func _physics_process(delta: float) -> void:
	if _body == null or not is_instance_valid(_body):
		queue_free()
		return

	var velocity_threshold: float = tuning.settle_velocity_threshold if tuning != null else 4.0
	var frames_required: int = tuning.settle_frames_required if tuning != null else 6
	var lifetime_cap: float = tuning.max_lifetime_s if tuning != null else 4.0

	_elapsed += delta
	if _body.linear_velocity.length() <= velocity_threshold:
		_slow_frames += 1
	else:
		_slow_frames = 0

	if _slow_frames >= frames_required or _elapsed >= lifetime_cap:
		_settle()


func _settle() -> void:
	var settled_position: Vector2 = _body.global_position
	if (
		_shop_item != null
		and is_instance_valid(_shop_item)
		and _shop_item.has_method("notify_body_settled")
	):
		_shop_item.notify_body_settled(_body, settled_position)
	queue_free()
