extends CanvasLayer

## Victory.gd - Victory / Win screen for PEARL OF SOUTHEAST

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	%PlayAgainButton.pressed.connect(_on_play_again)
	%MainMenuButton.pressed.connect(_on_main_menu)

func _on_play_again() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/character_selection/CharacterSelection.tscn")

func _on_main_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu/MainMenu.tscn")
