extends Node

## SaveManager.gd - Web-compatible JSON save/load system for PEARL OF SOUTHEAST

const SAVE_FILE_PATH: String = "user://save_data.json"

signal game_saved()
signal game_loaded()

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	print("[SaveManager] Initialized successfully.")

func save_exists() -> bool:
	return FileAccess.file_exists(SAVE_FILE_PATH)

func save_game() -> bool:
	var save_dict: Dictionary = {
		"version": "1.0",
		"timestamp": Time.get_datetime_string_from_system(),
		"selected_character": GameManager.selected_character_id,
		"current_level": GameManager.current_level_path,
		"current_health": GameManager.current_health,
		"collected_artifacts": InventoryManager.collected_artifacts,
		"is_game_active": GameManager.is_game_active
	}

	var json_string: String = JSON.stringify(save_dict, "\t")
	var file: FileAccess = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("[SaveManager] Failed to write save file: %s" % FileAccess.get_open_error())
		return false

	file.store_string(json_string)
	file.close()
	print("[SaveManager] Game saved successfully.")
	game_saved.emit()
	return true

func load_game() -> bool:
	if not save_exists():
		print("[SaveManager] No save file found.")
		return false

	var file: FileAccess = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	if file == null:
		push_error("[SaveManager] Failed to read save file: %s" % FileAccess.get_open_error())
		return false

	var content: String = file.get_as_text()
	file.close()

	var json: JSON = JSON.new()
	var parse_result = json.parse(content)
	if parse_result != OK:
		push_error("[SaveManager] JSON Parse Error: %s" % json.get_error_message())
		return false

	var save_dict: Dictionary = json.data
	if save_dict.has("selected_character"):
		GameManager.select_character(save_dict["selected_character"])
	if save_dict.has("collected_artifacts"):
		InventoryManager.collected_artifacts = save_dict["collected_artifacts"]
		InventoryManager.inventory_updated.emit()
	if save_dict.has("current_health"):
		GameManager.current_health = int(save_dict["current_health"])
	if save_dict.has("current_level"):
		GameManager.current_level_path = save_dict["current_level"]

	GameManager.is_game_active = save_dict.get("is_game_active", true)
	print("[SaveManager] Game loaded successfully.")
	game_loaded.emit()

	if GameManager.is_game_active and save_dict.has("current_level"):
		GameManager.change_level(save_dict["current_level"])

	return true

func delete_save() -> void:
	if save_exists():
		DirAccess.remove_absolute(SAVE_FILE_PATH)
		print("[SaveManager] Save data removed.")
