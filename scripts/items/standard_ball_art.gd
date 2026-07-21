extends ItemArt

var _textures: Array[Texture2D] = [
	preload("res://assets/items/training_ball.png"),
	preload("res://assets/sprites/ball.png"),
]

var _palette: Array[Color] = [
	Color.WHITE,
	Color(0.9, 0.85, 0.7),
	Color(0.85, 0.9, 0.85),
	Color(0.95, 0.85, 0.9),
	Color(0.85, 0.9, 1.0),
	Color(0.95, 0.95, 0.8),
]


func _ready() -> void:
	var sprite: Sprite2D = get_node("Sprite") as Sprite2D
	if sprite == null:
		return
	sprite.texture = _textures[randi() % _textures.size()]
	sprite.modulate = _palette[randi() % _palette.size()]
	sprite.rotation = randf_range(-0.15, 0.15)
