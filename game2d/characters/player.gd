## The player: runs left and right, jumps, and throws a fire punch.
extends CharacterBody2D

@export var run_speed := 300.0
@export var jump_speed := 640.0
@export var gravity := 1600.0
## How long one punch lasts, in seconds.
@export var punch_time := 0.28

const FLAME := preload("res://art/world/flame.png")

var facing := 1
var _punch_left := 0.0
var _spawn_point := Vector2.ZERO

@onready var rig: CutoutRig = $Rig


func _ready() -> void:
	_spawn_point = global_position


func _physics_process(delta: float) -> void:
	var dir := Input.get_axis("move_left", "move_right")

	if not is_on_floor():
		velocity.y += gravity * delta
	elif Input.is_action_just_pressed("jump"):
		velocity.y = -jump_speed
	# Letting go of jump early makes a smaller hop.
	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= 0.5

	velocity.x = move_toward(velocity.x, dir * run_speed, run_speed * delta * 10.0)
	if dir != 0.0:
		facing = 1 if dir > 0.0 else -1

	if Input.is_action_just_pressed("attack") and _punch_left <= 0.0:
		_punch_left = punch_time
		_spawn_flame.call_deferred()
	_punch_left -= delta

	move_and_slide()

	# Fell off the world: go back to the start.
	if global_position.y > 1600.0:
		global_position = _spawn_point
		velocity = Vector2.ZERO

	_update_rig()


func _update_rig() -> void:
	rig.scale.x = absf(rig.scale.x) * facing
	rig.move_amount = absf(velocity.x) / run_speed
	if _punch_left > 0.0:
		rig.state = "punch"
	elif not is_on_floor():
		rig.state = "jump"
	elif absf(velocity.x) > 10.0:
		rig.state = "walk"
	else:
		rig.state = "idle"


func _spawn_flame() -> void:
	# A splash of red ink fire in front of the fist that grows and fades.
	var fx := Sprite2D.new()
	fx.texture = FLAME
	fx.centered = false
	fx.offset = Vector2(0, -FLAME.get_height() / 2.0)
	fx.global_position = rig.fist_position() + Vector2(10 * facing, 0)
	fx.scale = Vector2(0.25 * facing, 0.25)
	fx.z_index = 5
	get_parent().add_child(fx)
	var tween := fx.create_tween().set_parallel()
	tween.tween_property(fx, "scale", Vector2(0.5 * facing, 0.5), punch_time)
	tween.tween_property(fx, "modulate:a", 0.0, punch_time).set_delay(0.08)
	tween.chain().tween_callback(fx.queue_free)
