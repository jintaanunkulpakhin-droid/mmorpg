@tool
extends StaticBody3D
## Small decorations: barrels, crates, benches, flower beds, bushes, signposts.

@export_enum("barrel", "crate", "bench", "flowers", "bush", "signpost") var kind := "barrel":
	set(value):
		kind = value
		_rebuild()
@export var color := Color("#f4b6cb"):
	set(value):
		color = value
		_rebuild()
## Text for signposts.
@export var text := "":
	set(value):
		text = value
		_rebuild()

const WOOD := Color("#b8642a")
const WOOD_DARK := Color("#8a4b1e")


func _ready() -> void:
	_rebuild()


func _rebuild() -> void:
	if not is_inside_tree():
		return
	ToonKit.clear_children(self)
	match kind:
		"barrel":
			ToonKit.add_shape(self, "cylinder", Vector3(0.7, 0.9, 0.7), Vector3(0, 0.45, 0), WOOD, Vector3.ZERO, false, 10)
			for y in [0.2, 0.7]:
				ToonKit.add_shape(self, "cylinder", Vector3(0.74, 0.07, 0.74), Vector3(0, y, 0), WOOD_DARK, Vector3.ZERO, false, 10)
			ToonKit.add_cylinder_collider(self, 0.36, 0.9, Vector3(0, 0.45, 0))
		"crate":
			ToonKit.add_shape(self, "box", Vector3(0.7, 0.6, 0.7), Vector3(0, 0.3, 0), Color("#d9a066"))
			ToonKit.add_shape(self, "box", Vector3(0.74, 0.1, 0.74), Vector3(0, 0.55, 0), WOOD)
			ToonKit.add_shape(self, "box", Vector3(0.74, 0.1, 0.74), Vector3(0, 0.05, 0), WOOD)
			ToonKit.add_box_collider(self, Vector3(0.7, 0.6, 0.7), Vector3(0, 0.3, 0))
		"bench":
			ToonKit.add_shape(self, "box", Vector3(1.8, 0.1, 0.5), Vector3(0, 0.45, 0), WOOD)
			ToonKit.add_shape(self, "box", Vector3(1.8, 0.35, 0.08), Vector3(0, 0.75, -0.22), WOOD, Vector3(-8, 0, 0))
			for x in [-0.75, 0.75]:
				ToonKit.add_shape(self, "box", Vector3(0.1, 0.45, 0.45), Vector3(x, 0.22, 0), Color("#4a3220"))
			ToonKit.add_box_collider(self, Vector3(1.8, 0.9, 0.55), Vector3(0, 0.45, 0))
		"flowers":
			ToonKit.add_shape(self, "box", Vector3(2.0, 0.25, 0.7), Vector3(0, 0.12, 0), Color("#bba693"))
			ToonKit.add_shape(self, "box", Vector3(1.85, 0.08, 0.55), Vector3(0, 0.26, 0), Color("#6b3b22"))
			for i in 9:
				var c := color if i % 3 != 1 else Color("#fbefcb")
				var p := Vector3(-0.8 + i * 0.2, 0.38 + (i % 2) * 0.05, -0.12 + (i % 2) * 0.24)
				ToonKit.add_shape(self, "sphere", Vector3(0.18, 0.15, 0.18), p, c, Vector3.ZERO, false, 7)
				ToonKit.add_shape(self, "sphere", Vector3(0.14, 0.12, 0.14), p - Vector3(0.08, 0.08, -0.05), Color("#6fb3a8"), Vector3.ZERO, false, 6)
			ToonKit.add_box_collider(self, Vector3(2.0, 0.5, 0.7), Vector3(0, 0.25, 0))
		"bush":
			ToonKit.add_shape(self, "sphere", Vector3(1.1, 0.8, 1.0), Vector3(0, 0.38, 0), Color("#7cc06a"), Vector3.ZERO, false, 8)
			ToonKit.add_shape(self, "sphere", Vector3(0.7, 0.6, 0.7), Vector3(0.35, 0.55, 0.1), Color("#8fca76"), Vector3.ZERO, false, 7)
			for i in 3:
				ToonKit.add_shape(self, "sphere", Vector3(0.12, 0.12, 0.12), Vector3(-0.3 + i * 0.3, 0.6 + (i % 2) * 0.12, 0.4), color, Vector3.ZERO, false, 6)
			ToonKit.add_cylinder_collider(self, 0.5, 0.8, Vector3(0, 0.4, 0))
		"signpost":
			ToonKit.add_shape(self, "box", Vector3(0.14, 1.6, 0.14), Vector3(0, 0.8, 0), WOOD_DARK)
			ToonKit.add_shape(self, "box", Vector3(1.7, 0.45, 0.08), Vector3(0, 1.4, 0.08), Color("#f3d27a"))
			ToonKit.add_shape(self, "prism", Vector3(0.45, 0.3, 0.08), Vector3(0.95, 1.4, 0.08), Color("#f3d27a"), Vector3(0, 0, -90))
			var label := Label3D.new()
			label.text = text
			label.font_size = 48
			label.pixel_size = 0.004
			label.modulate = Color("#4a3220")
			label.outline_size = 0
			label.position = Vector3(0, 1.4, 0.13)
			add_child(label)
			ToonKit.add_cylinder_collider(self, 0.15, 1.6, Vector3(0, 0.8, 0))
