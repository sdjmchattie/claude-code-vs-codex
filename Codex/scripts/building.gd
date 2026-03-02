extends Node2D
class_name Building

@export var size: Vector2 = Vector2(80.0, 220.0)
@export var building_color: Color = Color("3a5879")

signal damaged

@onready var sprite: Sprite2D = $Sprite2D
@onready var body: StaticBody2D = $StaticBody2D

var _image: Image
var _texture: ImageTexture

func _ready() -> void:
	_rebuild_bitmap()

func configure(new_size: Vector2, color: Color) -> void:
	size = new_size
	building_color = color
	if is_inside_tree():
		_rebuild_bitmap()

func apply_crater(world_pos: Vector2, radius: float) -> void:
	var local_center: Vector2 = to_local(world_pos)
	var min_x: int = max(0, int(floor(local_center.x - radius)))
	var max_x: int = min(int(size.x) - 1, int(ceil(local_center.x + radius)))
	var min_y: int = max(0, int(floor(local_center.y - radius)))
	var max_y: int = min(int(size.y) - 1, int(ceil(local_center.y + radius)))
	if min_x >= max_x or min_y >= max_y:
		return

	var changed: bool = false
	for y in range(min_y, max_y + 1):
		for x in range(min_x, max_x + 1):
			var pixel_pos := Vector2(float(x), float(y))
			if pixel_pos.distance_to(local_center) <= radius:
				var px: Color = _image.get_pixel(x, y)
				if px.a > 0.0:
					_image.set_pixel(x, y, Color(0, 0, 0, 0))
					changed = true

	if changed:
		_refresh_visual_and_collision()
		damaged.emit()

func _rebuild_bitmap() -> void:
	_image = Image.create(max(1, int(size.x)), max(1, int(size.y)), false, Image.FORMAT_RGBA8)
	_image.fill(building_color)
	_refresh_visual_and_collision()

func _refresh_visual_and_collision() -> void:
	if _texture == null:
		_texture = ImageTexture.create_from_image(_image)
	else:
		_texture.update(_image)
	sprite.texture = _texture
	sprite.centered = false

	for child in body.get_children():
		child.queue_free()

	var bitmap: BitMap = BitMap.new()
	bitmap.create_from_image_alpha(_image)
	var polygons: Array[PackedVector2Array] = bitmap.opaque_to_polygons(Rect2i(0, 0, _image.get_width(), _image.get_height()), 1.5)
	for poly in polygons:
		if poly.size() < 3:
			continue
		var collision: CollisionPolygon2D = CollisionPolygon2D.new()
		collision.polygon = poly
		body.add_child(collision)
