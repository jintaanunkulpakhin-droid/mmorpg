@tool
extends StaticBody3D
## The fountain in the middle of the town square.

const STONE := Color("#e8dccb")
const STONE_DARK := Color("#bba693")
const WATER := Color("#9fd8f0")

var _time := 0.0
var _drops: Array[Node3D] = []


func _ready() -> void:
	ToonKit.clear_children(self)
	ToonKit.add_shape(self, "cylinder", Vector3(4.2, 0.6, 4.2), Vector3(0, 0.3, 0), STONE_DARK, Vector3.ZERO, false, 16)
	ToonKit.add_shape(self, "torus", Vector3(4.3, 0.3, 4.3), Vector3(0, 0.64, 0), STONE, Vector3.ZERO, false, 16)
	ToonKit.add_shape(self, "cylinder", Vector3(3.8, 0.08, 3.8), Vector3(0, 0.6, 0), WATER, Vector3.ZERO, false, 16)
	ToonKit.add_shape(self, "cylinder", Vector3(0.6, 1.4, 0.45), Vector3(0, 1.2, 0), STONE, Vector3.ZERO, false, 10)
	ToonKit.add_shape(self, "cylinder", Vector3(0.5, 0.25, 1.5), Vector3(0, 1.95, 0), STONE, Vector3.ZERO, false, 12)
	ToonKit.add_shape(self, "cylinder", Vector3(1.3, 0.05, 1.3), Vector3(0, 2.06, 0), WATER, Vector3.ZERO, false, 12)
	ToonKit.add_shape(self, "sphere", Vector3(0.35, 0.45, 0.35), Vector3(0, 2.3, 0), STONE, Vector3.ZERO, false, 10)
	# Little water drops that bob up and down.
	_drops.clear()
	for i in 6:
		var angle := i * TAU / 6.0
		var drop := ToonKit.add_shape(self, "sphere", Vector3(0.12, 0.16, 0.12), Vector3(cos(angle) * 0.6, 1.9, sin(angle) * 0.6), WATER, Vector3.ZERO, false, 6)
		_drops.append(drop)
	ToonKit.add_cylinder_collider(self, 2.2, 2.5, Vector3(0, 1.25, 0))


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_time += delta
	for i in _drops.size():
		var t := fmod(_time * 0.8 + i / 6.0, 1.0)
		var angle := i * TAU / 6.0
		var r := 0.3 + t * 0.55
		_drops[i].position = Vector3(cos(angle) * r, 2.35 + sin(t * PI) * 0.35 - t * 0.3, sin(angle) * r)
