extends "res://addons/gut/hook_script.gd"

const CoverageScript = preload("res://addons/coverage/coverage.gd")

const EXCLUDE_PATHS = [
	"res://addons/*",
	"res://tests/*",
	# Require full scene with nodes, not unit-testable
	"res://scripts/hud/*",
	"res://scripts/core/scene_layout.gd",
	"res://scripts/entities/back_wall.gd",
	# Abstract base class, only used for mocking
	"res://scripts/progression/save_storage.gd",
	# Autoload, not unit-testable
	"res://scripts/progression/save_manager.gd",
]


func run():
	CoverageScript.new(gut.get_tree(), EXCLUDE_PATHS).instrument_scripts("res://")
