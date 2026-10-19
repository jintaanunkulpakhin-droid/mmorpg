@tool
extends StaticBody3D
## A market stall with a striped awning and goods on the counter.

@export var awning_color := Color("#d86a9a"):
	set(value):
		awning_color = value
		_rebuild()
@export var goods_color := Color("#e2384c"):
	set(value):
		goods_color = value
		_rebuild()

const WOOD := Color("#b8642a")
const WOOD_DARK := Color("#8a4b1e")
const CREAM := Color("#fbefcb")


func _ready() -> void:
	_rebuild()


func _rebuild() -> void:
	if not is_inside_tree():
		return
	ToonKit.clear_children(self)
	ToonKit.add_shape(self, "box", Vector3(2.6, 0.9, 1.0), Vector3(0, 0.45, 0.3), WOOD)
	ToonKit.add_shape(self, "box", Vector3(2.8, 0.08, 1.15), Vector3(0, 0.92, 0.3), WOOD_DARK)
	for x in [-1.25, 1.25]:
		for z in [-0.15, 0.75]:
			ToonKit.add_shape(self, "cylinder", Vector3(0.1, 2.3, 0.1), Vector3(x, 1.15, z), WOOD_DARK, Vector3.ZERO, false, 6)
	# Striped awning, tilted forward.
	for i in 7:
		var color := awning_color if i % 2 == 0 else CREAM
		ToonKit.add_shape(self, "box", Vector3(0.43, 0.06, 1.5), Vector3(-1.29 + i * 0.43, 2.35, 0.35), color, Vector3(14, 0, 0))
	for i in 7:
		var color := awning_color if i % 2 == 0 else CREAM
		ToonKit.add_shape(self, "prism", Vector3(0.43, 0.2, 0.04), Vector3(-1.29 + i * 0.43, 2.06, 1.07), color, Vector3(0, 0, 180))
	# Goods: baskets of fruit and a few jars.
	for i in 3:
		var x := -0.8 + i * 0.8
		ToonKit.add_shape(self, "cylinder", Vector3(0.55, 0.2, 0.62), Vector3(x, 1.06, 0.35), Color("#e8d3a2"), Vector3.ZERO, false, 10)
		for j in 4:
			var offset := Vector3(cos(j * 1.6) * 0.12, 1.2 + (j % 2) * 0.06, sin(j * 1.6) * 0.12 + 0.35)
			var c := goods_color if i != 1 else Color("#f3d27a")
			ToonKit.add_shape(self, "sphere", Vector3(0.16, 0.16, 0.16), offset + Vector3(x, 0, 0), c, Vector3.ZERO, false, 8)
	ToonKit.add_shape(self, "box", Vector3(0.6, 0.45, 0.5), Vector3(1.0, 0.22, 1.15), WOOD)
	ToonKit.add_box_collider(self, Vector3(2.8, 2.4, 1.3), Vector3(0, 1.2, 0.3))
