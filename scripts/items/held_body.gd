class_name HeldBody
extends RigidBody2D

signal grabbed(body: HeldBody)

enum Phase { LIFTING, HELD, LOOSE }

const HELD_BODY_SCENE: PackedScene = preload("res://scenes/items/held_body.tscn")

@export_range(0.0, 4.0, 0.05) var loose_gravity_scale: float = 1.0
## Grab hit-box radius multiplier on the at-rest shape; loose bodies get a generous grab target.
@export_range(1.0, 4.0, 0.1) var press_hitbox_inflation: float = 2.4
@export var grab_area: GrabArea
@export var press_collision: CollisionShape2D

var phase: Phase = Phase.LIFTING
var item_key: String = ""


static func make_for(definition: ItemDefinition, item_key: String) -> HeldBody:
	# Equipment without an authored at_rest_shape has no physics body to spawn; refuse rather than crash.
	if definition == null or definition.at_rest_shape == null:
		return null
	var body: HeldBody = HELD_BODY_SCENE.instantiate()
	body.name = "HeldBody_%s" % item_key
	body.item_key = item_key
	var collision: CollisionShape2D = body.get_node("Collision")
	# Per-instance shape so expansion-ring inflation cannot leak across held bodies.
	collision.shape = definition.at_rest_shape.duplicate()
	body._configure_press_shape(definition.at_rest_shape)

	if definition.art != null:
		var art_holder: Node2D = Node2D.new()
		art_holder.name = "ArtHolder"
		art_holder.add_child(definition.art.instantiate())
		body.add_child(art_holder)

	return body


func _ready() -> void:
	if grab_area != null and not grab_area.grabbed.is_connected(_on_grab_area_grabbed):
		grab_area.grabbed.connect(_on_grab_area_grabbed)


# Loose bodies live under the reconciler's ball-host subtree; that subtree is freed on scene reload, which is what cleans them up.
func go_loose(release_velocity: Vector2) -> void:
	phase = Phase.LOOSE
	# Migrate visible scale onto the ArtHolder so the body's collision matches at_rest_shape in world space.
	var pre_loose_scale: Vector2 = scale
	scale = Vector2.ONE
	var art_holder: Node2D = get_node_or_null("ArtHolder") as Node2D
	if art_holder != null:
		art_holder.scale = pre_loose_scale
	freeze = false
	gravity_scale = loose_gravity_scale
	# Layer 2 is the items layer; paddle masks it off during timeout so resting items can't body-block the walk.
	collision_layer = 2
	collision_mask = 1
	linear_velocity = release_velocity
	_enable_grab_area(true)


func mark_held() -> void:
	phase = Phase.HELD


# Reverse of go_loose's scale migration: pull the ArtHolder's visual scale back
# onto the body so the drag controller's lift ease operates on the right number.
func reclaim_scale_from_art_holder() -> void:
	var art_holder: Node2D = get_node_or_null("ArtHolder") as Node2D
	if art_holder == null:
		return
	if art_holder.scale == Vector2.ONE:
		return
	scale = art_holder.scale
	art_holder.scale = Vector2.ONE


func _configure_press_shape(at_rest_shape: Shape2D) -> void:
	if press_collision == null or at_rest_shape == null:
		return
	var inflated: Shape2D = at_rest_shape.duplicate()
	if inflated is CircleShape2D:
		(inflated as CircleShape2D).radius *= press_hitbox_inflation
	elif inflated is RectangleShape2D:
		(inflated as RectangleShape2D).size *= press_hitbox_inflation
	elif inflated is CapsuleShape2D:
		var cap: CapsuleShape2D = inflated
		cap.radius *= press_hitbox_inflation
		cap.height *= press_hitbox_inflation
	press_collision.shape = inflated


func _enable_grab_area(enabled: bool) -> void:
	if grab_area == null:
		return
	grab_area.input_pickable = enabled
	grab_area.monitoring = enabled
	grab_area.monitorable = enabled


func _on_grab_area_grabbed(_area: GrabArea) -> void:
	if phase != Phase.LOOSE:
		return
	grabbed.emit(self)
