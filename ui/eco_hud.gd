extends CanvasLayer
## The classic MMO screen layout from the ECO reference video, with our own look:
##   top left    = status window (level, HP, MP, EXP)
##   top middle  = two rows of skill hotkeys, and the target's HP under them
##   top right   = minimap
##   bottom left = chat / battle log
## Everything is built in code so it is easy to read in one place.

const MineMap := preload("res://world/mine_map.gd")

@export var battle: Node
@export var player: Node3D
@export var map_name := "Ore Mine B1"

const PANEL_BG := Color(0.06, 0.07, 0.11, 0.82)
const PANEL_EDGE := Color(0.85, 0.68, 0.38, 0.9)
const TEXT := Color("#f2ead9")
const DIM_TEXT := Color("#a79f90")

var _hp_bar: ProgressBar
var _mp_bar: ProgressBar
var _exp_bar: ProgressBar
var _job_bar: ProgressBar
var _hp_text: Label
var _mp_text: Label
var _exp_text: Label
var _job_text: Label
var _level_text: Label
var _log: RichTextLabel
var _target_panel: PanelContainer
var _target_name: Label
var _target_bar: ProgressBar
var _slots := {}  # skill id -> SkillSlot
var _minimap: Control


func _ready() -> void:
	_build_status()
	_build_hotbar()
	_build_target()
	_build_minimap()
	_build_log()
	_build_help()
	battle.logged.connect(_add_log)
	battle.leveled_up.connect(_flash_level)
	_add_log("Welcome to the %s." % map_name, Color("#ffd27a"))
	_add_log("Click a monster to fight it. Keys 1, 2, 3 use skills.", DIM_TEXT)


func _process(_delta: float) -> void:
	_set_bar(_hp_bar, _hp_text, battle.hp, battle.max_hp, "%d / %d" % [battle.hp, battle.max_hp])
	_set_bar(_mp_bar, _mp_text, battle.mp, battle.max_mp, "%d / %d" % [battle.mp, battle.max_mp])
	var base_pct: float = 100.0 * battle.base_exp / battle.need_base_exp()
	var job_pct: float = 100.0 * battle.job_exp / battle.need_job_exp()
	_set_bar(_exp_bar, _exp_text, base_pct, 100.0, "%.1f%%" % base_pct)
	_set_bar(_job_bar, _job_text, job_pct, 100.0, "%.1f%%" % job_pct)
	_level_text.text = "Lv %d   Job Lv %d" % [battle.base_level, battle.job_level]

	for id in _slots:
		var slot: SkillSlot = _slots[id]
		slot.cooldown = battle.cooldowns[id] / battle.SKILLS[id].cooldown
		slot.no_mana = battle.mp < battle.SKILLS[id].mp
		slot.queue_redraw()

	var target: Monster = battle.target
	_target_panel.visible = target != null
	if target:
		_target_name.text = target.monster_name
		_target_bar.max_value = target.max_hp
		_target_bar.value = target.hp
	_minimap.queue_redraw()


func _set_bar(bar: ProgressBar, label: Label, value: float, max_value: float, text: String) -> void:
	bar.max_value = max_value
	bar.value = value
	label.text = text


# ----------------------------------------------------------------------------
# Building the windows
# ----------------------------------------------------------------------------

func _panel(pos: Vector2, size: Vector2, anchor := Control.PRESET_TOP_LEFT) -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL_BG
	style.border_color = PANEL_EDGE
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	style.shadow_color = Color(0, 0, 0, 0.35)
	style.shadow_size = 4
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)
	_place(panel, anchor, pos, size)
	return panel


## Pins a window to a corner or edge of the screen. "pos" is measured from
## that corner, so it stays in place when the window is resized.
func _place(control: Control, anchor: Control.LayoutPreset, pos: Vector2, size: Vector2) -> void:
	control.set_anchors_preset(anchor)
	control.offset_left = pos.x
	control.offset_top = pos.y
	control.offset_right = pos.x + size.x
	control.offset_bottom = pos.y + size.y


func _label(text: String, size := 13, color := TEXT) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	label.add_theme_constant_override("outline_size", 3)
	return label


## A thin coloured bar with a name on the left and numbers on top.
func _bar_row(parent: Control, title: String, color: Color, height := 14) -> Array:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	parent.add_child(row)
	var name_label := _label(title, 12, DIM_TEXT)
	name_label.custom_minimum_size.x = 30
	row.add_child(name_label)

	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, height)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.02, 0.02, 0.04, 0.9)
	bg.set_corner_radius_all(3)
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	fill.set_corner_radius_all(3)
	fill.border_color = color.lightened(0.35)
	fill.border_width_top = 2
	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fill)
	row.add_child(bar)

	var numbers := _label("", 11)
	numbers.set_anchors_preset(Control.PRESET_FULL_RECT)
	numbers.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	numbers.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	bar.add_child(numbers)
	return [bar, numbers]


func _build_status() -> void:
	var panel := _panel(Vector2(10, 10), Vector2(270, 0))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 3)
	panel.add_child(box)

	var top := HBoxContainer.new()
	box.add_child(top)
	var badge := _label(" FIRE ", 11, Color.WHITE)
	var badge_bg := StyleBoxFlat.new()
	badge_bg.bg_color = Color("#c8322b")
	badge_bg.set_corner_radius_all(3)
	badge.add_theme_stylebox_override("normal", badge_bg)
	top.add_child(badge)
	top.add_child(_label("  " + battle.player_name, 15))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(spacer)
	_level_text = _label("", 13, Color("#ffd27a"))
	top.add_child(_level_text)

	var r := _bar_row(box, "HP", Color("#d8383f"))
	_hp_bar = r[0]
	_hp_text = r[1]
	r = _bar_row(box, "MP", Color("#3f74d8"))
	_mp_bar = r[0]
	_mp_text = r[1]
	r = _bar_row(box, "EXP", Color("#58b84a"), 10)
	_exp_bar = r[0]
	_exp_text = r[1]
	r = _bar_row(box, "JOB", Color("#3fb0c0"), 10)
	_job_bar = r[0]
	_job_text = r[1]


func _build_hotbar() -> void:
	var slot_size := 40.0
	var width := slot_size * 10 + 4 * 9 + 16
	var panel := _panel(Vector2(-width * 0.5, 10), Vector2(width, 0), Control.PRESET_CENTER_TOP)
	var grid := GridContainer.new()
	grid.columns = 10
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)
	panel.add_child(grid)

	var skill_ids: Array = battle.SKILLS.keys()
	for i in 20:
		var slot := SkillSlot.new()
		slot.custom_minimum_size = Vector2(slot_size, slot_size)
		slot.key_text = str((i + 1) % 10) if i < 10 else ""
		if i < skill_ids.size():
			var id: String = skill_ids[i]
			slot.skill = id
			slot.tooltip_text = "%s (MP %d)" % [battle.SKILLS[id].name, battle.SKILLS[id].mp]
			slot.gui_input.connect(func(event: InputEvent) -> void:
				if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
					battle.use_skill(id))
			_slots[id] = slot
		grid.add_child(slot)


func _build_target() -> void:
	_target_panel = _panel(Vector2(-130, 110), Vector2(260, 0), Control.PRESET_CENTER_TOP)
	var box := VBoxContainer.new()
	_target_panel.add_child(box)
	_target_name = _label("", 13, Color("#ff9a9a"))
	_target_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_target_name)
	var r := _bar_row(box, "", Color("#d8383f"), 10)
	_target_bar = r[0]
	r[1].hide()


func _build_minimap() -> void:
	var panel := _panel(Vector2(-190, 10), Vector2(180, 0), Control.PRESET_TOP_RIGHT)
	var box := VBoxContainer.new()
	panel.add_child(box)
	var title := _label(map_name, 12, Color("#ffd27a"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	_minimap = Control.new()
	_minimap.custom_minimum_size = Vector2(164, 164)
	_minimap.clip_contents = true
	_minimap.draw.connect(_draw_minimap)
	box.add_child(_minimap)


func _draw_minimap() -> void:
	var size := _minimap.size
	var half: float = MineMap.HALF_SIZE
	var to_map := func(p: Vector3) -> Vector2:
		return Vector2((p.x + half) / (half * 2.0) * size.x, (p.z + half) / (half * 2.0) * size.y)
	_minimap.draw_rect(Rect2(Vector2.ZERO, size), Color(0.16, 0.16, 0.19))
	_minimap.draw_rect(Rect2(Vector2.ZERO, size), Color(0.35, 0.33, 0.38), false, 2.0)
	var rail_x: float = to_map.call(Vector3(MineMap.RAIL_X, 0, 0)).x
	_minimap.draw_line(Vector2(rail_x, 0), Vector2(rail_x, size.y), Color(0.55, 0.55, 0.6), 2.0)
	for g in MineMap.GIRDERS:
		_minimap.draw_rect(Rect2(to_map.call(Vector3(g[0], 0, g[1])) - Vector2(3, 3), Vector2(6, 6)), Color("#9e2228"))
	for c in MineMap.CRYSTALS:
		_minimap.draw_circle(to_map.call(Vector3(c[0], 0, c[1])), 3.0, Color("#5fd4ff"))
	for monster in get_tree().get_nodes_in_group("monsters"):
		if monster.alive:
			_minimap.draw_circle(to_map.call(monster.global_position), 3.0, Color("#ff6b6b"))
	# The player is a little arrow pointing where they face.
	var p: Vector2 = to_map.call(player.global_position)
	var facing: float = -player.model.rotation.y + PI
	var tip := p + Vector2(0, -7).rotated(facing)
	var left := p + Vector2(-4.5, 4.5).rotated(facing)
	var right := p + Vector2(4.5, 4.5).rotated(facing)
	_minimap.draw_colored_polygon(PackedVector2Array([tip, right, left]), Color("#fff4dc"))


func _build_log() -> void:
	var panel := _panel(Vector2(10, -190), Vector2(440, 180), Control.PRESET_BOTTOM_LEFT)
	var box := VBoxContainer.new()
	panel.add_child(box)
	box.add_child(_label("Log", 12, Color("#ffd27a")))
	_log = RichTextLabel.new()
	_log.bbcode_enabled = true
	_log.scroll_following = true
	_log.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_log.add_theme_font_size_override("normal_font_size", 12)
	_log.add_theme_constant_override("outline_size", 2)
	_log.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	box.add_child(_log)


func _add_log(text: String, color: Color) -> void:
	_log.append_text("[color=#%s]%s[/color]\n" % [color.to_html(false), text])


## Like ECO, a level up is quiet on screen: the light pillar around the
## character, a log line, and the level number glowing for a moment.
func _flash_level(_kind: String, _level: int) -> void:
	var tween := _level_text.create_tween()
	_level_text.modulate = Color(2.0, 1.8, 1.0)
	tween.tween_property(_level_text, "modulate", Color.WHITE, 1.5)


func _build_help() -> void:
	var help := _label("Click: walk / attack    1 2 3: skills    Esc: stop    Q E / right drag: turn    Wheel: zoom",
			12, DIM_TEXT)
	help.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_place(help, Control.PRESET_BOTTOM_RIGHT, Vector2(-760, -26), Vector2(750, 20))
	add_child(help)


# ----------------------------------------------------------------------------
# One hotkey box. Skill icons are drawn with shapes (our own simple art).
# ----------------------------------------------------------------------------

class SkillSlot extends Control:
	var skill := ""
	var key_text := ""
	var cooldown := 0.0  # 1 = just used, 0 = ready
	var no_mana := false

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		draw_rect(r, Color(0.02, 0.02, 0.05, 0.85))
		var c := size * 0.5
		match skill:
			"flame_burst":
				draw_rect(r.grow(-2), Color("#5a1810"))
				draw_circle(c + Vector2(0, 5), 11, Color("#ff5a1f"))
				draw_colored_polygon(PackedVector2Array([c + Vector2(-10, 4), c + Vector2(0, -15), c + Vector2(10, 4)]), Color("#ff5a1f"))
				draw_circle(c + Vector2(0, 7), 6, Color("#ffd166"))
			"blaze_ring":
				draw_rect(r.grow(-2), Color("#4a1408"))
				draw_arc(c, 13, 0, TAU, 24, Color("#ff7a2f"), 4.0)
				draw_arc(c, 6, 0, TAU, 16, Color("#ffd166"), 3.0)
			"first_aid":
				draw_rect(r.grow(-2), Color("#123a22"))
				draw_rect(Rect2(c - Vector2(4, 12), Vector2(8, 24)), Color("#7dffa0"))
				draw_rect(Rect2(c - Vector2(12, 4), Vector2(24, 8)), Color("#7dffa0"))
		if skill != "" and no_mana:
			draw_rect(r, Color(0.1, 0.15, 0.5, 0.5))
		if cooldown > 0.0:
			draw_rect(Rect2(0, 0, size.x, size.y * cooldown), Color(0, 0, 0, 0.65))
		draw_rect(r, Color(0.85, 0.68, 0.38, 0.55), false, 1.0)
		if key_text != "":
			var font := ThemeDB.fallback_font
			draw_string_outline(font, Vector2(3, 12), key_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, 3, Color.BLACK)
			draw_string(font, Vector2(3, 12), key_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color.WHITE)
