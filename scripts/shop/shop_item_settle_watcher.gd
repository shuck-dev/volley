class_name ShopItemSettleWatcher
extends Node

## Polls a falling HeldBody until it settles, then notifies the originating ShopItem with the resting position.

@export var settle_velocity_threshold: float = 4.0
@export var settle_frames_required: int = 6
@export var max_lifetime_s: float = 4.0

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

	_elapsed += delta
	if _body.linear_velocity.length() <= settle_velocity_threshold:
		_slow_frames += 1
	else:
		_slow_frames = 0

	if _slow_frames >= settle_frames_required or _elapsed >= max_lifetime_s:
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
