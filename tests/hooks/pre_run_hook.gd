extends "res://addons/gut/hook_script.gd"

const CoverageScript = preload("res://addons/coverage/coverage.gd")

const EXCLUDE_PATHS = [
	"res://addons/*",
	"res://tests/*",
	# Require full scene with nodes, not unit-testable
	"res://scripts/hud/*",
	"res://scripts/core/venue.gd",
	# One-method duck-typing stubs, exercised through ball collision tests
	"res://scripts/entities/miss_zone.gd",
	# Thin wrappers, require full scene tree
	"res://scripts/entities/partner_paddle.gd",
	"res://scripts/entities/player_paddle.gd",
	# Abstract base class, only used for mocking
	"res://scripts/progression/save_storage.gd",
	# Autoload, not unit-testable
	"res://scripts/progression/save_manager.gd",
	# Pure data resource, exercised through GameRules.base / GameRules.paddle
	"res://scripts/core/base_stats_config.gd",
	"res://scripts/core/paddle_config.gd",
	# Abstract base class; subclasses override apply() and describe()
	"res://scripts/items/effect/outcome.gd",
	# Drawing-heavy @tool Control; _draw paths are untouched in headless tests
	"res://scripts/court/speed_bar.gd",
	# SH-297: pure enum + label container; only consumed via const access from callers.
	"res://scripts/items/cursor_state.gd",
]


func run():
	# Doubling the physics tick rate (60 -> 120 Hz) halves the wall-clock cost of every
	# `await get_tree().physics_frame` from ~16ms to ~8ms. Higher rates (240 Hz) shrink
	# `move_and_slide` per-step displacement enough that fixed-step tests overshoot their
	# step budget; 120 Hz is the largest safe bump for this suite.
	Engine.physics_ticks_per_second = 120
	CoverageScript.new(gut.get_tree(), EXCLUDE_PATHS).instrument_scripts("res://")
