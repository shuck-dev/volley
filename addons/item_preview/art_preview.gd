@tool
extends SubViewportContainer

const MIN_PREVIEW_SIZE := Vector2i(48, 48)
const MAX_PREVIEW_SIZE := Vector2i(256, 256)

var _viewport: SubViewport
var _camera: Camera2D
var _current_instance: Node


func _init() -> void:
	custom_minimum_size = Vector2(MIN_PREVIEW_SIZE)
	stretch = true

	_viewport = SubViewport.new()
	_viewport.size = MIN_PREVIEW_SIZE
	_viewport.transparent_bg = true
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_viewport)

	_camera = Camera2D.new()
	_camera.enabled = true
	_viewport.add_child(_camera)


func show_scene(scene: PackedScene) -> void:
	clear_scene()
	if scene == null:
		return
	var instance: Node = scene.instantiate()
	if instance == null:
		return
	_current_instance = instance
	_viewport.add_child(instance)
	_fit_to_content(instance)


func clear_scene() -> void:
	if _current_instance != null and is_instance_valid(_current_instance):
		_viewport.remove_child(_current_instance)
		_current_instance.queue_free()
	_current_instance = null


func _fit_to_content(content: Node) -> void:
	var bounds := _compute_content_bounds(content)
	if bounds.size == Vector2.ZERO:
		_apply_size(MIN_PREVIEW_SIZE)
		_camera.position = Vector2.ZERO
		_camera.zoom = Vector2.ONE
		return

	var actual_size := bounds.size
	var zoom_factor: float = 1.0
	if actual_size.x > MAX_PREVIEW_SIZE.x or actual_size.y > MAX_PREVIEW_SIZE.y:
		zoom_factor = minf(
			float(MAX_PREVIEW_SIZE.x) / actual_size.x, float(MAX_PREVIEW_SIZE.y) / actual_size.y
		)

	var display_size: Vector2 = actual_size * zoom_factor
	var final_size := Vector2i(
		int(maxf(display_size.x, MIN_PREVIEW_SIZE.x)), int(maxf(display_size.y, MIN_PREVIEW_SIZE.y))
	)

	_apply_size(final_size)
	_camera.position = bounds.get_center()
	_camera.zoom = Vector2(zoom_factor, zoom_factor)


func _apply_size(size_pixels: Vector2i) -> void:
	_viewport.size = size_pixels
	custom_minimum_size = Vector2(size_pixels)
	size = Vector2(size_pixels)


## Bounding box of rendered content. Handles Sprite2D, AnimatedSprite2D,
## Polygon2D, Line2D; extend `_get_node_rect` for anything else that needs framing.
func _compute_content_bounds(root: Node) -> Rect2:
	var bounds := Rect2()
	var has_any := false
	var queue: Array = [root]
	while queue.size() > 0:
		var node: Node = queue.pop_front()
		var rect := _get_node_rect(node)
		if rect.size != Vector2.ZERO:
			if has_any:
				bounds = bounds.merge(rect)
			else:
				bounds = rect
				has_any = true
		for child in node.get_children():
			queue.append(child)
	return bounds


func _get_node_rect(node: Node) -> Rect2:
	if node is Sprite2D:
		return _sprite2d_rect(node as Sprite2D)
	if node is AnimatedSprite2D:
		return _animated_sprite2d_rect(node as AnimatedSprite2D)
	if node is Polygon2D:
		return _polygon2d_rect(node as Polygon2D)
	if node is Line2D:
		return _line2d_rect(node as Line2D)
	return Rect2()


func _sprite2d_rect(sprite: Sprite2D) -> Rect2:
	if sprite.texture == null:
		return Rect2()
	return _transform_rect(sprite.get_rect(), sprite.global_transform)


func _animated_sprite2d_rect(sprite: AnimatedSprite2D) -> Rect2:
	if sprite.sprite_frames == null:
		return Rect2()
	var texture := sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
	if texture == null:
		return Rect2()
	var texture_size: Vector2 = texture.get_size()
	var local_rect := Rect2(-texture_size * 0.5, texture_size)
	return _transform_rect(local_rect, sprite.global_transform)


func _polygon2d_rect(polygon_node: Polygon2D) -> Rect2:
	if polygon_node.polygon.size() == 0:
		return Rect2()
	var min_point: Vector2 = polygon_node.polygon[0]
	var max_point: Vector2 = min_point
	for point: Vector2 in polygon_node.polygon:
		min_point = min_point.min(point)
		max_point = max_point.max(point)
	var local_rect := Rect2(min_point, max_point - min_point)
	return _transform_rect(local_rect, polygon_node.global_transform)


func _line2d_rect(line: Line2D) -> Rect2:
	if line.points.size() == 0:
		return Rect2()
	var min_point: Vector2 = line.points[0]
	var max_point: Vector2 = min_point
	for point: Vector2 in line.points:
		min_point = min_point.min(point)
		max_point = max_point.max(point)
	var half_width: float = line.width * 0.5
	var padding := Vector2(half_width, half_width)
	var local_rect := Rect2(min_point - padding, max_point - min_point + padding * 2.0)
	return _transform_rect(local_rect, line.global_transform)


func _transform_rect(rect: Rect2, transform: Transform2D) -> Rect2:
	var top_left: Vector2 = transform * rect.position
	var top_right: Vector2 = transform * Vector2(rect.end.x, rect.position.y)
	var bottom_left: Vector2 = transform * Vector2(rect.position.x, rect.end.y)
	var bottom_right: Vector2 = transform * rect.end
	var min_point: Vector2 = top_left.min(top_right).min(bottom_left).min(bottom_right)
	var max_point: Vector2 = top_left.max(top_right).max(bottom_left).max(bottom_right)
	return Rect2(min_point, max_point - min_point)
