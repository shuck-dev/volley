class_name ShopConfig
extends Resource

## Tuning for the stall; the values live in resources/shop_config.tres.

## How many balls are laid out at once.
@export var display_slots: int

## Gap between neighbouring balls on the shelf.
@export var item_spacing: float

## Height the row of items sits at, relative to the shop's origin.
@export var item_row_height: float

## Fraction of displayed items' total base cost charged for restock after the first free one.
@export var restock_cost_multiplier: float
