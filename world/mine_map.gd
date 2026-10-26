@tool
extends StaticBody3D
## The dark mine test map: stone floor, rock walls, red steel girders,
## a rail track, warning barriers, lamps and glowing crystals.
## Everything is built from code with ToonKit shapes when the scene loads.
##
## The layout lives in the lists below, so you can move things around by
## changing numbers. The minimap reads the same lists.

const HALF_SIZE := 18.0  # the map goes from -18 to 18 on X and Z

const ROCK_FLOOR_SHADER := preload("res://shaders/rock_floor.gdshader")
const ROCK := Color("#4a423b")
const ROCK_LIGHT := Color("#655a4f")
const GIRDER := Color("#9e2228")
const GIRDER_DARK := Color("#6e161b")
const RAIL := Color("#8c8f96")
const SLEEPER := Color("#4a3322")
const STRIPE_YELLOW := Color("#e8b422")
const STRIPE_BLACK := Color("#1d1b1c")
const LAMP_GLOW := Color("#ffcf7a")
const CRYSTAL := Color("#5fd4ff")

## Girder frames: [x, z, turned 90 degrees?]
const GIRDERS := [
	[-9.0, -10.0, false], [-1.0, -10.0, false], [7.0, -10.0, false],
	[-12.0, 2.0, true], [12.0, 0.0, true], [-4.0, 9.0, false], [6.0, 10.0, false],
]
## Lamps: [x, z]
const LAMPS := [[-14.0, -6.0], [3.0, -12.5], [14.5, 7.0], [-6.0, 13.5], [0.5, 2.5]]
## Warning barriers: [x, z, angle in degrees]
const BARRIERS := [[-3.0, 5.0, 0.0], [-0.8, 5.0, 0.0], [9.0, -4.0, 90.0]]
## Blue crystal clusters: [x, z]
const CRYSTALS := [[-15.0, -14.0], [15.0, -15.0], [-15.5, 14.5], [10.0, 15.0], [15.5, -3.0]]
## Rail track: from z = -HALF_SIZE to HALF_SIZE at this x.
const RAIL_X := 4.0


func _ready() -> void:
	ToonKit.clear_children(self)
	_build_floor()
	_build_walls()
	_build_rails()
	for g in GIRDERS:
		_build_girder(Vector3(g[0], 0, g[1]), 90.0 if g[2] else 0.0)
	for l in LAMPS:
		_build_lamp(Vector3(l[0], 0, l[1]))
	for b in BARRIERS:
		_build_barrier(Vector3(b[0], 0, b[1]), b[2])
	for c in CRYSTALS:
		_build_crystals(Vector3(c[0], 0, c[1]))
	_build_rocks()


func _build_floor() -> void:
	var mi := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(HALF_SIZE * 2.0 + 8.0, HALF_SIZE * 2.0 + 8.0)
	mi.mesh = plane
	var mat := ShaderMaterial.new()
	mat.shader = ROCK_FLOOR_SHADER
	mi.material_override = mat
	add_child(mi)
	ToonKit.add_box_collider(self, Vector3(HALF_SIZE * 2.0 + 8.0, 0.2, HALF_SIZE * 2.0 + 8.0), Vector3(0, -0.1, 0))


func _build_walls() -> void:
	# A ring of lumpy rock around the edge. Lower at the front (south)
	# so the camera can always see the player.
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var step := 2.4
	var x := -HALF_SIZE - 1.0
	while x <= HALF_SIZE + 1.0:
		_rock_lump(Vector3(x, 0, -HALF_SIZE - 1.2), rng, 3.2)
		_rock_lump(Vector3(x, 0, HALF_SIZE + 1.2), rng, 1.0)
		_rock_lump(Vector3(-HALF_SIZE - 1.2, 0, x), rng, 2.6)
		_rock_lump(Vector3(HALF_SIZE + 1.2, 0, x), rng, 2.6)
		x += step
	ToonKit.add_box_collider(self, Vector3(HALF_SIZE * 2.0, 4, 1), Vector3(0, 2, -HALF_SIZE - 0.5))
	ToonKit.add_box_collider(self, Vector3(HALF_SIZE * 2.0, 4, 1), Vector3(0, 2, HALF_SIZE + 0.5))
	ToonKit.add_box_collider(self, Vector3(1, 4, HALF_SIZE * 2.0), Vector3(-HALF_SIZE - 0.5, 2, 0))
	ToonKit.add_box_collider(self, Vector3(1, 4, HALF_SIZE * 2.0), Vector3(HALF_SIZE + 0.5, 2, 0))


func _rock_lump(pos: Vector3, rng: RandomNumberGenerator, height: float) -> void:
	var h := height * rng.randf_range(0.7, 1.3)
	var color := ROCK if rng.randf() < 0.6 else ROCK_LIGHT
	ToonKit.add_shape(self, "sphere", Vector3(3.2, h * 2.0, 3.0), pos, color,
			Vector3(0, rng.randf_range(0, 180), rng.randf_range(-8, 8)), true, 7)


func _build_rails() -> void:
	var length := HALF_SIZE * 2.0
	for side in [-0.55, 0.55]:
		ToonKit.add_shape(self, "box", Vector3(0.1, 0.12, length), Vector3(RAIL_X + side, 0.16, 0), RAIL)
	var z := -HALF_SIZE + 0.4
	while z < HALF_SIZE:
		ToonKit.add_shape(self, "box", Vector3(1.6, 0.1, 0.32), Vector3(RAIL_X, 0.05, z), SLEEPER)
		z += 0.9
	# A little mine cart parked on the track.
	var cart := Vector3(RAIL_X, 0, -4.5)
	ToonKit.add_shape(self, "box", Vector3(1.3, 0.75, 1.7), cart + Vector3(0, 0.6, 0), Color("#5b5f66"), Vector3.ZERO, true)
	ToonKit.add_shape(self, "box", Vector3(1.1, 0.2, 1.5), cart + Vector3(0, 0.9, 0), Color("#2b2c30"))
	for wheel in [Vector3(-0.55, 0.2, -0.5), Vector3(0.55, 0.2, -0.5), Vector3(-0.55, 0.2, 0.5), Vector3(0.55, 0.2, 0.5)]:
		ToonKit.add_shape(self, "cylinder", Vector3(0.36, 0.12, 0.36), cart + wheel, STRIPE_BLACK, Vector3(0, 0, 90), false, 10)
	for ore in [Vector3(-0.25, 1.05, -0.3), Vector3(0.2, 1.08, 0.2), Vector3(0.0, 1.0, 0.5)]:
		ToonKit.add_shape(self, "sphere", Vector3(0.42, 0.3, 0.38), cart + ore, Color("#8a6b4e"), Vector3.ZERO, false, 6)
	ToonKit.add_box_collider(self, Vector3(1.3, 1.2, 1.7), cart + Vector3(0, 0.6, 0))


func _build_girder(pos: Vector3, angle: float) -> void:
	var g := Node3D.new()
	add_child(g)
	g.position = pos
	g.rotation_degrees.y = angle
	var width := 4.4
	var height := 4.2
	for side in [-1.0, 1.0]:
		var x: float = side * width * 0.5
		ToonKit.add_shape(g, "box", Vector3(0.38, height, 0.38), Vector3(x, height * 0.5, 0), GIRDER, Vector3.ZERO, true)
		ToonKit.add_shape(g, "box", Vector3(0.6, 0.18, 0.6), Vector3(x, 0.09, 0), GIRDER_DARK)
		ToonKit.add_box_collider(self, Vector3(0.5, 2.0, 0.5), pos + Vector3(x, 1.0, 0).rotated(Vector3.UP, deg_to_rad(angle)))
	ToonKit.add_shape(g, "box", Vector3(width + 0.6, 0.42, 0.42), Vector3(0, height, 0), GIRDER, Vector3.ZERO, true)
	ToonKit.add_shape(g, "box", Vector3(width, 0.16, 0.2), Vector3(0, height - 0.55, 0), GIRDER_DARK)
	# Corner braces.
	for side in [-1.0, 1.0]:
		ToonKit.add_shape(g, "box", Vector3(0.95, 0.14, 0.18), Vector3(side * (width * 0.5 - 0.45), height - 0.45, 0),
				GIRDER_DARK, Vector3(0, 0, side * 45.0))


func _build_lamp(pos: Vector3) -> void:
	ToonKit.add_shape(self, "box", Vector3(0.18, 2.6, 0.18), pos + Vector3(0, 1.3, 0), Color("#3a2a1c"))
	ToonKit.add_shape(self, "box", Vector3(0.7, 0.12, 0.12), pos + Vector3(0.28, 2.55, 0), Color("#3a2a1c"))
	var bulb := ToonKit.add_shape(self, "cylinder", Vector3(0.32, 0.42, 0.28), pos + Vector3(0.55, 2.2, 0), LAMP_GLOW, Vector3.ZERO, false, 8)
	bulb.material_override = _glow_material(LAMP_GLOW, 2.0)
	ToonKit.add_shape(self, "cone", Vector3(0.45, 0.2, 0), pos + Vector3(0.55, 2.5, 0), Color("#2a2420"), Vector3.ZERO, false, 8)
	var light := OmniLight3D.new()
	light.light_color = Color("#ffb75e")
	light.light_energy = 3.5
	light.omni_range = 9.0
	light.omni_attenuation = 1.4
	light.position = pos + Vector3(0.55, 2.0, 0)
	add_child(light)
	ToonKit.add_box_collider(self, Vector3(0.3, 2.0, 0.3), pos + Vector3(0, 1.0, 0))


func _build_barrier(pos: Vector3, angle: float) -> void:
	var b := Node3D.new()
	add_child(b)
	b.position = pos
	b.rotation_degrees.y = angle
	for leg in [-0.85, 0.85]:
		ToonKit.add_shape(b, "box", Vector3(0.12, 0.8, 0.5), Vector3(leg, 0.4, 0), STRIPE_BLACK)
	# Yellow and black stripes on the board.
	for i in 8:
		var c := STRIPE_YELLOW if i % 2 == 0 else STRIPE_BLACK
		ToonKit.add_shape(b, "box", Vector3(0.25, 0.32, 0.08), Vector3(-0.875 + i * 0.25, 0.72, 0), c)
	# Little spikes on top, like the barriers in the video.
	for i in 5:
		ToonKit.add_shape(b, "cone", Vector3(0.12, 0.25, 0), Vector3(-0.8 + i * 0.4, 1.0, 0), RAIL, Vector3.ZERO, false, 5)
	ToonKit.add_box_collider(self, Vector3(2.0, 1.0, 0.5), pos + Vector3(0, 0.5, 0), Vector3(0, angle, 0))


func _build_crystals(pos: Vector3) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(pos.x * 31.0 + pos.z * 17.0)
	for i in 5:
		var offset := Vector3(rng.randf_range(-0.7, 0.7), 0, rng.randf_range(-0.7, 0.7))
		var h := rng.randf_range(0.7, 1.7)
		var crystal := ToonKit.add_shape(self, "cone", Vector3(0.35, h, 0), pos + offset + Vector3(0, h * 0.5, 0),
				CRYSTAL, Vector3(rng.randf_range(-20, 20), 0, rng.randf_range(-20, 20)), false, 5)
		crystal.material_override = _glow_material(CRYSTAL, 1.6)
	var light := OmniLight3D.new()
	light.light_color = CRYSTAL
	light.light_energy = 1.4
	light.omni_range = 4.5
	light.position = pos + Vector3(0, 1.0, 0)
	add_child(light)
	ToonKit.add_cylinder_collider(self, 0.9, 1.6, pos + Vector3(0, 0.8, 0))


func _build_rocks() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 21
	for i in 45:
		var pos := Vector3(rng.randf_range(-HALF_SIZE + 1, HALF_SIZE - 1), 0, rng.randf_range(-HALF_SIZE + 1, HALF_SIZE - 1))
		if absf(pos.x - RAIL_X) < 1.5 or pos.length() < 4.0:
			continue
		var s := rng.randf_range(0.2, 0.55)
		ToonKit.add_shape(self, "sphere", Vector3(s * 1.6, s, s * 1.3), pos + Vector3(0, s * 0.3, 0),
				ROCK_LIGHT, Vector3(0, rng.randf_range(0, 180), 0), false, 6)


## A material that glows by itself (lamps, crystals). The glow setting in
## the scene's environment makes these bleed light around their edges.
func _glow_material(color: Color, strength: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = strength
	return mat
