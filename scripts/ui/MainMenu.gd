extends Control

## MainMenu.gd - Full Main Menu logic for PEARL OF SOUTHEAST

@onready var new_game_btn: Button = %NewGameButton
@onready var continue_btn: Button = %ContinueButton
@onready var settings_btn: Button = %SettingsButton
@onready var credits_btn: Button = %CreditsButton

@onready var settings_panel: PanelContainer = %SettingsPanel
@onready var credits_panel: PanelContainer = %CreditsPanel
@onready var close_settings_btn: Button = %CloseSettingsButton
@onready var close_credits_btn: Button = %CloseCreditsButton

@onready var music_slider: HSlider = %MusicSlider
@onready var sfx_slider: HSlider = %SFXSlider

func _ready() -> void:
	print("[MainMenu] Loaded.")
	
	# Update continue button based on save existence
	if continue_btn:
		var has_save = SaveManager.save_exists()
		continue_btn.disabled = not has_save
		if not has_save:
			continue_btn.tooltip_text = "No saved game found"

	# Connect main navigation buttons
	if new_game_btn:
		new_game_btn.pressed.connect(_on_new_game_pressed)
	if continue_btn:
		continue_btn.pressed.connect(_on_continue_pressed)
	if settings_btn:
		settings_btn.pressed.connect(_on_settings_pressed)
	if credits_btn:
		credits_btn.pressed.connect(_on_credits_pressed)

	# Connect popups
	if close_settings_btn:
		close_settings_btn.pressed.connect(func(): settings_panel.visible = false)
	if close_credits_btn:
		close_credits_btn.pressed.connect(func(): credits_panel.visible = false)

	# Audio sliders
	if music_slider:
		music_slider.value_changed.connect(_on_music_volume_changed)
	if sfx_slider:
		sfx_slider.value_changed.connect(_on_sfx_volume_changed)

	# Ensure popups are hidden at start
	if settings_panel:
		settings_panel.visible = false
	if credits_panel:
		credits_panel.visible = false

func _on_new_game_pressed() -> void:
	print("[MainMenu] Navigating to Character Selection...")
	get_tree().change_scene_to_file("res://scenes/character_selection/CharacterSelection.tscn")

func _on_continue_pressed() -> void:
	if SaveManager.save_exists():
		print("[MainMenu] Loading saved game...")
		SaveManager.load_game()

func _on_settings_pressed() -> void:
	credits_panel.visible = false
	settings_panel.visible = true

func _on_credits_pressed() -> void:
	settings_panel.visible = false
	credits_panel.visible = true

func _on_music_volume_changed(val: float) -> void:
	AudioManager.set_music_volume(val / 100.0)

func _on_sfx_volume_changed(val: float) -> void:
	AudioManager.set_sfx_volume(val / 100.0)
