class_name ShopShelf
extends Node2D

## The row of balls laid out on the stall. Owns what is on offer and where it sits;
## the shop above it owns the soul and the purchase.

## Re-raised from whichever item the player is acting on, so the shop wires once.
signal item_grabbed(item: ShopItem)
signal item_dropped(item: ShopItem)
signal item_refund_owed(item: ShopItem)
signal item_drop_completed(ball_key: String, release_position: Vector2, purchased: bool)

const ShopItemScene: PackedScene = preload("res://scenes/shop_item.tscn")

var config: ShopConfig
var _ball_manager: BallManager
var _shop_area: Area2D
var _items: Array[ShopItem] = []


## The shop supplies what an item needs but the shelf has no business knowing.
func configure(shop_config: ShopConfig, ball_manager: BallManager, shop_area: Area2D) -> void:
	config = shop_config
	_ball_manager = ball_manager
	_shop_area = shop_area


## Clears the table and rolls a fresh offering onto it.
func restock() -> void:
	clear()

	var offering: Array[BallDefinition] = _roll_offering()
	var count: int = offering.size()
	var spacing: float = config.item_spacing
	var start_x: float = -(count - 1) * spacing / 2.0

	for index in count:
		var definition: BallDefinition = offering[index]
		var slot := Vector2(start_x + index * spacing, config.item_row_height)

		_add_item(definition, slot)


func clear() -> void:
	for item: ShopItem in _items.duplicate():
		remove_item(item)


## Takes an item off the table. Unparenting is immediate, so the freeing can be
## deferred: removal runs mid-signal, where the node is still being called into.
func remove_item(item: ShopItem) -> void:
	_items.erase(item)
	remove_child(item)

	item.queue_free()


## The item offering `ball_key`, or null once it has left the table.
func find_item(ball_key: String) -> ShopItem:
	for item: ShopItem in _items:
		if item.ball_definition != null and item.ball_definition.key == ball_key:
			return item

	return null


## What the balls currently laid out are worth at their base price.
func total_base_cost() -> int:
	var total: int = 0

	for item: ShopItem in _items:
		if item.ball_definition != null:
			total += item.ball_definition.base_cost

	return total


func _add_item(definition: BallDefinition, slot: Vector2) -> void:
	var item: ShopItem = ShopItemScene.instantiate()
	item.name = "ShopItem_%s" % definition.key
	item.position = slot

	add_child(item)
	_items.append(item)

	item.configure(_ball_manager, definition)
	item.bind_shop_area(_shop_area)

	item.grabbed.connect(item_grabbed.emit)
	item.dropped.connect(item_dropped.emit)
	item.refund_owed.connect(item_refund_owed.emit)
	item.drop_completed.connect(item_drop_completed.emit)


func _roll_offering() -> Array[BallDefinition]:
	var available: Array[BallDefinition] = _ball_manager.items.duplicate()
	available.shuffle()

	return available.slice(0, config.display_slots)
