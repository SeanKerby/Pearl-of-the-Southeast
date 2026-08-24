extends Control

## CharacterSelection.gd - Character Selection Scene logic

@onready var mangyan_card: PanelContainer = %MangyanCard
@onready var igorot_card: PanelContainer = %IgorotCard
@onready var badjao_card: PanelContainer = %BadjaoCard

@onready var select_mangyan_btn: Button = %SelectMangyanButton
@onready var select_igorot_btn: Button = %SelectIgorotButton
@onready var select_badjao_btn: Button = %SelectBadjaoButton

@onready var selected_info_label: Label = %SelectedInfoLabel
@onready var start_btn: Button = %StartButton
@onready var back_btn: Button = %BackButton

# Story Intro Modal
@onready var story_modal: PanelContainer = %StoryModal
@onready var proceed_story_btn: Button = %ProceedStoryButton

var current_selected: String = "mangyan"

func _ready() -> void:
	print("[CharacterSelection] Loaded.")
	story_modal.visible = false

	# Connect selection buttons
	select_mangyan_btn.pressed.connect(func(): _select_character("mangyan"))
	select_igorot_btn.pressed.connect(func(): _select_character("igorot"))
	select_badjao_btn.pressed.connect(func(): _select_character("badjao"))

	start_btn.pressed.connect(_on_start_pressed)
	back_btn.pressed.connect(_on_back_pressed)
	proceed_story_btn.pressed.connect(_on_proceed_story_pressed)

	_select_character("mangyan")

func _select_character(char_id: String) -> void:
	current_selected = char_id
	GameManager.select_character(char_id)
	var data = GameManager.get_selected_character_data()

	# Highlight chosen card
	_update_card_highlight(mangyan_card, char_id == "mangyan", Color(0.2, 0.7, 0.3))
	_update_card_highlight(igorot_card, char_id == "igorot", Color(0.85, 0.35, 0.2))
	_update_card_highlight(badjao_card, char_id == "badjao", Color(0.2, 0.65, 0.9))

	selected_info_label.text = "Selected: %s (%s)\n%s" % [data["name"], data["role"], data["special_ability"]]

func _update_card_highlight(card: PanelContainer, is_active: bool, accent_color: Color) -> void:
	if card:
		card.modulate = Color(1.0, 1.0, 1.0, 1.0) if is_active else Color(0.7, 0.7, 0.7, 0.8)

func _on_start_pressed() -> void:
	# Show brief story introduction before Level 1
	story_modal.visible = true

func _on_proceed_story_pressed() -> void:
	print("[CharacterSelection] Starting adventure with: %s" % current_selected)
	GameManager.start_new_game(current_selected)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu/MainMenu.tscn")
