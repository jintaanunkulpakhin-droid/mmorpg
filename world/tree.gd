@tool
extends StaticBody3D
## A low-poly tree. Pick a kind: round (leafy), pine, or blossom (pink).

@export_enum("round", "pine", "blossom") var kind := "round":
	set(value):
		kind = value
		_rebuild()
@export var height := 1.0:
	set(value):
		height = value
		_rebuild()

const TRUNK := Color("#8a4b1e")


func _ready() -> void:
	_rebuild()


func _rebuild() -> void:
	if not is_inside_tree():
		return
	ToonKit.clear_children(self)
	var s := height
	match kind:
		"pine":
			ToonKit.add_shape(self, "cylinder", Vector3(0.36, 1.0, 0.26) * s, Vector3(0, 0.5 * s, 0), TRUNK, Vector3.ZERO, false, 7)
			var greens := [Color("#3e9b5a"), Color("#4fae68"), Color("#6fc07a")]
			for i in 3:
				var w := (2.4 - i * 0.6) * s
				ToonKit.add_shape(self, "cone", Vector3(w, 1.5 * s, 0), Vector3(0, (1.4 + i * 0.85) * s, 0), greens[i], Vector3.ZERO, false, 8)
		_:
			ToonKit.add_shape(self, "cylinder", Vector3(0.42, 1.6, 0.3) * s, Vector3(0, 0.8 * s, 0), TRUNK, Vector3.ZERO, false, 7)
			var colors := [Color("#7cc06a"), Color("#a8d58a"), Color("#8fca76")]
			if kind == "blossom":
				colors = [Color("#f4b6cb"), Color("#f9d3df"), Color("#eea0bb")]
			ToonKit.add_shape(self, "sphere", Vector3(2.3, 1.9, 2.3) * s, Vector3(0, 2.3 * s, 0), colors[0], Vector3.ZERO, false, 9)
			ToonKit.add_shape(self, "sphere", Vector3(1.5, 1.3, 1.5) * s, Vector3(0.6 * s, 2.9 * s, 0.3 * s), colors[1], Vector3.ZERO, false, 8)
			ToonKit.add_shape(self, "sphere", Vector3(1.4, 1.2, 1.4) * s, Vector3(-0.6 * s, 2.7 * s, -0.4 * s), colors[2], Vector3.ZERO, false, 8)
	ToonKit.add_cylinder_collider(self, 0.3 * s, 2.0 * s, Vector3(0, 1.0 * s, 0))
