extends Node
## Fighting, skills, EXP and level ups for the mine test map.
##
##   Left click a monster   = walk to it and punch it (auto attack)
##   1 = Flame Burst   (fire on your target)
##   2 = Blaze Ring    (fire all around you)
##   3 = First Aid     (heal yourself)
##   Esc = stop attacking
##
## The player's numbers (HP, MP, level, EXP) live here; the HUD reads them.

signal logged(text: String, color: Color)
signal leveled_up(kind: String, level: int)

@export var player: CharacterBody3D
@export var player_name := "Benika"

const SKILLS := {
	"flame_burst": {name = "Flame Burst", key = KEY_1, mp = 10, cooldown = 1.5, cast = 0.6},
	"blaze_ring": {name = "Blaze Ring", key = KEY_2, mp = 18, cooldown = 4.0, cast = 0.9},
	"first_aid": {name = "First Aid", key = KEY_3, mp = 8, cooldown = 3.0, cast = 0.5},
}
const FIRE_RED := Color(1.0, 0.35, 0.2)
const HEAL_GREEN := Color(0.4, 1.0, 0.6)
const LEVEL_GOLD := Color(1.0, 0.8, 0.35)
const JOB_BLUE := Color(0.4, 0.75, 1.0)

var base_level := 9
var job_level := 5
var base_exp := 0
var job_exp := 0
var max_hp := 420
var hp := 420
var max_mp := 120
var mp := 120
var stats := {STR = 14, DEX = 10, INT = 8, VIT = 12, AGI = 11, MAG = 6}

var target: Monster = null
var attacking := false
var cooldowns := {}  # skill id -> seconds left

var _punch_wait := 0.0
var _casting := 0.0
var _regen_wait := 0.0
var _out_of_combat := 0.0


func _ready() -> void:
	base_exp = int(need_base_exp() * 0.72)
	job_exp = int(need_job_exp() * 0.55)
	for id in SKILLS:
		cooldowns[id] = 0.0
	player.hit.connect(_on_player_hit)
	for monster in get_tree().get_nodes_in_group("monsters"):
		monster.died.connect(_on_monster_died)
	_add_name_tag()


func need_base_exp() -> int:
	return 1000 + base_level * 100


func need_job_exp() -> int:
	return 700 + job_level * 60


func say(text: String, color := Color("#e8e3d8")) -> void:
	logged.emit(text, color)


func _add_name_tag() -> void:
	var tag := Label3D.new()
	tag.text = player_name
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tag.fixed_size = true
	tag.no_depth_test = true
	tag.pixel_size = 0.0005
	tag.font_size = 32
	tag.outline_size = 10
	tag.modulate = Color("#fff4dc")
	tag.outline_modulate = Color(0, 0, 0, 0.9)
	tag.position.y = 1.75
	player.add_child(tag)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var monster := _monster_under_mouse(event.position)
		if monster:
			target = monster
			attacking = true
			get_viewport().set_input_as_handled()
		else:
			attacking = false  # clicked the ground: just walk there
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			attacking = false
			target = null
			return
		for id in SKILLS:
			if event.keycode == SKILLS[id].key:
				use_skill(id)
				get_viewport().set_input_as_handled()


func _monster_under_mouse(screen_pos: Vector2) -> Monster:
	var camera := get_viewport().get_camera_3d()
	var from := camera.project_ray_origin(screen_pos)
	var to := from + camera.project_ray_normal(screen_pos) * 200.0
	var query := PhysicsRayQueryParameters3D.create(from, to, 4)
	var hit := player.get_world_3d().direct_space_state.intersect_ray(query)
	return hit.collider as Monster if hit else null


func _physics_process(delta: float) -> void:
	for id in cooldowns:
		cooldowns[id] = maxf(cooldowns[id] - delta, 0.0)
	if target and not target.alive:
		target = null
		attacking = false

	if _casting > 0.0:
		_casting -= delta
		if _casting <= 0.0:
			player.frozen = false

	_out_of_combat += delta
	if attacking and target and _casting <= 0.0:
		_out_of_combat = 0.0
		var dist := _flat_distance(player.global_position, target.global_position)
		if dist > 1.45:
			player.walk_to(target.global_position)
		else:
			player.stop_walking()
			player.face_towards(target.global_position)
			_punch_wait -= delta
			if _punch_wait <= 0.0:
				_punch_wait = 0.9
				_punch()

	# Slowly get HP and MP back, faster when not fighting.
	_regen_wait -= delta
	if _regen_wait <= 0.0:
		_regen_wait = 1.0
		var rest := 3.0 if _out_of_combat > 4.0 else 1.0
		hp = mini(hp + int(max_hp * 0.006 * rest) + 1, max_hp)
		mp = mini(mp + int(rest) + 1, max_mp)


func _flat_distance(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


func _punch() -> void:
	var damage: int = randi_range(9, 14) + stats.STR / 3
	var critical := randf() < 0.15
	if critical:
		damage = int(damage * 1.8)
	var hit_pos := target.global_position + Vector3(0, 0.6, 0)
	Fx.sparkles(get_tree().current_scene, hit_pos, FIRE_RED, 12)
	Fx.damage_number(get_tree().current_scene, target.global_position + Vector3(0, 1.4, 0),
			str(damage) + ("!" if critical else ""), Color("#ffd27a") if critical else Color.WHITE, critical)
	target.take_damage(damage, player)


func use_skill(id: String) -> void:
	var skill: Dictionary = SKILLS[id]
	if _casting > 0.0 or cooldowns[id] > 0.0:
		return
	if mp < skill.mp:
		say("Not enough MP for %s." % skill.name, Color("#ff9a9a"))
		return

	var scene := get_tree().current_scene
	var feet := player.global_position
	match id:
		"flame_burst":
			var foe := _pick_target(8.0)
			if foe == null:
				say("No monster close enough.", Color("#ff9a9a"))
				return
			target = foe
			attacking = true
			player.face_towards(foe.global_position)
			Fx.magic_circle(scene, feet, FIRE_RED, 0.8, skill.cast + 0.2)
			_after(skill.cast, func() -> void:
				if not foe.alive:
					return
				Fx.fire(scene, foe.global_position, 0.5)
				Fx.magic_circle(scene, foe.global_position, Color(1.0, 0.55, 0.2), 0.7, 0.6)
				var damage: int = randi_range(38, 52) + stats.INT * 2
				Fx.damage_number(scene, foe.global_position + Vector3(0, 1.5, 0), str(damage), Color("#ffb347"), true)
				foe.take_damage(damage, player))
		"blaze_ring":
			Fx.magic_circle(scene, feet, Color(1.0, 0.3, 0.15), 1.6, skill.cast + 0.4)
			_after(skill.cast, func() -> void:
				Fx.fire(scene, feet, 0.4)
				Fx.sparkles(scene, feet + Vector3(0, 0.3, 0), Color(1.0, 0.5, 0.2), 60)
				var hit_any := false
				for monster in get_tree().get_nodes_in_group("monsters"):
					if monster.alive and _flat_distance(monster.global_position, feet) < 2.5:
						var damage: int = randi_range(25, 35) + stats.INT
						Fx.damage_number(scene, monster.global_position + Vector3(0, 1.4, 0), str(damage), Color("#ffb347"))
						monster.take_damage(damage, player)
						hit_any = true
				if not hit_any:
					say("Blaze Ring hit nothing.", Color("#bdb6a8")))
		"first_aid":
			Fx.magic_circle(scene, feet, HEAL_GREEN, 0.8, skill.cast + 0.4)
			Fx.sparkles(scene, feet, HEAL_GREEN, 30, true)
			_after(skill.cast, func() -> void:
				var amount: int = 60 + stats.VIT * 3
				hp = mini(hp + amount, max_hp)
				Fx.damage_number(scene, player.global_position + Vector3(0, 1.6, 0), "+%d" % amount, HEAL_GREEN))

	mp -= skill.mp
	cooldowns[id] = skill.cooldown
	_casting = skill.cast
	player.frozen = true
	_out_of_combat = 0.0


## The current target if it is close, otherwise the closest monster.
func _pick_target(max_range: float) -> Monster:
	if target and target.alive and _flat_distance(target.global_position, player.global_position) <= max_range:
		return target
	var best: Monster = null
	var best_dist := max_range
	for monster in get_tree().get_nodes_in_group("monsters"):
		var d := _flat_distance(monster.global_position, player.global_position)
		if monster.alive and d <= best_dist:
			best = monster
			best_dist = d
	return best


func _after(seconds: float, action: Callable) -> void:
	get_tree().create_timer(seconds).timeout.connect(action)


func _on_player_hit(amount: int, _from: Node3D) -> void:
	_out_of_combat = 0.0
	hp = maxi(hp - amount, 0)
	Fx.damage_number(get_tree().current_scene, player.global_position + Vector3(0, 1.6, 0), str(amount), Color("#ff5a5a"))
	if hp == 0:
		say("You fainted! Back to the mine entrance.", Color("#ff9a9a"))
		attacking = false
		target = null
		player.stop_walking()
		player.global_position = Vector3(0, 0.1, 0)
		hp = max_hp
		mp = max_mp


func _on_monster_died(monster: Monster) -> void:
	var b := monster.base_exp
	var j := monster.job_exp
	say("Defeated %s." % monster.monster_name, Color("#ffd27a"))
	say("Got Base EXP %d, Job EXP %d" % [b, j], Color("#9be38a"))
	base_exp += b
	job_exp += j
	while base_exp >= need_base_exp():
		base_exp -= need_base_exp()
		_base_level_up()
	while job_exp >= need_job_exp():
		job_exp -= need_job_exp()
		_job_level_up()


func _base_level_up() -> void:
	base_level += 1
	max_hp += 38
	max_mp += 9
	hp = max_hp
	mp = max_mp
	var scene := get_tree().current_scene
	var feet := player.global_position
	Fx.light_pillar(scene, feet, LEVEL_GOLD, 0.9, 6.0, 1.6)
	Fx.magic_circle(scene, feet, LEVEL_GOLD, 1.0, 1.6)
	Fx.sparkles(scene, feet + Vector3(0, 0.2, 0), LEVEL_GOLD, 70, true, 1.6)
	Fx.sparkles(scene, feet + Vector3(0, 1.0, 0), Color(1.0, 0.95, 0.7), 40)
	say("Base Level up! You are now Lv %d." % base_level, LEVEL_GOLD)
	say("HP and MP are full. You got 3 status points.", LEVEL_GOLD)
	leveled_up.emit("base", base_level)


func _job_level_up() -> void:
	job_level += 1
	var raised: String = ["STR", "INT", "VIT", "DEX"][job_level % 4]
	stats[raised] += 1
	var scene := get_tree().current_scene
	Fx.light_pillar(scene, player.global_position, JOB_BLUE, 0.7, 5.0, 1.2)
	Fx.sparkles(scene, player.global_position, JOB_BLUE, 40, true)
	say("Job Level up! You are now Job Lv %d." % job_level, JOB_BLUE)
	say("%s increased by 1." % raised, JOB_BLUE)
	leveled_up.emit("job", job_level)
