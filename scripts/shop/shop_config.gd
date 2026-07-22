class_name ShopConfig
extends Resource

@export var display_slots: int = 5
@export var item_spacing: float = 80.0
## Fraction of displayed items' total base cost charged for restock after the first free one.
@export var restock_cost_multiplier: float = 0.2
