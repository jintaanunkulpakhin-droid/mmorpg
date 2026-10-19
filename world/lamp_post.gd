@tool
extends StaticBody3D
## A street lamp. Bunting strings hang from the top of these.

const IRON := Color("#4a3220")
const GLOW := Color("#ffe48a")


func _ready() -> void:
	ToonKit.clear_children(self)
	ToonKit.add_shape(self, "cylinder", Vector3(0.45, 0.3, 0.35), Vector3(0, 0.15, 0), IRON, Vector3.ZERO, false, 8)
	ToonKit.add_shape(self, "cylinder", Vector3(0.12, 3.0, 0.1), Vector3(0, 1.6, 0), IRON, Vector3.ZERO, false, 6)
	ToonKit.add_shape(self, "cylinder", Vector3(0.3, 0.35, 0.42), Vector3(0, 3.2, 0), GLOW, Vector3.ZERO, false, 6)
	ToonKit.add_shape(self, "cone", Vector3(0.6, 0.3, 0), Vector3(0, 3.5, 0), IRON, Vector3.ZERO, false, 6)
	ToonKit.add_shape(self, "sphere", Vector3(0.1, 0.1, 0.1), Vector3(0, 3.7, 0), Color("#e3b34e"), Vector3.ZERO, false, 6)
	ToonKit.add_cylinder_collider(self, 0.2, 3.6, Vector3(0, 1.8, 0))
