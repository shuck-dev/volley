class_name ShopShelf
extends Node2D

## The row of balls laid out on the stall.

signal item_grabbed(item: ShopItem)
signal item_dropped(item: ShopItem)
signal item_refund_owed(item: ShopItem)
signal item_drop_completed(ball_key: String, release_position: Vector2, purchased: bool)

const ShopItemScene: PackedScene = preload("res://scenes/shop_item.tscn")

@export var config: ShopConfig

## Bound into each item so it can hit-test its release against the stall.
@export var shop_area: Area2D

var _items: Array[ShopItem] = []


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


## Takes an item off the table.
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

	item.configure(BallManager, definition)
	item.bind_shop_area(shop_area)

	item.grabbed.connect(item_grabbed.emit)
	item.dropped.connect(item_dropped.emit)
	item.refund_owed.connect(item_refund_owed.emit)
	item.drop_completed.connect(item_drop_completed.emit)


func _roll_offering() -> Array[BallDefinition]:
	var available: Array[BallDefinition] = BallManager.items.duplicate()
	available.shuffle()

	return available.slice(0, config.display_slots)
