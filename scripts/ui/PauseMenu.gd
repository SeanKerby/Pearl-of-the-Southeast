extends Control

## PauseMenu.gd - Pause overlay for PEARL OF SOUTHEAST

@onready var resume_btn: Button = %ResumeButton
@onready var inventory_btn: Button = %InventoryButton
@onready var save_btn: Button = %SaveButton
@onready var main_menu_btn: Button = %MainMenuButton

@onready var inventory_panel: Control = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	visible = false
	resume_btn.pressed.connect(_on_resume)
	inventory_btn.pressed.connect(_on_inventory)
	save_btn.pressed.connect(_on_save)
	main_menu_btn.pressed.connect(_on_main_menu)

	GameManager.game_paused.connect(_on_game_paused)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and not event.is_echo():
		GameManager.toggle_pause()
		get_viewport().set_input_as_handled()

func _on_game_paused(is_paused: bool) -> void:
	visible = is_paused

func _on_resume() -> void:
	GameManager.toggle_pause()

func _on_inventory() -> void:
	# Inventory is spawned as a sibling CanvasLayer by HUD.gd
	var hud = get_parent().get_node_or_null("HUD")
	if hud and hud.get("inventory_node") and hud.inventory_node.has_method("toggle"):
		hud.inventory_node.toggle()
		return
	# Fallback: search the whole scene tree
	var inv = get_tree().get_first_node_in_group("inventory_ui")
	if inv and inv.has_method("toggle"):
		inv.toggle()

func _on_save() -> void:
	if SaveManager:
		SaveManager.save_game()
		_show_save_feedback()

func _show_save_feedback() -> void:
	save_btn.text = "SAVED!"
	await get_tree().create_timer(1.2).timeout
	save_btn.text = "SAVE GAME"

func _on_main_menu() -> void:
	GameManager.is_game_paused = false
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu/MainMenu.tscn")
