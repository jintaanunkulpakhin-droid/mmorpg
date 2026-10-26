@tool
class_name Chibi
extends Node3D
## A chibi character (about 2.5 heads tall) built on one shared skeleton.
##
## The player and every NPC use this same script. Each one just picks
## different outfit items from OutfitCatalog. Change the fields in the
## Inspector (right side of the Godot editor) to dress a character up.
##
## How it works:
##   1. A Skeleton3D with 7 bones is made (hips, chest, head, 2 arms, 2 legs).
##   2. The body and every outfit part are glued to those bones.
##   3. The walk animation turns the bones, so clothes move with the body.

signal outfit_changed

## The shared skeleton: bone name, parent bone, position from the parent,
## and a resting tilt in degrees.
const BONES := [
	["Hips", "", Vector3(0.0, 0.42, 0.0), Vector3.ZERO],
	["Chest", "Hips", Vector3(0.0, 0.16, 0.0), Vector3.ZERO],
	["Head", "Chest", Vector3(0.0, 0.22, 0.0), Vector3.ZERO],
	["Arm.L", "Chest", Vector3(0.17, 0.16, 0.0), Vector3(0, 0, 12)],
	["Arm.R", "Chest", Vector3(-0.17, 0.16, 0.0), Vector3(0, 0, -12)],
	["Leg.L", "Hips", Vector3(0.085, 0.0, 0.0), Vector3.ZERO],
	["Leg.R", "Hips", Vector3(-0.085, 0.0, 0.0), Vector3.ZERO],
]

const FACE_SHADER := preload("res://shaders/face.gdshader")
const OUTLINE_SHADER := preload("res://shaders/outline.gdshader")
const INNER_WEAR := Color("#fbefcb")

@export_group("Look")
@export var skin_color := Color("#fbe3d2"):
	set(value):
		skin_color = value
		_queue_rebuild()
@export var eye_color := Color("#5b8cd9"):
	set(value):
		eye_color = value
		_queue_rebuild()

@export_group("Outfit")
@export var hair := "hair_bob":
	set(value):
		hair = value
		_queue_rebuild()
@export var head := "none":
	set(value):
		head = value
		_queue_rebuild()
@export var top := "top_tunic":
	set(value):
		top = value
		_queue_rebuild()
@export var bottom := "bottom_shorts":
	set(value):
		bottom = value
		_queue_rebuild()
@export var shoes := "shoes_boots":
	set(value):
		shoes = value
		_queue_rebuild()
@export var back := "none":
	set(value):
		back = value
		_queue_rebuild()

@export_group("Dyes")
## Leave a dye at full transparent (the default) to use the item's own colour.
@export var hair_dye := Color(0, 0, 0, 0):
	set(value):
		hair_dye = value
		_queue_rebuild()
@export var head_dye := Color(0, 0, 0, 0):
	set(value):
		head_dye = value
		_queue_rebuild()
@export var top_dye := Color(0, 0, 0, 0):
	set(value):
		top_dye = value
		_queue_rebuild()
@export var bottom_dye := Color(0, 0, 0, 0):
	set(value):
		bottom_dye = value
		_queue_rebuild()
@export var shoes_dye := Color(0, 0, 0, 0):
	set(value):
		shoes_dye = value
		_queue_rebuild()
@export var back_dye := Color(0, 0, 0, 0):
	set(value):
		back_dye = value
		_queue_rebuild()

## How fast the character is walking, from 0 (standing) to 1 (full speed).
## The player and NPC scripts set this every frame.
var walk_amount := 0.0

var skeleton: Skeleton3D
var _attachments := {}  # bone name -> BoneAttachment3D
var _slot_nodes := {}  # slot name -> Array of the nodes that slot made
var _body_nodes := {}  # body tag -> Array of body nodes (e.g. "feet")
var _hair_crown: Array[Node3D] = []
var _flappers: Array = []  # [pivot, side] pairs for wings
var _face_material: ShaderMaterial
var _rebuild_queued := false
var _walk_time := 0.0
var _idle_time := 0.0
var _blink_timer := 2.0
var _blink_left := 0.0


func _ready() -> void:
	_rebuild()


## Lets the editor show item names as a dropdown instead of a text box.
func _validate_property(property: Dictionary) -> void:
	if property.name in OutfitCatalog.SLOTS:
		property.hint = PROPERTY_HINT_ENUM
		property.hint_string = ",".join(OutfitCatalog.ids_for_slot(property.name))


# ----------------------------------------------------------------------------
# Outfit API (used by the wardrobe window)
# ----------------------------------------------------------------------------

func get_item(slot: String) -> String:
	return get(slot)


func equip(slot: String, item_id: String) -> void:
	set(slot, item_id)


func get_dye(slot: String) -> Color:
	var dye: Color = get(slot + "_dye")
	if dye.a > 0.0:
		return dye
	return OutfitCatalog.get_item(get_item(slot)).get("dye", Color.WHITE)


func set_dye(slot: String, color: Color) -> void:
	set(slot + "_dye", color)


## Makes a random outfit. Handy for NPCs and for testing that everything fits.
func randomize_outfit(rng: RandomNumberGenerator) -> void:
	for slot in OutfitCatalog.SLOTS:
		var ids := OutfitCatalog.ids_for_slot(slot)
		set(slot, ids[rng.randi() % ids.size()])
		set(slot + "_dye", OutfitCatalog.DYES[rng.randi() % OutfitCatalog.DYES.size()])
	eye_color = OutfitCatalog.EYE_COLORS[rng.randi() % OutfitCatalog.EYE_COLORS.size()]


# ----------------------------------------------------------------------------
# Building the character
# ----------------------------------------------------------------------------

func _queue_rebuild() -> void:
	# Many fields can change in one frame, so rebuild once at the end of it.
	if _rebuild_queued or not is_inside_tree():
		return
	_rebuild_queued = true
	_rebuild.call_deferred()


func _rebuild() -> void:
	_rebuild_queued = false
	if skeleton == null:
		_build_skeleton()
		_build_body()
	_face_material.set_shader_parameter("skin_color", skin_color)
	_face_material.set_shader_parameter("eye_color", eye_color)
	for tag in _body_nodes:
		for node: MeshInstance3D in _body_nodes[tag]:
			if tag != "inner":
				node.material_override = ToonKit.material(skin_color, true)
	for slot in OutfitCatalog.SLOTS:
		_build_slot(slot)
	_apply_hiding_rules()
	outfit_changed.emit()


func _build_skeleton() -> void:
	# If the editor reloaded this script, remove the old copy first.
	var old := get_node_or_null("Skeleton")
	if old:
		remove_child(old)
		old.queue_free()
	skeleton = Skeleton3D.new()
	skeleton.name = "Skeleton"
	add_child(skeleton)
	for bone in BONES:
		var index := skeleton.add_bone(bone[0])
		if bone[1] != "":
			skeleton.set_bone_parent(index, skeleton.find_bone(bone[1]))
		var tilt: Vector3 = bone[3]
		var rest := Transform3D(Basis.from_euler(tilt * PI / 180.0), bone[2])
		skeleton.set_bone_rest(index, rest)
	skeleton.reset_bone_poses()
	for bone in BONES:
		var attachment := BoneAttachment3D.new()
		attachment.name = bone[0].replace(".", "_")
		attachment.bone_name = bone[0]
		skeleton.add_child(attachment)
		_attachments[bone[0]] = attachment


func _build_body() -> void:
	var line := ShaderMaterial.new()
	line.shader = OUTLINE_SHADER
	_face_material = ShaderMaterial.new()
	_face_material.shader = FACE_SHADER
	_face_material.next_pass = line

	var face := MeshInstance3D.new()
	face.name = "Face"
	var sphere := SphereMesh.new()
	sphere.radius = 0.26
	sphere.height = 0.52
	sphere.radial_segments = 20
	sphere.rings = 12
	face.mesh = sphere
	face.material_override = _face_material
	face.position = OutfitCatalog.HEAD
	_attachments["Head"].add_child(face)

	_body_nodes = {"inner": [], "skin": [], "feet": []}
	_body_nodes.inner.append(ToonKit.add_shape(_attachments["Chest"], "sphere", Vector3(0.3, 0.28, 0.21), Vector3(0, 0.07, 0), INNER_WEAR, Vector3.ZERO, true))
	_body_nodes.inner.append(ToonKit.add_shape(_attachments["Hips"], "sphere", Vector3(0.27, 0.17, 0.19), Vector3(0, 0.03, 0), INNER_WEAR, Vector3.ZERO, true))
	_body_nodes.skin.append(ToonKit.add_shape(_attachments["Chest"], "cylinder", Vector3(0.09, 0.08, 0.09), Vector3(0, 0.2, 0), skin_color, Vector3.ZERO, true, 8))
	for side in ["L", "R"]:
		var arm: Node3D = _attachments["Arm." + side]
		var leg: Node3D = _attachments["Leg." + side]
		_body_nodes.skin.append(ToonKit.add_shape(arm, "capsule", Vector3(0.09, 0.3, 0.09), Vector3(0, -0.13, 0), skin_color, Vector3.ZERO, true, 8))
		_body_nodes.skin.append(ToonKit.add_shape(arm, "sphere", Vector3(0.1, 0.1, 0.1), Vector3(0, -0.29, 0), skin_color, Vector3.ZERO, true, 8))
		_body_nodes.skin.append(ToonKit.add_shape(leg, "capsule", Vector3(0.1, 0.34, 0.1), Vector3(0, -0.17, 0), skin_color, Vector3.ZERO, true, 8))
		_body_nodes.feet.append(ToonKit.add_shape(leg, "sphere", Vector3(0.12, 0.08, 0.17), Vector3(0, -0.38, 0.03), skin_color, Vector3.ZERO, true, 8))


func _build_slot(slot: String) -> void:
	for node in _slot_nodes.get(slot, []):
		node.queue_free()
	var made: Array[Node3D] = []
	_slot_nodes[slot] = made
	_flappers = _flappers.filter(func(f): return f[2] != slot)
	if slot == "hair":
		_hair_crown.clear()

	var item := OutfitCatalog.get_item(get_item(slot))
	if item.is_empty():
		return
	var dye := get_dye(slot)
	var accent: Color = item.get("accent", dye.darkened(0.3))
	for part: Dictionary in item.parts:
		var color: Color
		match part.color:
			"dye":
				color = dye
			"accent":
				color = accent
			_:
				color = part.color
		var bone: String = part.bone
		# "Arm" and "Leg" parts are made twice, mirrored for the right side.
		var sides := [""]
		if bone == "Arm" or bone == "Leg":
			sides = [".L", ".R"]
		for side in sides:
			var mirror: bool = side == ".R"
			var parent: Node3D = _attachments[bone + side]
			var pos: Vector3 = part.pos
			var rot: Vector3 = part.get("rot", Vector3.ZERO)
			if mirror:
				pos.x = -pos.x
				rot.y = -rot.y
				rot.z = -rot.z
			if part.has("pivot"):
				# Wing feathers hang off a pivot so they can flap.
				var pivot := Node3D.new()
				pivot.position = part.pivot
				parent.add_child(pivot)
				made.append(pivot)
				_flappers.append([pivot, part.get("flap", 1.0), slot])
				parent = pivot
			var mesh := ToonKit.add_shape(parent, part.shape, part.size, pos, color, rot, true, part.get("segments", 12))
			made.append(mesh)
			if slot == "hair" and part.get("tag", "") == "crown":
				_hair_crown.append(mesh)


## The outfit rules from the style guide:
##   - a hat with hides_crown hides the top of the hair
##   - a one_piece top (a dress) hides the bottom slot
##   - "covers" hides body parts underneath (shoes hide bare feet)
func _apply_hiding_rules() -> void:
	var head_item := OutfitCatalog.get_item(head)
	var top_item := OutfitCatalog.get_item(top)
	for node in _hair_crown:
		node.visible = not head_item.get("hides_crown", false)
	for node: Node3D in _slot_nodes.get("bottom", []):
		node.visible = not top_item.get("one_piece", false)
	var covered := []
	for slot in OutfitCatalog.SLOTS:
		covered.append_array(OutfitCatalog.get_item(get_item(slot)).get("covers", []))
	for node: Node3D in _body_nodes.feet:
		node.visible = not "feet" in covered


# ----------------------------------------------------------------------------
# Animation (all done in code by turning bones)
# ----------------------------------------------------------------------------

func _process(delta: float) -> void:
	if Engine.is_editor_hint() or skeleton == null:
		return
	_idle_time += delta
	_walk_time += delta * lerpf(0.0, 9.0, walk_amount)
	var swing := sin(_walk_time) * 0.75 * walk_amount
	var bounce := absf(sin(_walk_time)) * 0.035 * walk_amount
	var breathe := sin(_idle_time * 2.2) * 0.006 * (1.0 - walk_amount)

	_pose("Leg.L", Vector3(swing, 0, 0))
	_pose("Leg.R", Vector3(-swing, 0, 0))
	_pose("Arm.L", Vector3(-swing * 0.9, 0, 0))
	_pose("Arm.R", Vector3(swing * 0.9, 0, 0))
	_pose("Chest", Vector3(0.08 * walk_amount, sin(_walk_time) * 0.12 * walk_amount, 0))
	_pose("Head", Vector3(-0.06 * walk_amount, 0, sin(_idle_time * 0.9) * 0.04))
	var hips := skeleton.find_bone("Hips")
	skeleton.set_bone_pose_position(hips, skeleton.get_bone_rest(hips).origin + Vector3(0, bounce + breathe, 0))

	for flapper in _flappers:
		var pivot: Node3D = flapper[0]
		pivot.rotation.y = flapper[1] * (0.35 + sin(_idle_time * (3.0 + walk_amount * 6.0)) * 0.35)

	_update_blink(delta)


## Turns a bone by an angle (in radians) on top of its resting tilt.
func _pose(bone_name: String, angles: Vector3) -> void:
	var index := skeleton.find_bone(bone_name)
	var rest := skeleton.get_bone_rest(index).basis.get_rotation_quaternion()
	skeleton.set_bone_pose_rotation(index, rest * Quaternion.from_euler(angles))


func _update_blink(delta: float) -> void:
	_blink_timer -= delta
	if _blink_timer <= 0.0:
		_blink_timer = randf_range(2.0, 5.0)
		_blink_left = 0.14
	var open := 1.0
	if _blink_left > 0.0:
		_blink_left -= delta
		open = 0.0
	_face_material.set_shader_parameter("blink", open)
