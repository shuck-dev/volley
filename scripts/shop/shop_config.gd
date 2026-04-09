class_name ShopConfig
extends Resource

@export var display_slots: int = 5
@export var preferred_width: int = 500
@export var items_row_position: Vector2 = Vector2.ZERO

## Display case padding as proportions of item size: x=horizontal per side, y=top, z=bottom.
@export var display_case_padding: Vector3 = Vector3(0.5, 1.0, 0.3)
## Uniform scale applied to the display case padding. 1.0 is tight, 2.0 is roomier.
@export var display_case_scale: float = 1.0
