class_name ShopItemSettleWatcher
extends Node

## Polls a falling HeldBody until it settles, then notifies the originating ShopItem with the resting position.

const SETTLE_VELOCITY_THRESHOLD: float = 4.0
const SETTLE_FRAMES_REQUIRED: int = 6
## Hard cap so a body that bounces off-screen still resolves the gesture eventually.
const MAX_LIFETIME_S: float = 4.0

var _body: HeldBody
var _shop_item: Object
var _slow_frames: int = 0
var _elapsed: float = 0.0


func configure(body: HeldBody, shop_item: Object, _shop_area: Area2D = null) -> void:
	_body = body
	_shop_item = shop_item


func _physics_process(delta: float) -> void:
	if _body == null or not is_instance_valid(_body):
		queue_free()
		return

	_elapsed += delta
	if _body.linear_velocity.length() <= SETTLE_VELOCITY_THRESHOLD:
		_slow_frames += 1
	else:
		_slow_frames = 0

	if _slow_frames >= SETTLE_FRAMES_REQUIRED or _elapsed >= MAX_LIFETIME_S:
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
