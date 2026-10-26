@tool
extends Node3D
## A string of little festival flags hanging between two points.
## The string starts here and ends at "end_point" (measured from here).

@export var end_point := Vector3(10, 0, 0):
	set(value):
		end_point = value
		_rebuild()
@export var sag := 0.8:
	set(value):
		sag = value
		_rebuild()
@export var flag_spacing := 0.6:
	set(value):
		flag_spacing = value
		_rebuild()

const COLORS := [Color("#f4b6cb"), Color("#f3d27a"), Color("#6aa6d8"), Color("#a8d58a"), Color("#f0955a")]
const ROPE := Color("#7e4a20")


func _ready() -> void:
	_rebuild()


func _point(t: float) -> Vector3:
	return end_point * t - Vector3(0, sag * 4.0 * t * (1.0 - t), 0)


func _rebuild() -> void:
	if not is_inside_tree():
		return
	ToonKit.clear_children(self)
	var segments := 12
	for i in segments:
		var a := _point(float(i) / segments)
		var b := _point(float(i + 1) / segments)
		var rope := ToonKit.add_shape(self, "box", Vector3(0.03, 0.03, a.distance_to(b)), (a + b) * 0.5, ROPE)
		rope.basis = Basis.looking_at(b - a, Vector3.UP)
	var count := int(end_point.length() / flag_spacing)
	var yaw := atan2(end_point.x, end_point.z) - PI * 0.5
	for i in range(1, count):
		var t := float(i) / count
		var p := _point(t)
		var flag := ToonKit.add_shape(self, "prism", Vector3(0.32, 0.4, 0.02), p - Vector3(0, 0.2, 0), COLORS[i % COLORS.size()], Vector3(0, 0, 180))
		flag.rotation.y = yaw
