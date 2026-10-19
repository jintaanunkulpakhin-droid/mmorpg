extends CharacterBody3D
## The player: walk with WASD / arrow keys, or click the ground to walk there.
## Movement is relative to the camera, so "up" always means "away from the camera".

@export var speed := 3.6
@export var turn_speed := 12.0

@onready var model: Chibi = $Chibi
@onready var click_marker: Node3D = $ClickMarker

var _click_target: Variant = null  # a Vector3 while walking to a clicked spot
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

## Set by the HUD while a dialogue or text box is open, so the player stands still.
var frozen := false


func _ready() -> void:
	click_marker.top_level = true
	click_marker.visible = false


func _unhandled_input(event: InputEvent) -> void:
	# Left click on the ground = walk there (like ECO and most classic MMOs).
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var camera := get_viewport().get_camera_3d()
		var from := camera.project_ray_origin(event.position)
		var to := from + camera.project_ray_normal(event.position) * 200.0
		var query := PhysicsRayQueryParameters3D.create(from, to, 1)
		var hit := get_world_3d().direct_space_state.intersect_ray(query)
		if hit and hit.normal.y > 0.7:
			_click_target = hit.position
			click_marker.global_position = hit.position + Vector3(0, 0.03, 0)
			click_marker.visible = true


func _physics_process(delta: float) -> void:
	var direction := Vector3.ZERO
	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	if frozen:
		input = Vector2.ZERO
		_click_target = null

	if input != Vector2.ZERO:
		# Keys always win over a click target.
		_click_target = null
		var camera := get_viewport().get_camera_3d()
		var yaw := camera.global_rotation.y if camera else 0.0
		direction = Vector3(input.x, 0, input.y).rotated(Vector3.UP, yaw)
	elif _click_target != null:
		var to_target: Vector3 = _click_target - global_position
		to_target.y = 0
		if to_target.length() < 0.15:
			_click_target = null
		else:
			direction = to_target.normalized()

	if direction.length() > 1.0:
		direction = direction.normalized()
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	velocity.y = 0.0 if is_on_floor() else velocity.y - _gravity * delta
	move_and_slide()

	# If we walked into a wall on the way to a click target, give up.
	if _click_target != null and get_slide_collision_count() > 0 and get_real_velocity().length() < 0.3:
		_click_target = null

	click_marker.visible = _click_target != null
	click_marker.rotate_y(delta * 2.0)

	# Turn the model to face where we're going, and tell it how fast to animate.
	if direction.length() > 0.05:
		var target_angle := atan2(direction.x, direction.z)
		model.rotation.y = lerp_angle(model.rotation.y, target_angle, 1.0 - exp(-turn_speed * delta))
	var flat_speed := Vector2(get_real_velocity().x, get_real_velocity().z).length()
	model.walk_amount = clampf(flat_speed / speed, 0.0, 1.0)


## Turns the model to look at a spot (used when talking to NPCs).
func face_towards(point: Vector3) -> void:
	var d := point - global_position
	model.rotation.y = atan2(d.x, d.z)
