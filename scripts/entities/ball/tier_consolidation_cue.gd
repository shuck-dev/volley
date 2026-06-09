class_name TierConsolidationCue
extends Node2D

const _RING_TEXTURE_PATH: String = "res://assets/ui/tier_cue_ring.svg"
const _GROUP: StringName = &"tier_consolidation_cue"

## Duration the ring takes to fully expand and fade.
@export_range(0.05, 2.0) var duration_s: float = 0.4
## Scale the ring starts at; the ring expands from this to ring_scale_end.
@export_range(0.1, 2.0) var ring_scale_start: float = 1.0
## Scale the ring reaches by the end of the animation.
@export_range(1.0, 5.0) var ring_scale_end: float = 1.8
## Tint applied to the ring sprite; alpha is fully opaque at start and tweened to zero.
@export var ring_color: Color = Color(1.0, 1.0, 1.0, 1.0)

var _sprite: Sprite2D


func _ready() -> void:
	add_to_group(_GROUP)

	_sprite = Sprite2D.new()
	_sprite.modulate = ring_color
	_sprite.scale = Vector2.ONE * ring_scale_start

	if ResourceLoader.exists(_RING_TEXTURE_PATH):
		_sprite.texture = load(_RING_TEXTURE_PATH) as Texture2D

	add_child(_sprite)

	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(_sprite, "scale", Vector2.ONE * ring_scale_end, duration_s)
	tween.tween_property(_sprite, "modulate:a", 0.0, duration_s)
	tween.chain().tween_callback(queue_free)
