@tool
class_name ToonKit
## Helpers that build simple low-poly shapes with the toon shader.
## All placeholder art in this prototype (buildings, props, characters,
## clothes) is made from these shapes, so there are no model files yet.
## Later, real models from Blender can replace them piece by piece.

const TOON_SHADER := preload("res://shaders/toon.gdshader")
const OUTLINE_SHADER := preload("res://shaders/outline.gdshader")

static var _materials := {}


## Returns a shared toon material for a colour (one material per colour).
static func material(color: Color, outline := false) -> ShaderMaterial:
	var key := color.to_html() + ("_o" if outline else "")
	if _materials.has(key):
		return _materials[key]
	var mat := ShaderMaterial.new()
	mat.shader = TOON_SHADER
	mat.set_shader_parameter("albedo", color)
	if outline:
		var line := ShaderMaterial.new()
		line.shader = OUTLINE_SHADER
		mat.next_pass = line
	_materials[key] = mat
	return mat


## Makes a mesh for a shape name. "size" is the full width, height and depth.
## Shapes: box, sphere, capsule, cylinder, cone, prism, torus.
static func make_mesh(shape: String, size: Vector3, segments := 12) -> Mesh:
	match shape:
		"box":
			var box := BoxMesh.new()
			box.size = size
			return box
		"sphere":
			var sphere := SphereMesh.new()
			sphere.radius = 0.5
			sphere.height = 1.0
			sphere.radial_segments = segments
			sphere.rings = maxi(segments / 2, 4)
			return sphere
		"hemisphere":
			var dome := SphereMesh.new()
			dome.radius = 0.5
			dome.height = 0.5
			dome.is_hemisphere = true
			dome.radial_segments = segments
			dome.rings = maxi(segments / 4, 3)
			return dome
		"capsule":
			var capsule := CapsuleMesh.new()
			capsule.radius = size.x * 0.5
			capsule.height = maxf(size.y, size.x)
			capsule.radial_segments = segments
			capsule.rings = 2
			return capsule
		"cylinder", "cone":
			var cyl := CylinderMesh.new()
			cyl.bottom_radius = size.x * 0.5
			cyl.top_radius = 0.0 if shape == "cone" else size.z * 0.5
			cyl.height = size.y
			cyl.radial_segments = segments
			cyl.rings = 1
			return cyl
		"prism":
			var prism := PrismMesh.new()
			prism.size = size
			return prism
		"torus":
			var torus := TorusMesh.new()
			torus.outer_radius = size.x * 0.5
			torus.inner_radius = size.x * 0.5 - size.y
			torus.rings = segments
			torus.ring_segments = 6
			return torus
	push_error("ToonKit: unknown shape '%s'" % shape)
	return BoxMesh.new()


## Adds a coloured shape to "parent" and returns it.
## For spheres and hemispheres, "size" stretches the shape (so they can be eggs or discs).
## For cylinders, size.x is the bottom width and size.z the top width.
static func add_shape(parent: Node, shape: String, size: Vector3, pos: Vector3, color: Color,
		rot_deg := Vector3.ZERO, outline := false, segments := 12) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = make_mesh(shape, size, segments)
	mi.material_override = material(color, outline)
	mi.position = pos
	mi.rotation_degrees = rot_deg
	if shape == "sphere" or shape == "hemisphere":
		mi.scale = size
	elif shape == "capsule" and size.x > 0.0:
		mi.scale = Vector3(1.0, 1.0, size.z / size.x)
	parent.add_child(mi)
	return mi


## Adds an invisible box that the player bumps into.
static func add_box_collider(body: CollisionObject3D, size: Vector3, pos: Vector3, rot_deg := Vector3.ZERO) -> void:
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	shape.position = pos
	shape.rotation_degrees = rot_deg
	body.add_child(shape)


## Adds an invisible cylinder that the player bumps into.
static func add_cylinder_collider(body: CollisionObject3D, radius: float, height: float, pos: Vector3) -> void:
	var shape := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = radius
	cyl.height = height
	shape.shape = cyl
	shape.position = pos
	body.add_child(shape)


## Removes everything a prop script made, so it can be built again.
static func clear_children(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()
