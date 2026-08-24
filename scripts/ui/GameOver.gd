extends CanvasLayer

## GameOver.gd - Game Over screen

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	%RestartButton.pressed.connect(_on_restart)
	%MainMenuButton.pressed.connect(_on_main_menu)

func _on_restart() -> void:
	GameManager.restart_current_level()

func _on_main_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu/MainMenu.tscn")
