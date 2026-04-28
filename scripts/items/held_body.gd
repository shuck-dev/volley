class_name HeldBody
extends RigidBody2D

enum Phase { LIFTING, HELD, LOOSE }

@export_range(0.0, 4.0, 0.05) var loose_gravity_scale: float = 1.0

var phase: Phase = Phase.LIFTING
var item_key: String = ""


static func make_for(definition: ItemDefinition, item_key: String) -> HeldBody:
	var body: HeldBody = HeldBody.new()
	body.name = "HeldBody_%s" % item_key
	body.item_key = item_key
	body.gravity_scale = 0.0
	body.lock_rotation = true
	body.linear_damp = 1.0
	body.contact_monitor = false
	body.freeze = true
	body.freeze_mode = RigidBody2D.FREEZE_MODE_KINEMATIC
	body.input_pickable = false
	# Collision stays disabled until go_loose so the body cannot push the cursor-driven motion around.
	body.collision_layer = 0
	body.collision_mask = 0

	var collision: CollisionShape2D = CollisionShape2D.new()
	collision.name = "Collision"
	if definition != null and definition.at_rest_shape != null:
		collision.shape = definition.at_rest_shape
	else:
		var fallback: CircleShape2D = CircleShape2D.new()
		fallback.radius = 12.0
		collision.shape = fallback
	body.add_child(collision)

	if definition != null and definition.art != null:
		var art_holder: Node2D = Node2D.new()
		art_holder.name = "ArtHolder"
		art_holder.add_child(definition.art.instantiate())
		body.add_child(art_holder)

	return body


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


func mark_held() -> void:
	phase = Phase.HELD
