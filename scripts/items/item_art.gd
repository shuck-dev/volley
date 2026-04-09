class_name ItemArt
extends Node2D

## Local-space rect of the visible art. Consumers size their viewport to
## `bounding_rect.size` and shift the art by `-bounding_rect.position`.
@export var bounding_rect: Rect2
