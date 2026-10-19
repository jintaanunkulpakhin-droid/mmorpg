## Builds the test level: brush-stroke platforms on rice paper, with ink-wash
## mountains far behind. Add, move or resize platforms in the list below.
extends Node2D

const PLATFORM := preload("res://art/world/platform.png")
const MOUNTAINS := preload("res://art/world/mountains.png")
const GROUND_WASH := Color(0.88, 0.85, 0.79)

## Each platform: x, y of its top-left corner and its width, in pixels.
## The first one is the ground. The others can be jumped onto from below.
@export var platforms: Array[Rect2] = [
	Rect2(-400, 600, 4400, 0),
	Rect2(380, 470, 260, 0),
	Rect2(760, 360, 220, 0),
	Rect2(1120, 470, 300, 0),
	Rect2(1540, 330, 240, 0),
	Rect2(1900, 220, 200, 0),
	Rect2(2300, 420, 360, 0),
	Rect2(2850, 300, 260, 0),
]


func _ready() -> void:
	_add_mountains()
	for i in platforms.size():
		_add_platform(platforms[i], i == 0)
	# Invisible walls at both ends of the ground, so you can't walk off the world.
	var ground := platforms[0]
	_add_wall(ground.position.x)
	_add_wall(ground.end.x)


func _add_mountains() -> void:
	var layer := Parallax2D.new()
	layer.name = "Mountains"
	layer.scroll_scale = Vector2(0.25, 0.1)
	layer.z_index = -10
	var sprite := Sprite2D.new()
	sprite.texture = MOUNTAINS
	sprite.centered = false
	sprite.scale = Vector2(0.5, 0.5)
	sprite.position = Vector2(-400, 160)
	layer.add_child(sprite)
	add_child(layer)


func _add_platform(rect: Rect2, is_ground: bool) -> void:
	var body := StaticBody2D.new()
	body.position = rect.position
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = Vector2(rect.size.x, 24)
	shape.shape = box
	shape.position = Vector2(rect.size.x / 2.0, 12)
	shape.one_way_collision = not is_ground
	body.add_child(shape)

	if is_ground:
		# Darker paper under the ground line. It also hides the bottom of the mountains.
		var wash := ColorRect.new()
		wash.color = GROUND_WASH
		wash.position = Vector2(0, 10)
		wash.size = Vector2(rect.size.x, 800)
		body.add_child(wash)

	var stroke := Sprite2D.new()
	stroke.texture = PLATFORM
	stroke.centered = false
	stroke.scale = Vector2(rect.size.x / PLATFORM.get_width(), 0.5)
	stroke.position = Vector2(0, -6)
	body.add_child(stroke)

	add_child(body)


func _add_wall(x: float) -> void:
	var body := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = Vector2(40, 2000)
	shape.shape = box
	body.position = Vector2(x, 0)
	body.add_child(shape)
	add_child(body)
