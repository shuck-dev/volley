class_name HeldBody
extends RigidBody2D

signal pressed(body: HeldBody)

enum Phase { LIFTING, HELD, LOOSE }

const HELD_BODY_SCENE: PackedScene = preload("res://scenes/items/held_body.tscn")

@export_range(0.0, 4.0, 0.05) var loose_gravity_scale: float = 1.0
## Press hit-box radius multiplier on the at-rest shape; loose bodies get a generous press target.
@export_range(1.0, 4.0, 0.1) var press_hitbox_inflation: float = 2.4
@export var press_area: Area2D
@export var press_collision: CollisionShape2D

var phase: Phase = Phase.LIFTING
var item_key: String = ""


static func make_for(definition: ItemDefinition, item_key: String) -> HeldBody:
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
	if press_area != null and not press_area.input_event.is_connected(_on_press_input_event):
		press_area.input_event.connect(_on_press_input_event)


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
	collision_layer = 1
	collision_mask = 1
	linear_velocity = release_velocity
	_enable_press_area(true)


func mark_held() -> void:
	phase = Phase.HELD


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


func _enable_press_area(enabled: bool) -> void:
	if press_area == null:
		return
	press_area.input_pickable = enabled
	press_area.monitoring = enabled
	press_area.monitorable = enabled


func _on_press_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if phase != Phase.LOOSE:
		return
	if not (event is InputEventMouseButton):
		return
	var mouse_button: InputEventMouseButton = event
	if mouse_button.button_index != MOUSE_BUTTON_LEFT:
		return
	if not mouse_button.pressed:
		return
	pressed.emit(self)
