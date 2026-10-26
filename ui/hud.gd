extends CanvasLayer
## The on-screen interface: status window, chat log, talk prompt,
## NPC dialogue box and the wardrobe window.

@export var player: CharacterBody3D
@export var player_name := "Adventurer"
@export var talk_distance := 2.2

@onready var name_label: Label = %NameLabel
@onready var chat: RichTextLabel = %Chat
@onready var prompt: PanelContainer = %Prompt
@onready var prompt_label: Label = %PromptLabel
@onready var dialogue: PanelContainer = %Dialogue
@onready var dialogue_name: Label = %DialogueName
@onready var dialogue_text: Label = %DialogueText
@onready var wardrobe: PanelContainer = %Wardrobe
@onready var help: Label = %Help

var _talking_to: Node3D = null
var _line := 0


func _ready() -> void:
	name_label.text = player_name
	wardrobe.chibi = player.model
	wardrobe.hide()
	dialogue.hide()
	prompt.hide()
	%WardrobeButton.pressed.connect(_toggle_wardrobe)
	dialogue.gui_input.connect(_on_dialogue_input)
	say("System", "Welcome to Petalbrook!")
	say("System", "Walk with WASD or click the ground. Hold the right mouse button to turn the camera.")
	say("System", "Press C to open your wardrobe. Press F near someone to talk.")


## Adds a line to the chat log.
func say(who: String, text: String) -> void:
	var color := "#7e4a20" if who == "System" else "#4c8fd6"
	chat.append_text("[color=%s][b]%s:[/b][/color] %s\n" % [color, who, text])


func _process(_delta: float) -> void:
	if _talking_to:
		prompt.hide()
		return
	var npc := _nearest_npc()
	prompt.visible = npc != null
	if npc:
		prompt_label.text = "[F] Talk to %s" % npc.npc_name


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("wardrobe"):
		_toggle_wardrobe()
	elif event.is_action_pressed("interact"):
		if _talking_to:
			_next_line()
		else:
			var npc := _nearest_npc()
			if npc:
				_start_dialogue(npc)
	elif event.is_action_pressed("ui_cancel"):
		if _talking_to:
			_end_dialogue()
		else:
			wardrobe.hide()


func _toggle_wardrobe() -> void:
	wardrobe.visible = not wardrobe.visible


func _nearest_npc() -> Node3D:
	var best: Node3D = null
	var best_distance := talk_distance
	for npc: Node3D in get_tree().get_nodes_in_group("npcs"):
		var d := npc.global_position.distance_to(player.global_position)
		if d < best_distance:
			best = npc
			best_distance = d
	return best


func _start_dialogue(npc: Node3D) -> void:
	_talking_to = npc
	_line = 0
	npc.start_talking(player.global_position)
	player.face_towards(npc.global_position)
	player.frozen = true
	dialogue_name.text = npc.npc_name
	dialogue_text.text = npc.lines[0]
	dialogue.show()
	help.hide()


func _next_line() -> void:
	_line += 1
	if _line >= _talking_to.lines.size():
		_end_dialogue()
	else:
		dialogue_text.text = _talking_to.lines[_line]


func _end_dialogue() -> void:
	say(_talking_to.npc_name, _talking_to.lines[-1])
	_talking_to.stop_talking()
	_talking_to = null
	player.frozen = false
	dialogue.hide()
	help.show()


func _on_dialogue_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_next_line()
