extends CharacterBody3D
## A townsperson who strolls around near home and can be talked to.
## Change the name, lines and outfit in the Inspector.

@export var npc_name := "Villager"
@export_multiline var lines: Array[String] = ["Hello!"]
@export var wander_radius := 3.0
@export var speed := 1.4

@onready var model: Chibi = $Chibi
@onready var name_label: Label3D = $NameLabel

var talking := false
var _home := Vector3.ZERO
var _target := Vector3.ZERO
var _wait := 0.0
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	add_to_group("npcs")
	_home = global_position
	_target = _home
	_rng.seed = hash(npc_name)
	_wait = _rng.randf_range(0.5, 3.0)
	name_label.text = npc_name


func _physics_process(delta: float) -> void:
	var direction := Vector3.ZERO
	if not talking:
		var to_target := _target - global_position
		to_target.y = 0
		if to_target.length() < 0.2:
			_wait -= delta
			if _wait <= 0.0:
				_pick_new_target()
		else:
			direction = to_target.normalized()

	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	velocity.y = 0.0 if is_on_floor() else velocity.y - _gravity * delta
	move_and_slide()

	# Bumped into something: stop and pick somewhere else later.
	if direction != Vector3.ZERO and get_slide_collision_count() > 0 and get_real_velocity().length() < 0.2:
		_target = global_position
		_wait = 1.0

	if direction != Vector3.ZERO:
		model.rotation.y = lerp_angle(model.rotation.y, atan2(direction.x, direction.z), 1.0 - exp(-8.0 * delta))
	var flat_speed := Vector2(get_real_velocity().x, get_real_velocity().z).length()
	model.walk_amount = clampf(flat_speed / 3.6, 0.0, 1.0)


func _pick_new_target() -> void:
	var angle := _rng.randf() * TAU
	var dist := _rng.randf_range(0.5, wander_radius)
	_target = _home + Vector3(cos(angle) * dist, 0, sin(angle) * dist)
	_wait = _rng.randf_range(1.5, 4.0)


func start_talking(player_position: Vector3) -> void:
	talking = true
	var d := player_position - global_position
	model.rotation.y = atan2(d.x, d.z)


func stop_talking() -> void:
	talking = false
	_wait = 2.0
