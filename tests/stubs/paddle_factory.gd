class_name PaddleFactory
extends RefCounted


## Create new paddle in positional lane
static func create(gut_test: GutTest, position: Vector2 = Vector2.ZERO) -> Paddle:
	var paddle: Paddle = load("res://scripts/entities/paddle.gd").new()
	return wire(gut_test, paddle, position)


## Wires the exports onto a paddle for testing
static func wire(gut_test: GutTest, paddle: Paddle, position: Vector2 = Vector2.ZERO) -> Paddle:
	paddle.position = position

	var sound := AudioStreamPlayer.new()
	paddle.add_child(sound)
	paddle.hit_sound = sound

	var tracker: HitTracker = load("res://scripts/core/hit_tracker.gd").new()
	paddle.add_child(tracker)
	paddle.tracker = tracker

	var racket_hitbox: RacketHitbox = load("res://scripts/entities/racket_hitbox.gd").new()
	var racket_collision := CollisionShape2D.new()
	racket_collision.shape = RectangleShape2D.new()
	racket_hitbox.add_child(racket_collision)
	racket_hitbox.collision = racket_collision
	paddle.add_child(racket_hitbox)
	paddle.racket_hitbox = racket_hitbox

	var swing_anticipation_zone := Area2D.new()
	paddle.add_child(swing_anticipation_zone)
	paddle.swing_anticipation_zone = swing_anticipation_zone

	var sprite := AnimatedSprite2D.new()
	paddle.add_child(sprite)
	paddle.sprite = sprite

	var ground_ray := RayCast2D.new()
	paddle.add_child(ground_ray)
	paddle.ground_ray = ground_ray

	gut_test.add_child_autofree(paddle)
	return paddle
