@tool
extends StaticBody3D
## The ground: grass, the tiled town square, sandy paths, and invisible walls
## at the edge of town so the player can't walk off the map.

@export var town_half_size := 26.0
@export var plaza_half_size := 9.0
@export var path_width := 3.2

const GRASS := Color("#a8d58a")
const GRASS_DARK := Color("#9ccd7f")
const PATH := Color("#e8d3a2")
const TILE_A := Color("#f3e3c3")
const TILE_B := Color("#ecbfb4")


func _ready() -> void:
	ToonKit.clear_children(self)
	var grass := ToonKit.add_shape(self, "box", Vector3(120, 1, 120), Vector3(0, -0.5, 0), GRASS)
	grass.material_override = _checker(GRASS, GRASS_DARK, 4.0)
	ToonKit.add_box_collider(self, Vector3(120, 1, 120), Vector3(0, -0.5, 0))

	var plaza := ToonKit.add_shape(self, "box", Vector3(plaza_half_size * 2, 0.04, plaza_half_size * 2), Vector3(0, 0.0, 0), TILE_A)
	plaza.material_override = _checker(TILE_A, TILE_B, 0.6)
	ToonKit.add_shape(self, "box", Vector3(plaza_half_size * 2 + 0.5, 0.04, plaza_half_size * 2 + 0.5), Vector3(0, -0.01, 0), Color("#bba693"))

	var length := town_half_size - plaza_half_size + 2.0
	var middle := plaza_half_size + length * 0.5
	for dir in [Vector3.FORWARD, Vector3.BACK, Vector3.LEFT, Vector3.RIGHT]:
		var size := Vector3(path_width, 0.03, length) if dir.x == 0 else Vector3(length, 0.03, path_width)
		ToonKit.add_shape(self, "box", size, dir * middle, PATH)

	# Grass tufts and tiny flowers, placed the same way every time.
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var flower_colors := [Color("#fbefcb"), Color("#f4b6cb"), Color("#f3d27a")]
	for i in 160:
		var p := Vector3(rng.randf_range(-town_half_size, town_half_size), 0, rng.randf_range(-town_half_size, town_half_size))
		if absf(p.x) < plaza_half_size + 1.0 and absf(p.z) < plaza_half_size + 1.0:
			continue
		if absf(p.x) < path_width or absf(p.z) < path_width:
			continue
		if i % 3 == 0:
			ToonKit.add_shape(self, "sphere", Vector3(0.12, 0.1, 0.12), p + Vector3(0, 0.06, 0), flower_colors[i % 3 if i % 2 == 0 else 1], Vector3.ZERO, false, 6)
		else:
			ToonKit.add_shape(self, "cone", Vector3(0.14, 0.22, 0), p + Vector3(0, 0.1, 0), Color("#7cc06a"), Vector3(0, 0, rng.randf_range(-15, 15)), false, 4)

	# Invisible walls around the edge of town.
	var edge := town_half_size + 0.5
	for dir in [Vector3.FORWARD, Vector3.BACK, Vector3.LEFT, Vector3.RIGHT]:
		var size := Vector3(edge * 2, 6, 1) if dir.x == 0 else Vector3(1, 6, edge * 2)
		ToonKit.add_box_collider(self, size, dir * edge + Vector3(0, 3, 0))


func _checker(a: Color, b: Color, cell: float) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = ToonKit.TOON_SHADER
	mat.set_shader_parameter("albedo", a)
	mat.set_shader_parameter("use_checker", true)
	mat.set_shader_parameter("checker_color", b)
	mat.set_shader_parameter("checker_size", cell)
	return mat
