extends ItemArt

var _palette: Array[Color] = [
	Color.WHITE,
	Color(0.9, 0.85, 0.7),
	Color(0.85, 0.9, 0.85),
]


func _ready() -> void:
	var sprite: Sprite2D = get_node("Sprite") as Sprite2D
	if sprite != null:
		sprite.modulate = _palette[randi() % _palette.size()]
