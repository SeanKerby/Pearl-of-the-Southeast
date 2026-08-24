extends Node2D

## FinalArea.gd - Artifact Restoration Point + Victory trigger

@onready var hud: CanvasLayer = $HUD
@onready var player_spawn: Marker2D = $PlayerSpawn
@onready var restoration_area: Area2D = $RestorationPoint/RestorationArea
@onready var restoration_label: Label = $RestorationPoint/RestorationLabel

var player_instance: CharacterBody2D = null
var player_scene: PackedScene = preload("res://scenes/player/Player.tscn")
var game_over_scene: PackedScene = preload("res://scenes/ui/GameOver.tscn")
var victory_scene: PackedScene = preload("res://scenes/ui/Victory.tscn")
var restored: bool = false

func _ready() -> void:
	player_instance = player_scene.instantiate()
	player_instance.global_position = player_spawn.global_position
	add_child(player_instance)

	if hud:
		hud.setup_player_connections(player_instance)
		if InventoryManager.is_all_collected():
			hud.set_objective("Place all three artifacts at the Restoration Point")
		else:
			hud.set_objective("You need all three artifacts first!")

	player_instance.player_died.connect(_on_player_died)

	if restoration_area:
		restoration_area.body_entered.connect(_on_player_near_restoration)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and not event.is_echo():
		GameManager.toggle_pause()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("interact") and not event.is_echo():
		_try_restore()
		get_viewport().set_input_as_handled()

func _on_player_near_restoration(body: Node2D) -> void:
	if body.is_in_group("player"):
		if InventoryManager.is_all_collected():
			if hud:
				hud.show_notification("Press E to restore the Pearl of Southeast!")
		else:
			var missing = 3 - InventoryManager.get_collected_count()
			if hud:
				hud.show_notification("You need %d more artifact(s) to restore the connection." % missing)

func _try_restore() -> void:
	if restored:
		return
	if not InventoryManager.is_all_collected():
		if hud:
			hud.show_notification("You need all three artifacts.\nReturn and find the missing ones.")
		return

	# Check player is near restoration area
	var overlapping = restoration_area.get_overlapping_bodies()
	var player_near = false
	for body in overlapping:
		if body.is_in_group("player"):
			player_near = true
			break

	if not player_near:
		return

	restored = true
	_play_restoration_sequence()

func _play_restoration_sequence() -> void:
	if hud:
		hud.show_notification("All three artifacts have been restored.\nThe connection lives again!")

	if restoration_label:
		restoration_label.text = "✦ RESTORED ✦"
		restoration_label.add_theme_color_override("font_color", Color(1, 0.9, 0.3, 1))

	# Dramatic pause then victory
	await get_tree().create_timer(3.0).timeout
	SaveManager.save_game()
	GameManager.trigger_victory()
	var v = victory_scene.instantiate()
	add_child(v)

func _on_player_died() -> void:
	await get_tree().create_timer(0.8).timeout
	var go = game_over_scene.instantiate()
	add_child(go)
