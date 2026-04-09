class_name ShopConfig
extends Resource

@export var display_slots: int
@export var preferred_width: int
@export var items_row_position: Vector2

## Display case padding as proportions of item size: x=horizontal per side, y=top, z=bottom.
@export var display_case_padding: Vector3
## Uniform scale applied to the display case padding. 1.0 is tight, 2.0 is roomier.
@export var display_case_scale: float
## Friend's pick note position relative to the pick slot's top-left corner.
@export var pick_note_position: Vector2
