extends Node2D

## Level3_Ruins.gd - Cave and Ancient Ruins level controller

@onready var hud: CanvasLayer = $HUD
@onready var player_spawn: Marker2D = $PlayerSpawn
@onready var exit_area: Area2D = $ExitArea

var player_instance: CharacterBody2D = null
var player_scene: PackedScene = preload("res://scenes/player/Player.tscn")
var game_over_scene: PackedScene = preload("res://scenes/ui/GameOver.tscn")
var artifact_collected: bool = false

func _ready() -> void:
	player_instance = player_scene.instantiate()
	player_instance.global_position = player_spawn.global_position
	add_child(player_instance)

	if hud:
		hud.setup_player_connections(player_instance)
		hud.set_objective("Explore the ancient ruins and claim the Ancient Stone")

	player_instance.player_died.connect(_on_player_died)

	if exit_area:
		exit_area.monitoring = false
		exit_area.body_entered.connect(_on_exit_entered)

	if InventoryManager:
		InventoryManager.artifact_collected.connect(_on_artifact_collected)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and not event.is_echo():
		GameManager.toggle_pause()
		get_viewport().set_input_as_handled()

func _on_artifact_collected(artifact_id: String, _aname: String) -> void:
	if artifact_id == "ancient_stone":
		artifact_collected = true
		if exit_area:
			exit_area.monitoring = true
		if hud:
			hud.set_objective("Ancient Stone found! All artifacts collected — enter the Final Sanctuary!")

func _on_exit_entered(body: Node2D) -> void:
	if body.is_in_group("player") and artifact_collected:
		SaveManager.save_game()
		GameManager.change_level("res://scenes/levels/FinalArea.tscn")

func _on_player_died() -> void:
	await get_tree().create_timer(0.8).timeout
	var go = game_over_scene.instantiate()
	add_child(go)
