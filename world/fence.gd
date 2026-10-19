@tool
extends StaticBody3D
## A wooden fence running along the red X arrow for "length" metres.

@export var length := 10.0:
	set(value):
		length = value
		_rebuild()

const WOOD := Color("#c98a55")
const WOOD_DARK := Color("#8a4b1e")


func _ready() -> void:
	_rebuild()


func _rebuild() -> void:
	if not is_inside_tree():
		return
	ToonKit.clear_children(self)
	var posts := maxi(int(length / 1.5), 1)
	for i in posts + 1:
		var x := i * length / posts
		ToonKit.add_shape(self, "box", Vector3(0.16, 1.0, 0.16), Vector3(x, 0.5, 0), WOOD_DARK)
		ToonKit.add_shape(self, "prism", Vector3(0.16, 0.12, 0.16), Vector3(x, 1.06, 0), WOOD_DARK)
	for y in [0.4, 0.75]:
		ToonKit.add_shape(self, "box", Vector3(length, 0.1, 0.06), Vector3(length * 0.5, y, 0.07), WOOD)
	ToonKit.add_box_collider(self, Vector3(length, 1.2, 0.4), Vector3(length * 0.5, 0.6, 0))
