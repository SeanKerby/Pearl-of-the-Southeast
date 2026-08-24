extends Node2D

## Level1_Forest.gd - Level 1: The Whispering Forest (TROPICAL WORD ADVENTURE)

@onready var hud: CanvasLayer = $HUD
@onready var pause_menu: Control = $PauseMenu
@onready var player_spawn: Marker2D = $PlayerSpawn
@onready var exit_area: Area2D = $ExitArea
@onready var boss_node: CharacterBody2D = get_node_or_null("Enemies/ForestGuardianBoss")

var player_instance: CharacterBody2D = null
var player_scene: PackedScene = preload("res://scenes/player/Player.tscn")
var game_over_scene: PackedScene = preload("res://scenes/ui/GameOver.tscn")

var artifact_collected: bool = false
var boss_defeated: bool = false
var tutorial_shown: bool = false

func _ready() -> void:
	# 1. Spawn player at Start Point
	_spawn_player()

	# 2. Lock exit gate until objectives are met
	if exit_area:
		exit_area.monitoring = false
		exit_area.body_entered.connect(_on_exit_entered)

	# 3. Connect inventory signals
	if InventoryManager:
		InventoryManager.artifact_collected.connect(_on_artifact_collected)

	# 4. Connect boss death signal if boss exists
	if boss_node and boss_node.has_signal("boss_defeated"):
		boss_node.boss_defeated.connect(_on_boss_defeated)

	# 5. Set tutorial objective
	if hud:
		hud.set_objective(
			"1. Speak to the Village Elder\n" +
			"2. Explore the forest and defeat enemies\n" +
			"3. Find the Forest Relic at the Ancient Chest\n" +
			"4. Defeat the Forest Guardian Boss"
		)
		await get_tree().create_timer(0.5).timeout
		hud.show_notification(
			"📜 The Whispering Forest\n" +
			"Words are your weapons — approach enemies to start a Word Battle!"
		)

func _spawn_player() -> void:
	player_instance = player_scene.instantiate()
	player_instance.global_position = player_spawn.global_position
	add_child(player_instance)

	if hud:
		hud.setup_player_connections(player_instance)

	var cam: Camera2D = player_instance.get_node_or_null("Camera2D")
	if cam:
		cam.limit_left = 0
		cam.limit_top = 0
		cam.limit_right = 1018
		cam.limit_bottom = 571

	player_instance.player_died.connect(_on_player_died)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and not event.is_echo():
		GameManager.toggle_pause()
		get_viewport().set_input_as_handled()

# ── Tutorial hint shown on first interaction ────────────────────────────────

func _show_first_battle_tip() -> void:
	if tutorial_shown:
		return
	tutorial_shown = true
	if hud:
		hud.show_notification(
			"⚔️ WORD BATTLE!\n" +
			"Select letter tiles to form words.\n" +
			"Longer, elemental words deal more damage!"
		)

# ── Artifact / Boss events ───────────────────────────────────────────────────

func _on_artifact_collected(artifact_id: String, _aname: String) -> void:
	if artifact_id == "forest_relic":
		artifact_collected = true
		if hud:
			hud.show_notification(
				"✦ Forest Relic Acquired!\n" +
				"Now defeat the Forest Guardian to open the path!"
			)
			if not boss_defeated:
				hud.set_objective("Defeat the Forest Guardian Boss near the Ancient Shrine!")
			else:
				_unlock_exit()

func _on_boss_defeated() -> void:
	boss_defeated = true
	if hud:
		hud.show_notification(
			"🏆 Forest Guardian Defeated!\n" +
			"The northern gateway has opened!"
		)
		hud.set_objective("The path is clear — head to the northern gateway!")
	_unlock_exit()

func _unlock_exit() -> void:
	if exit_area:
		exit_area.monitoring = true
	if hud:
		hud.set_objective("Path Clear! Proceed to the northern gateway → Level 2")

func _on_exit_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if artifact_collected or boss_defeated:
			if SaveManager:
				SaveManager.save_game()
			if hud:
				hud.show_notification("🌊 Entering Level 2: Sunken Coast...")
			await get_tree().create_timer(1.2).timeout
			GameManager.change_level("res://scenes/levels/Level2_Coastal.tscn")
		else:
			if hud:
				hud.show_notification(
					"🔒 The gate is sealed!\n" +
					"Find the Forest Relic and defeat the Forest Guardian first."
				)

func _on_player_died() -> void:
	await get_tree().create_timer(0.8).timeout
	var go = game_over_scene.instantiate()
	add_child(go)
