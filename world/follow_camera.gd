extends Node3D
## A camera that follows the player from high up and behind, like ECO.
##   Right mouse drag or Q / E  = turn around the player
##   Mouse wheel or - / =       = zoom in and out
## Only things on physics layer 1 ("world") block the camera.

@export var target: Node3D
@export var height_offset := 0.7
@export var pitch_degrees := -38.0
@export var distance := 7.5
@export var min_distance := 3.5
@export var max_distance := 13.0
@export var follow_speed := 8.0
@export var mouse_turn_speed := 0.3
@export var key_turn_speed := 100.0

@onready var camera: Camera3D = $Camera3D

var _yaw := 0.0
var _target_distance := 7.5
var _dragging := false


func _ready() -> void:
	_yaw = rotation_degrees.y
	_target_distance = distance
	if target:
		global_position = target.global_position + Vector3.UP * height_offset


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_RIGHT:
				_dragging = event.pressed
			MOUSE_BUTTON_WHEEL_UP:
				_target_distance = clampf(_target_distance - 0.8, min_distance, max_distance)
			MOUSE_BUTTON_WHEEL_DOWN:
				_target_distance = clampf(_target_distance + 0.8, min_distance, max_distance)
	elif event is InputEventMouseMotion and _dragging:
		_yaw -= event.relative.x * mouse_turn_speed


func _process(delta: float) -> void:
	_yaw += Input.get_axis("camera_right", "camera_left") * key_turn_speed * delta
	_target_distance = clampf(_target_distance + Input.get_axis("zoom_in", "zoom_out") * 8.0 * delta, min_distance, max_distance)
	distance = lerpf(distance, _target_distance, 1.0 - exp(-10.0 * delta))

	if target:
		var goal := target.global_position + Vector3.UP * height_offset
		global_position = global_position.lerp(goal, 1.0 - exp(-follow_speed * delta))
	rotation_degrees = Vector3(pitch_degrees, _yaw, 0.0)

	# If a house or tree is between the player and the camera, move the
	# camera closer so it doesn't end up inside the wall.
	var wanted := distance
	var from := global_position
	var to := global_transform * Vector3(0, 0, distance + 0.4)
	var query := PhysicsRayQueryParameters3D.create(from, to, 1)
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit:
		wanted = maxf(from.distance_to(hit.position) - 0.4, 0.8)
	camera.position = Vector3(0, 0, wanted)
