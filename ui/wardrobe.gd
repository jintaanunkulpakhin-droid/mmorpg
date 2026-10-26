extends PanelContainer
## The wardrobe window (press C). Every row is one outfit slot:
##   < >    switch to the previous / next item for that slot
##   Dye    click the colour square to try the next dye colour

var chibi: Chibi:
	set(value):
		chibi = value
		if is_node_ready():
			_refresh()

var _name_labels := {}  # slot -> Label
var _dye_buttons := {}  # slot -> Button


func _ready() -> void:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	add_child(box)

	var title := Label.new()
	title.text = "Wardrobe"
	title.add_theme_font_size_override("font_size", 22)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var note := Label.new()
	note.text = "Every piece fits every body: they share one skeleton."
	note.add_theme_font_size_override("font_size", 12)
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(note)

	var grid := GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	box.add_child(grid)
	for slot in OutfitCatalog.SLOTS + ["eyes"]:
		var label := Label.new()
		label.text = "Eyes" if slot == "eyes" else OutfitCatalog.SLOT_NAMES[slot]
		label.custom_minimum_size.x = 64
		grid.add_child(label)
		grid.add_child(_small_button("<", _step.bind(slot, -1)))
		var item_name := Label.new()
		item_name.custom_minimum_size.x = 150
		item_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		grid.add_child(item_name)
		_name_labels[slot] = item_name
		grid.add_child(_small_button(">", _step.bind(slot, 1)))
		var dye := Button.new()
		dye.custom_minimum_size = Vector2(36, 28)
		dye.tooltip_text = "Change colour"
		dye.pressed.connect(_next_dye.bind(slot))
		grid.add_child(dye)
		_dye_buttons[slot] = dye

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 12)
	box.add_child(buttons)
	buttons.add_child(_small_button("Random", _randomize))
	buttons.add_child(_small_button("Close (C)", hide))
	if chibi:
		_refresh()


func _small_button(text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(action)
	return button


func _step(slot: String, amount: int) -> void:
	if slot == "eyes":
		var colors := OutfitCatalog.EYE_COLORS
		var index := colors.find(chibi.eye_color)
		chibi.eye_color = colors[posmod(index + amount, colors.size())]
	else:
		var ids := OutfitCatalog.ids_for_slot(slot)
		var index := ids.find(chibi.get_item(slot))
		chibi.equip(slot, ids[posmod(index + amount, ids.size())])
		chibi.set_dye(slot, Color(0, 0, 0, 0))  # new item starts in its own colour
	_refresh()


func _next_dye(slot: String) -> void:
	if slot == "eyes":
		_step("eyes", 1)
		return
	var dyes := OutfitCatalog.DYES
	var index := -1
	for i in dyes.size():
		if dyes[i].is_equal_approx(chibi.get_dye(slot)):
			index = i
	chibi.set_dye(slot, dyes[posmod(index + 1, dyes.size())])
	_refresh()


func _randomize() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	chibi.randomize_outfit(rng)
	_refresh()


func _refresh() -> void:
	for slot in _name_labels:
		var color: Color
		if slot == "eyes":
			_name_labels[slot].text = "Eye colour"
			color = chibi.eye_color
		else:
			var id := chibi.get_item(slot)
			_name_labels[slot].text = OutfitCatalog.display_name(id)
			color = chibi.get_dye(slot)
		var style := StyleBoxFlat.new()
		style.bg_color = color
		style.border_color = Color("#7e4a20")
		style.set_border_width_all(3)
		style.set_corner_radius_all(6)
		var button: Button = _dye_buttons[slot]
		for state in ["normal", "hover", "pressed", "focus"]:
			button.add_theme_stylebox_override(state, style)
		button.disabled = slot != "eyes" and chibi.get_item(slot) == "none"
		button.modulate.a = 0.35 if button.disabled else 1.0
