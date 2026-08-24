extends Node2D

## base_level.gd - Shared base logic for all levels in PEARL OF SOUTHEAST

@export var level_music: AudioStream = null
@export var level_objective: String = "Explore and find the artifact"
@export var next_level_path: String = ""

@onready var hud: CanvasLayer = $HUD
@onready var pause_menu: Control = $PauseMenu
@onready var player_spawn: Marker2D = $PlayerSpawn

var player_instance: CharacterBody2D = null
var player_scene: PackedScene = preload("res://scenes/player/Player.tscn")
var game_over_scene: PackedScene = preload("res://scenes/ui/GameOver.tscn")

func _ready() -> void:
	# Spawn player at designated spawn marker
	player_instance = player_scene.instantiate()
	if player_spawn:
		player_instance.global_position = player_spawn.global_position
	add_child(player_instance)

	# Connect HUD to player
	if hud and hud.has_method("setup_player_connections"):
		hud.setup_player_connections(player_instance)
	if hud and hud.has_method("set_objective"):
		hud.set_objective(level_objective)

	# Connect player death
	if player_instance and player_instance.has_signal("player_died"):
		player_instance.player_died.connect(_on_player_died)

	# Start level music
	if level_music and AudioManager:
		AudioManager.play_music(level_music)

func _on_player_died() -> void:
	await get_tree().create_timer(0.8).timeout
	var go = game_over_scene.instantiate()
	add_child(go)

func transition_to_next_level() -> void:
	if next_level_path and next_level_path != "":
		GameManager.change_level(next_level_path)
