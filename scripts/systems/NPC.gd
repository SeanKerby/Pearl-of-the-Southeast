extends Area2D

## NPC.gd - Interactive NPC character for PEARL OF SOUTHEAST

@export var npc_name: String = "Village Elder"
@export var npc_texture: Texture2D = null
@export_multiline var dialog_lines: Array[String] = [
	"Greetings, traveler! Welcome to our village.",
	"The sacred Forest Relic is kept in the chest near the southeastern oasis.",
	"Beware of the Jungle Boars to the west and Forest Spirits along the trees!",
	"Once you recover the artifact, head north to the ancient sanctuary to challenge the Forest Guardian and open the path to the coast!"
]

@onready var prompt_label: Label = $PromptLabel
@onready var sprite: Sprite2D = $Sprite2D

var player_near: bool = false
var current_line_idx: int = 0
var is_talking: bool = false

signal dialog_started(npc_name: String, text: String)
signal dialog_advanced(npc_name: String, text: String)
signal dialog_ended()

func _ready() -> void:
	add_to_group("interactable")
	if npc_texture and sprite:
		sprite.texture = npc_texture
	prompt_label.visible = false
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_near = true
		prompt_label.visible = true

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_near = false
		prompt_label.visible = false
		if is_talking:
			_end_dialog()

func interact(_caller: Node) -> void:
	if not is_talking:
		_start_dialog()
	else:
		_advance_dialog()

func _start_dialog() -> void:
	is_talking = true
	current_line_idx = 0
	prompt_label.text = "Press E to continue..."
	var hud = get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("show_dialog"):
		hud.show_dialog(npc_name, dialog_lines[current_line_idx], npc_texture)

func _advance_dialog() -> void:
	current_line_idx += 1
	if current_line_idx < dialog_lines.size():
		var hud = get_tree().get_first_node_in_group("hud")
		if hud and hud.has_method("show_dialog"):
			hud.show_dialog(npc_name, dialog_lines[current_line_idx], npc_texture)
	else:
		_end_dialog()

func _end_dialog() -> void:
	is_talking = false
	prompt_label.text = "Press E to Talk"
	var hud = get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("hide_dialog"):
		hud.hide_dialog()
