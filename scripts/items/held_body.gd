class_name HeldBody
extends RigidBody2D

enum Phase { LIFTING, HELD }

const HELD_BODY_SCENE: PackedScene = preload("res://scenes/items/held_body.tscn")

## Grab hit-box radius multiplier on the collision shape.
@export_range(1.0, 4.0, 0.1) var press_hitbox_inflation: float = 2.4
@export var press_collision: CollisionShape2D

var phase: Phase = Phase.LIFTING
var ball_key: String = ""


static func make_for(definition: BallDefinition, key: String, collision_shape: Shape2D) -> HeldBody:
	if definition == null or collision_shape == null:
		return null
	var body: HeldBody = HELD_BODY_SCENE.instantiate()
	body.name = "HeldBody_%s" % key
	body.ball_key = key
	var collision: CollisionShape2D = body.get_node("Collision")
	# Per-instance shape so expansion-ring inflation cannot leak across held bodies.
	collision.shape = collision_shape.duplicate()
	body._configure_press_shape(collision_shape)

	if definition.art != null:
		var art_holder: Node2D = Node2D.new()
		art_holder.name = "ArtHolder"
		art_holder.add_child(definition.art.instantiate())
		body.add_child(art_holder)

	return body


func mark_held() -> void:
	phase = Phase.HELD


func _configure_press_shape(collision_shape: Shape2D) -> void:
	if press_collision == null or collision_shape == null:
		return
	var inflated: Shape2D = collision_shape.duplicate()
	if inflated is CircleShape2D:
		(inflated as CircleShape2D).radius *= press_hitbox_inflation
	elif inflated is RectangleShape2D:
		(inflated as RectangleShape2D).size *= press_hitbox_inflation
	elif inflated is CapsuleShape2D:
		var cap: CapsuleShape2D = inflated
		cap.radius *= press_hitbox_inflation
		cap.height *= press_hitbox_inflation
	press_collision.shape = inflated
