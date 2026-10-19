@tool
extends StaticBody3D
## A cosy town house: plaster walls, brick patches, a pointed roof, a door
## and flower-box windows. The door faces forward (the blue Z arrow).
## Change the fields in the Inspector and the house rebuilds right away.

@export var size := Vector3(5.0, 3.0, 4.5):
	set(value):
		size = value
		_rebuild()
@export var roof_height := 2.2:
	set(value):
		roof_height = value
		_rebuild()
@export var wall_color := Color("#fbefcb"):
	set(value):
		wall_color = value
		_rebuild()
@export var roof_color := Color("#d9785a"):
	set(value):
		roof_color = value
		_rebuild()
@export var trim_color := Color("#8a4b1e"):
	set(value):
		trim_color = value
		_rebuild()
@export var flower_color := Color("#f4b6cb"):
	set(value):
		flower_color = value
		_rebuild()
## Text on the hanging sign above the door. Leave empty for no sign.
@export var sign_text := "":
	set(value):
		sign_text = value
		_rebuild()

const STONE := Color("#bba693")
const BRICK := Color("#d08a62")
const GLASS := Color("#bfe3f5")
const BASE := 0.3


func _ready() -> void:
	_rebuild()


func _rebuild() -> void:
	if not is_inside_tree():
		return
	ToonKit.clear_children(self)
	var w := size.x
	var h := size.y
	var d := size.z
	var front := d * 0.5

	ToonKit.add_shape(self, "box", Vector3(w + 0.3, BASE, d + 0.3), Vector3(0, BASE * 0.5, 0), STONE)
	ToonKit.add_shape(self, "box", Vector3(w, h, d), Vector3(0, BASE + h * 0.5, 0), wall_color)

	# Corner posts and a beam under the roof, in dark wood.
	for x in [-w * 0.5, w * 0.5]:
		for z in [-front, front]:
			ToonKit.add_shape(self, "box", Vector3(0.22, h, 0.22), Vector3(x, BASE + h * 0.5, z), trim_color)
	ToonKit.add_shape(self, "box", Vector3(w + 0.1, 0.2, d + 0.1), Vector3(0, BASE + h - 0.1, 0), trim_color)

	# A few patches of exposed brick, like old plaster that fell off.
	ToonKit.add_shape(self, "box", Vector3(0.7, 0.35, 0.05), Vector3(-w * 0.32, BASE + 0.45, front + 0.01), BRICK)
	ToonKit.add_shape(self, "box", Vector3(0.45, 0.3, 0.05), Vector3(w * 0.36, BASE + h - 0.55, front + 0.01), BRICK)
	ToonKit.add_shape(self, "box", Vector3(0.05, 0.32, 0.6), Vector3(w * 0.5 + 0.01, BASE + h * 0.4, d * 0.15), BRICK)

	# Roof: a long triangle with overhang, plus a chimney.
	var roof := ToonKit.add_shape(self, "prism", Vector3(w + 0.8, roof_height, d + 0.7), Vector3(0, BASE + h + roof_height * 0.5, 0), roof_color)
	roof.position.y -= 0.05
	ToonKit.add_shape(self, "box", Vector3(0.5, 1.4, 0.5), Vector3(w * 0.25, BASE + h + roof_height * 0.6, -d * 0.2), BRICK)
	ToonKit.add_shape(self, "box", Vector3(0.6, 0.12, 0.6), Vector3(w * 0.25, BASE + h + roof_height * 0.6 + 0.7, -d * 0.2), STONE)
	# Round window in the gable.
	ToonKit.add_shape(self, "cylinder", Vector3(0.7, 0.08, 0.7), Vector3(0, BASE + h + roof_height * 0.32, front + 0.37), trim_color, Vector3(90, 0, 0))
	ToonKit.add_shape(self, "cylinder", Vector3(0.5, 0.1, 0.5), Vector3(0, BASE + h + roof_height * 0.32, front + 0.39), GLASS, Vector3(90, 0, 0))

	# Door with frame, knob and a step.
	ToonKit.add_shape(self, "box", Vector3(1.15, 1.85, 0.08), Vector3(0, BASE + 0.92, front + 0.03), trim_color)
	ToonKit.add_shape(self, "box", Vector3(0.9, 1.7, 0.08), Vector3(0, BASE + 0.85, front + 0.06), Color("#b8642a"))
	ToonKit.add_shape(self, "sphere", Vector3(0.09, 0.09, 0.09), Vector3(0.3, BASE + 0.85, front + 0.12), Color("#e3b34e"))
	ToonKit.add_shape(self, "box", Vector3(1.4, 0.15, 0.5), Vector3(0, 0.08, front + 0.35), STONE)

	# Windows: front ones if the house is wide enough, and one on each side.
	if w >= 4.0:
		for x in [-w * 0.3, w * 0.3]:
			_add_window(Vector3(x, BASE + h * 0.58, front), 0.0)
	for side in [-1.0, 1.0]:
		_add_window(Vector3(side * w * 0.5, BASE + h * 0.58, -d * 0.1), side * 90.0)

	if sign_text != "":
		_add_sign(Vector3(0.0, BASE + 2.15, front))

	ToonKit.add_box_collider(self, Vector3(w + 0.3, h + BASE + roof_height, d + 0.3), Vector3(0, (h + BASE + roof_height) * 0.5, 0))


func _add_window(pos: Vector3, angle: float) -> void:
	var pivot := Node3D.new()
	pivot.position = pos
	pivot.rotation_degrees.y = angle
	add_child(pivot)
	ToonKit.add_shape(pivot, "box", Vector3(0.95, 0.95, 0.08), Vector3(0, 0, 0.03), trim_color)
	ToonKit.add_shape(pivot, "box", Vector3(0.75, 0.75, 0.08), Vector3(0, 0, 0.06), GLASS)
	ToonKit.add_shape(pivot, "box", Vector3(0.06, 0.75, 0.1), Vector3(0, 0, 0.07), trim_color)
	ToonKit.add_shape(pivot, "box", Vector3(0.75, 0.06, 0.1), Vector3(0, 0, 0.07), trim_color)
	# Flower box under the window.
	ToonKit.add_shape(pivot, "box", Vector3(1.0, 0.22, 0.3), Vector3(0, -0.58, 0.18), Color("#b8642a"))
	for i in 5:
		var x := -0.36 + i * 0.18
		var color := flower_color if i % 2 == 0 else Color("#fbefcb")
		ToonKit.add_shape(pivot, "sphere", Vector3(0.16, 0.14, 0.16), Vector3(x, -0.43, 0.18), color, Vector3.ZERO, false, 8)
	ToonKit.add_shape(pivot, "box", Vector3(0.9, 0.08, 0.22), Vector3(0, -0.47, 0.18), Color("#6fb3a8"))


func _add_sign(pos: Vector3) -> void:
	ToonKit.add_shape(self, "box", Vector3(0.08, 0.08, 0.7), pos + Vector3(0.95, 0.3, 0.35), trim_color)
	ToonKit.add_shape(self, "box", Vector3(1.1, 0.5, 0.08), pos + Vector3(0.95, 0.0, 0.62), Color("#f3d27a"))
	var label := Label3D.new()
	label.text = sign_text
	label.font_size = 56
	label.pixel_size = 0.004
	label.modulate = Color("#4a3220")
	label.outline_size = 0
	label.position = pos + Vector3(0.95, 0.0, 0.67)
	add_child(label)
	var back := label.duplicate()
	back.rotation_degrees.y = 180
	back.position.z -= 0.1
	add_child(back)
