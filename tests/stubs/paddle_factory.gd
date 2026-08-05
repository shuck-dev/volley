class_name PaddleFactory
extends RefCounted

## Builds a bare Paddle wired with the same exports every shipped paddle scene wires, so tests
## exercise the real _ready() contract instead of a guard-permissive shortcut.


## position is applied before the paddle enters the tree so _ready() captures the intended lane.
static func create(gut_test: GutTest, position: Vector2 = Vector2.ZERO) -> Paddle:
	var paddle: Paddle = load("res://scripts/entities/paddle.gd").new()
	return wire(gut_test, paddle, position)


## Wires the exports a shipped paddle scene wires onto an already-constructed Paddle (or
## subclass, e.g. a test stub), then adds it to the tree. Lets callers supply their own subclass
## while still satisfying the real _ready() contract.
static func wire(gut_test: GutTest, paddle: Paddle, position: Vector2 = Vector2.ZERO) -> Paddle:
	paddle.position = position

	var sound := AudioStreamPlayer.new()
	paddle.add_child(sound)
	paddle.hit_sound = sound

	var tracker: HitTracker = load("res://scripts/core/hit_tracker.gd").new()
	paddle.add_child(tracker)
	paddle.tracker = tracker

	var body_collision := CollisionShape2D.new()
	body_collision.shape = RectangleShape2D.new()
	paddle.add_child(body_collision)
	paddle.collision = body_collision

	var racket_hitbox := Area2D.new()
	var racket_collision := CollisionShape2D.new()
	racket_collision.shape = RectangleShape2D.new()
	racket_hitbox.add_child(racket_collision)
	paddle.add_child(racket_hitbox)
	paddle.racket_hitbox = racket_hitbox
	paddle.racket_shape = racket_collision

	var sprite := AnimatedSprite2D.new()
	paddle.add_child(sprite)
	paddle.sprite = sprite

	gut_test.add_child_autofree(paddle)
	return paddle
