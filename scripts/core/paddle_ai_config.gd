class_name PaddleAIConfig
extends Resource

@export_group("Tracking")
## Frames of latency between seeing the ball and reacting.
@export var reaction_delay_frames: int = 20
## Movement speed as a multiplier of paddle speed. Below 1.0 = slower, above 1.0 = faster.
@export var speed_scale: float = 0.75

@export_group("Prediction")
## Standard deviation (pixels) of noise on the predicted intercept.
## 0 = perfect aim. Sampled once per ball flight, not every frame.
@export_range(0.0, 120.0) var noise: float = 0.0

@export_group("Feel")
## Lerp factor for velocity changes while tracking (0 = frozen, 1 = instant).
@export_range(0.01, 1.0) var velocity_smoothing: float = 0.04
## Drift speed as a fraction of tracking speed when ball is moving away.
@export var center_drift_scale: float = 0.25
## Lerp factor for drift velocity changes.
@export_range(0.01, 1.0) var center_drift_smoothing: float = 0.025
## Pixels within which the paddle stops tracking to prevent jitter.
@export var snap_threshold: float = 8.0
