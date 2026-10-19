## A "cut-out" character: each body part is one painted picture, and the parts
## turn around their joints like a paper puppet. To change an outfit later, you
## only swap the picture for one part (for example a new jacket for "torso").
class_name CutoutRig
extends Node2D

## Which pose to show: "idle", "walk", "jump" or "punch". The player script sets it.
var state := "idle"
## How fast the character is moving, from 0 to 1. Makes the walk swing bigger.
var move_amount := 0.0

## Folder that holds the part pictures.
@export_dir var art_folder := "res://art/benika"

# Each part: the joint it hangs from, where that joint sits on its parent
# (in pixels), the picture's offset so it turns around the joint, and draw order.
# The offsets come from tools/trim_art.py.
const PARTS := [
	{"name": "leg_back", "parent": "hips", "pos": Vector2(-16, 0), "offset": Vector2(-15, -7), "z": 0},
	{"name": "leg_front", "parent": "hips", "pos": Vector2(16, 0), "offset": Vector2(-16, -8), "z": 0},
	{"name": "torso", "parent": "hips", "pos": Vector2(0, 0), "offset": Vector2(-94, -172), "z": 0},
	{"name": "arm_back", "parent": "torso", "pos": Vector2(-28, -132), "offset": Vector2(-28, -15), "z": -1},
	{"name": "head", "parent": "torso", "pos": Vector2(0, -152), "offset": Vector2(-105, -188), "z": 0},
	{"name": "ponytail", "parent": "head", "pos": Vector2(76, -148), "offset": Vector2(-16, -32), "z": -1},
	{"name": "arm_front", "parent": "torso", "pos": Vector2(28, -132), "offset": Vector2(-27, -16), "z": 1},
]

var joints := {}
var _time := 0.0
var _hips: Node2D


func _ready() -> void:
	# The hips sit 88 px above the feet. The rig's own position is the feet.
	_hips = Node2D.new()
	_hips.name = "Hips"
	_hips.position = Vector2(0, -88)
	add_child(_hips)
	joints["hips"] = _hips
	for p in PARTS:
		var joint := Node2D.new()
		joint.name = p.name.capitalize().replace(" ", "")
		joint.position = p.pos
		joint.z_index = p.z
		var sprite := Sprite2D.new()
		sprite.texture = load("%s/%s.png" % [art_folder, p.name])
		sprite.centered = false
		sprite.offset = p.offset
		joint.add_child(sprite)
		joints[p.parent].add_child(joint)
		joints[p.name] = joint


func _process(delta: float) -> void:
	_time += delta
	var t := _time
	# Every pose starts from standing still, then each state adds its own movement.
	var pose := {
		"hips_y": -88.0, "torso": 0.0, "head": 0.0, "ponytail": 0.0,
		"arm_back": 0.15, "arm_front": -0.15, "leg_back": 0.0, "leg_front": 0.0,
	}
	match state:
		"idle":
			pose.hips_y += sin(t * 2.5) * 2.0
			pose.head = sin(t * 2.5) * 0.03
			pose.ponytail = sin(t * 2.0) * 0.08
		"walk":
			var swing: float = sin(t * 11.0) * 0.55 * maxf(move_amount, 0.4)
			pose.leg_front = swing
			pose.leg_back = -swing
			pose.arm_front = -swing * 0.8
			pose.arm_back = swing * 0.8
			pose.hips_y += -absf(sin(t * 11.0)) * 6.0
			pose.torso = 0.06
			pose.ponytail = 0.25 + sin(t * 11.0) * 0.12
		"jump":
			pose.leg_front = -0.7
			pose.leg_back = 0.35
			pose.arm_front = -2.4
			pose.arm_back = 0.9
			pose.ponytail = -0.35
		"punch":
			# The front arm points straight forward and the body leans in.
			pose.arm_front = -PI / 2.0
			pose.arm_back = 0.6
			pose.torso = 0.15
			pose.leg_front = -0.35
			pose.leg_back = 0.35
			pose.ponytail = 0.4
	# Ease toward the pose so changes look smooth instead of snapping.
	var k := clampf(delta * 18.0, 0.0, 1.0)
	_hips.position.y = lerpf(_hips.position.y, pose.hips_y, k)
	for part_name in ["torso", "head", "ponytail", "arm_back", "arm_front", "leg_back", "leg_front"]:
		var j: Node2D = joints[part_name]
		j.rotation = lerp_angle(j.rotation, pose[part_name], k)


## Where the front fist is in the world, for placing punch effects.
func fist_position() -> Vector2:
	return (joints["arm_front"] as Node2D).to_global(Vector2(0, 92))
