class_name GameRules
extends RefCounted

const CONFIG: Resource = preload("res://resources/base_stats.tres")

static var base_stats: Dictionary = CONFIG.to_dict()
