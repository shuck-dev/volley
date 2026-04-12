class_name PartnerDefinition
extends Resource

const EffectType = preload("res://scripts/items/effect/effect.gd")

@export var key: StringName
@export var display_name: String
@export var unlock_threshold: int
@export var unlock_cost: int
@export var effects: Array[EffectType]
