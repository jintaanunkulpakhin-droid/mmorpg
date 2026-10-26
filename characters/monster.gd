class_name Monster
extends CharacterBody3D
## A simple mine monster (an "Ore Slime"). It wanders around, fights back
## when you hit it, and comes back a few seconds after it is defeated.
## Its body is built from ToonKit shapes; a real model can replace it later.

signal died(monster: Monster)

const HP_BAR_SHADER := preload("res://shaders/hp_bar.gdshader")

@export var monster_name := "Ore Slime"
@export var max_hp := 100
@export var attack := 6
@export var body_color := Color("#7d6a8f")
@export var crystal_color := Color("#ff6b8a")
@export var base_exp := 420
@export var job_exp := 310

var hp := 100
var target: Node3D = null  # who it is angry at
var alive := true

var _home := Vector3.ZERO
var _wander_to := Vector3.ZERO
var _wander_wait := 0.0
var _attack_wait := 0.0
var _time := randf() * 10.0
var _body: Node3D
var _bar_material: ShaderMaterial
var _bar: MeshInstance3D
var _name_tag: Label3D
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")


func _ready() -> void:
	collision_layer = 4  # "monsters", so mouse clicks can find it
	collision_mask = 1
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.45
	capsule.height = 1.0
	shape.shape = capsule
	shape.position.y = 0.5
	add_child(shape)
	hp = max_hp
	_home = global_position
	_wander_to = _home
	_build_body()
	_build_tags()


func _build_body() -> void:
	_body = Node3D.new()
	add_child(_body)
	ToonKit.add_shape(_body, "sphere", Vector3(1.0, 0.8, 0.95), Vector3(0, 0.38, 0), body_color, Vector3.ZERO, true, 14)
	ToonKit.add_shape(_body, "sphere", Vector3(0.55, 0.3, 0.5), Vector3(0, 0.62, 0.05), body_color.lightened(0.25), Vector3.ZERO, false, 10)
	for eye in [-0.17, 0.17]:
		ToonKit.add_shape(_body, "sphere", Vector3(0.12, 0.17, 0.06), Vector3(eye, 0.45, 0.44), Color("#1b1420"), Vector3.ZERO, false, 8)
		ToonKit.add_shape(_body, "sphere", Vector3(0.05, 0.05, 0.03), Vector3(eye + 0.02, 0.49, 0.47), Color.WHITE, Vector3.ZERO, false, 6)
	# Glowing crystals growing out of its back.
	for c in [[0.0, 0.85, -0.1, 0.0, 0.5], [0.22, 0.72, -0.2, -25.0, 0.35], [-0.2, 0.74, -0.18, 25.0, 0.38]]:
		var crystal := ToonKit.add_shape(_body, "cone", Vector3(0.2, c[4], 0), Vector3(c[0], c[1], c[2]),
				crystal_color, Vector3(-20, 0, c[3]), false, 5)
		var glow := StandardMaterial3D.new()
		glow.albedo_color = crystal_color
		glow.emission_enabled = true
		glow.emission = crystal_color
		glow.emission_energy_multiplier = 1.4
		crystal.material_override = glow


func _build_tags() -> void:
	_name_tag = Label3D.new()
	_name_tag.text = monster_name
	_name_tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_name_tag.fixed_size = true
	_name_tag.no_depth_test = true
	_name_tag.pixel_size = 0.0005
	_name_tag.font_size = 32
	_name_tag.outline_size = 10
	_name_tag.modulate = Color("#ff9a9a")
	_name_tag.outline_modulate = Color(0, 0, 0, 0.9)
	_name_tag.position.y = 1.45
	add_child(_name_tag)

	_bar = MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(0.8, 0.09)
	_bar.mesh = quad
	_bar_material = ShaderMaterial.new()
	_bar_material.shader = HP_BAR_SHADER
	_bar_material.render_priority = 5
	_bar.material_override = _bar_material
	_bar.position.y = 1.22
	_bar.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_bar)


func _physics_process(delta: float) -> void:
	_time += delta
	if not alive:
		return
	var goal := _wander_to
	if target and is_instance_valid(target):
		goal = target.global_position
		if goal.distance_to(_home) > 14.0:
			target = null  # gave up the chase
	elif global_position.distance_to(_wander_to) < 0.3:
		_wander_wait -= delta
		if _wander_wait <= 0.0:
			_wander_wait = randf_range(1.5, 4.0)
			_wander_to = _home + Vector3(randf_range(-3, 3), 0, randf_range(-3, 3))

	var to_goal := goal - global_position
	to_goal.y = 0
	var close := target != null and to_goal.length() < 1.3
	var direction := Vector3.ZERO if close or to_goal.length() < 0.25 else to_goal.normalized()
	var speed := 2.4 if target else 1.0
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	velocity.y = 0.0 if is_on_floor() else velocity.y - _gravity * delta
	move_and_slide()
	if to_goal.length() > 0.1:
		_body.rotation.y = lerp_angle(_body.rotation.y, atan2(to_goal.x, to_goal.z), 1.0 - exp(-8.0 * delta))

	# Squishy bounce while it moves.
	var bounce := absf(sin(_time * 7.0)) if direction != Vector3.ZERO else 0.15 * (sin(_time * 2.5) + 1.0)
	_body.scale = Vector3(1.0 + bounce * 0.06, 1.0 - bounce * 0.1, 1.0 + bounce * 0.06)

	if close:
		_attack_wait -= delta
		if _attack_wait <= 0.0:
			_attack_wait = 1.6
			if target.has_method("take_hit"):
				target.take_hit(attack + randi_range(-2, 2), self)
			var tween := create_tween()
			tween.tween_property(_body, "position:z", 0.3, 0.08)
			tween.tween_property(_body, "position:z", 0.0, 0.15)


## Called by the battle code when the player hits this monster.
func take_damage(amount: int, from: Node3D) -> void:
	if not alive:
		return
	target = from
	hp = maxi(hp - amount, 0)
	_bar_material.set_shader_parameter("value", float(hp) / max_hp)
	var flash := create_tween()
	flash.tween_property(_body, "scale", Vector3(1.25, 0.75, 1.25), 0.06)
	flash.tween_property(_body, "scale", Vector3.ONE, 0.12)
	if hp == 0:
		_die()


func _die() -> void:
	alive = false
	target = null
	collision_layer = 0
	_bar.hide()
	_name_tag.hide()
	died.emit(self)
	Fx.sparkles(get_parent(), global_position + Vector3(0, 0.5, 0), crystal_color, 30)
	var tween := create_tween()
	tween.tween_property(_body, "scale", Vector3(1.6, 0.05, 1.6), 0.35).set_ease(Tween.EASE_IN)
	tween.tween_callback(_body.hide)
	tween.tween_interval(5.0)
	tween.tween_callback(_respawn)


func _respawn() -> void:
	global_position = _home
	hp = max_hp
	_bar_material.set_shader_parameter("value", 1.0)
	alive = true
	collision_layer = 4
	_body.show()
	_bar.show()
	_name_tag.show()
	var tween := create_tween()
	tween.tween_property(_body, "scale", Vector3.ONE, 0.3).from(Vector3(0.1, 0.1, 0.1)).set_trans(Tween.TRANS_BACK)
