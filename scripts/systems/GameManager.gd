extends Node

## GameManager.gd - Global state, character data, and multi-chapter Bookworm Adventures stage progression

signal character_selected(character_id: String)
signal level_changed(level_path: String)
signal game_paused(is_paused: bool)
signal game_over_triggered()
signal victory_triggered()
signal stage_completed(chapter_num: int, stage_index: int)
signal chapter_changed(chapter_num: int)

# Scene Constants
const ADVENTURE_MAP_PATH: String = "res://scenes/levels/AdventureMap.tscn"
const MAIN_MENU_PATH: String = "res://scenes/main_menu/MainMenu.tscn"
const CHAR_SELECT_PATH: String = "res://scenes/character_selection/CharacterSelection.tscn"

# Character database
const CHARACTERS: Dictionary = {
	"mangyan": {
		"id": "mangyan",
		"name": "Mangyan Explorer",
		"inspiration": "Inspired by Mangyan culture & traditions",
		"role": "Nature Wordsmith",
		"max_health": 100,
		"speed": 150.0,
		"special_ability": "Nature words heal + deal 20% bonus damage",
		"sprite_folder": "res://assets/characters/mangyan/",
		"color_theme": Color(0.2, 0.65, 0.3)
	},
	"igorot": {
		"id": "igorot",
		"name": "Igorot Explorer",
		"inspiration": "Inspired by Igorot mountain resilience & craftsmanship",
		"role": "Ancient Wordsmith",
		"max_health": 130,
		"speed": 130.0,
		"special_ability": "Ancient words deal 20% bonus damage + high HP",
		"sprite_folder": "res://assets/characters/igorot/",
		"color_theme": Color(0.8, 0.3, 0.2)
	},
	"badjao": {
		"id": "badjao",
		"name": "Badjao Explorer",
		"inspiration": "Inspired by Badjao maritime heritage & navigation",
		"role": "Water Wordsmith",
		"max_health": 90,
		"speed": 175.0,
		"special_ability": "Water words deal 25% bonus damage + tidal combos",
		"sprite_folder": "res://assets/characters/badjao/",
		"color_theme": Color(0.15, 0.6, 0.85)
	}
}

# Chapter 1: The Coastal Village
const CHAPTER_1_STAGES: Array[Dictionary] = [
	{
		"stage_num": 1,
		"chapter": 1,
		"name": "The Coastal Village",
		"description": "A peaceful village by the shore. A wild Forest Crab blocks the path!",
		"enemy_id": "crab",
		"enemy_name": "Forest Crab",
		"enemy_hp": 45,
		"is_boss": false,
		"theme": "forest",
		"loot": [
			{"type": "consumable", "id": "healing_fruit", "name": "Healing Fruit", "amount": 1, "chance": 1.0},
			{"type": "collectible", "id": "ancient_leaf", "name": "Ancient Leaf", "amount": 1, "chance": 1.0},
			{"type": "gold", "id": "gold", "name": "Gold", "amount": 20, "chance": 1.0}
		]
	},
	{
		"stage_num": 2,
		"chapter": 1,
		"name": "The Docks",
		"description": "Old wooden docks where turbulent waves crash. A ferocious Jungle Boar charges!",
		"enemy_id": "boar",
		"enemy_name": "Jungle Boar",
		"enemy_hp": 75,
		"is_boss": false,
		"theme": "forest",
		"loot": [
			{"type": "consumable", "id": "tropical_potion", "name": "Tropical Potion", "amount": 1, "chance": 1.0},
			{"type": "collectible", "id": "lost_shell", "name": "Lost Shell", "amount": 1, "chance": 1.0},
			{"type": "gold", "id": "gold", "name": "Gold", "amount": 35, "chance": 1.0}
		]
	},
	{
		"stage_num": 3,
		"chapter": 1,
		"name": "The Hidden Forest",
		"description": "Mystical trees whispering ancient riddles. An ethereal Forest Spirit tests your vocabulary!",
		"enemy_id": "spirit",
		"enemy_name": "Forest Spirit",
		"enemy_hp": 65,
		"is_boss": false,
		"theme": "forest",
		"loot": [
			{"type": "consumable", "id": "focus_leaf", "name": "Focus Leaf", "amount": 1, "chance": 1.0},
			{"type": "collectible", "id": "stone_fragment", "name": "Stone Fragment", "amount": 1, "chance": 1.0},
			{"type": "gold", "id": "gold", "name": "Gold", "amount": 50, "chance": 1.0}
		]
	},
	{
		"stage_num": 4,
		"chapter": 1,
		"name": "The Ancient Shrine",
		"description": "The sanctuary of the first relic. The colossal Forest Guardian awakens across 3 combat phases!",
		"enemy_id": "boss",
		"enemy_name": "Forest Guardian",
		"enemy_hp": 180,
		"is_boss": true,
		"theme": "forest",
		"loot": [
			{"type": "artifact", "id": "forest_relic", "name": "Forest Relic", "amount": 1, "chance": 1.0},
			{"type": "consumable", "id": "ancient_tonic", "name": "Ancient Tonic", "amount": 1, "chance": 1.0},
			{"type": "gold", "id": "gold", "name": "Gold", "amount": 150, "chance": 1.0}
		]
	}
]

# Chapter 2: The Sunken Coast
const CHAPTER_2_STAGES: Array[Dictionary] = [
	{
		"stage_num": 1,
		"chapter": 2,
		"name": "The Coral Shallows",
		"description": "Shimmering tide pools beneath coastal cliffs. An armored Coral Crab scuttles into combat!",
		"enemy_id": "coral_crab",
		"enemy_name": "Coral Crab",
		"enemy_hp": 60,
		"is_boss": false,
		"theme": "coastal",
		"loot": [
			{"type": "consumable", "id": "healing_fruit", "name": "Healing Fruit", "amount": 2, "chance": 1.0},
			{"type": "collectible", "id": "lost_shell", "name": "Lost Shell", "amount": 1, "chance": 1.0},
			{"type": "gold", "id": "gold", "name": "Gold", "amount": 40, "chance": 1.0}
		]
	},
	{
		"stage_num": 2,
		"chapter": 2,
		"name": "The Sunken Docks",
		"description": "Submerged wooden pilings shrouded in mist. A luminous Abyssal Jellyfish floats forward with shocking tentacles!",
		"enemy_id": "jellyfish",
		"enemy_name": "Abyssal Jellyfish",
		"enemy_hp": 90,
		"is_boss": false,
		"theme": "coastal",
		"loot": [
			{"type": "consumable", "id": "tropical_potion", "name": "Tropical Potion", "amount": 1, "chance": 1.0},
			{"type": "collectible", "id": "ancient_leaf", "name": "Ancient Leaf", "amount": 1, "chance": 1.0},
			{"type": "gold", "id": "gold", "name": "Gold", "amount": 60, "chance": 1.0}
		]
	},
	{
		"stage_num": 3,
		"chapter": 2,
		"name": "The Submerged Ruins",
		"description": "Ancient sunken stone temples teeming with ocean currents. A fearsome Tide Serpent coils ready to strike!",
		"enemy_id": "sea_serpent",
		"enemy_name": "Tide Serpent",
		"enemy_hp": 115,
		"is_boss": false,
		"theme": "coastal",
		"loot": [
			{"type": "consumable", "id": "focus_leaf", "name": "Focus Leaf", "amount": 2, "chance": 1.0},
			{"type": "collectible", "id": "stone_fragment", "name": "Stone Fragment", "amount": 2, "chance": 1.0},
			{"type": "gold", "id": "gold", "name": "Gold", "amount": 80, "chance": 1.0}
		]
	},
	{
		"stage_num": 4,
		"chapter": 2,
		"name": "The Water Guardian Shrine",
		"description": "The abyssal dais of the sunken ancients. The mythical Water Guardian emerges to test your oceanic mastery!",
		"enemy_id": "water_guardian",
		"enemy_name": "The Water Guardian",
		"enemy_hp": 240,
		"is_boss": true,
		"theme": "coastal",
		"loot": [
			{"type": "artifact", "id": "water_relic", "name": "Ocean Pearl (Water Relic)", "amount": 1, "chance": 1.0},
			{"type": "consumable", "id": "ancient_tonic", "name": "Ancient Tonic", "amount": 2, "chance": 1.0},
			{"type": "gold", "id": "gold", "name": "Gold", "amount": 250, "chance": 1.0}
		]
	}
]

# Chapter 3: The Forgotten Ruins
const CHAPTER_3_STAGES: Array[Dictionary] = [
	{
		"stage_num": 1,
		"chapter": 3,
		"name": "The Ruin Gateway",
		"description": "Moss-covered stone stairs guarded by an ancient skeletal warrior reanimated by lost magic!",
		"enemy_id": "skeleton_warrior",
		"enemy_name": "Skeleton Warrior",
		"enemy_hp": 80,
		"is_boss": false,
		"theme": "ruins",
		"loot": [
			{"type": "consumable", "id": "healing_fruit", "name": "Healing Fruit", "amount": 2, "chance": 1.0},
			{"type": "collectible", "id": "stone_fragment", "name": "Stone Fragment", "amount": 1, "chance": 1.0},
			{"type": "gold", "id": "gold", "name": "Gold", "amount": 50, "chance": 1.0}
		]
	},
	{
		"stage_num": 2,
		"chapter": 3,
		"name": "The Sunken Catacombs",
		"description": "Dark subterranean passages echoing with screeching shadow bats that dart through the gloom!",
		"enemy_id": "ruin_bat",
		"enemy_name": "Cave Shadow Bat",
		"enemy_hp": 110,
		"is_boss": false,
		"theme": "ruins",
		"loot": [
			{"type": "consumable", "id": "tropical_potion", "name": "Tropical Potion", "amount": 1, "chance": 1.0},
			{"type": "collectible", "id": "ancient_leaf", "name": "Ancient Leaf", "amount": 2, "chance": 1.0},
			{"type": "gold", "id": "gold", "name": "Gold", "amount": 75, "chance": 1.0}
		]
	},
	{
		"stage_num": 3,
		"chapter": 3,
		"name": "The Ancient Bastion",
		"description": "A fortress of stone slabs animated by earthen runes. A massive Boulder Golem steps forward!",
		"enemy_id": "stone_golem",
		"enemy_name": "Stone Sentinel Golem",
		"enemy_hp": 150,
		"is_boss": false,
		"theme": "ruins",
		"loot": [
			{"type": "consumable", "id": "focus_leaf", "name": "Focus Leaf", "amount": 2, "chance": 1.0},
			{"type": "collectible", "id": "stone_fragment", "name": "Stone Fragment", "amount": 2, "chance": 1.0},
			{"type": "gold", "id": "gold", "name": "Gold", "amount": 100, "chance": 1.0}
		]
	},
	{
		"stage_num": 4,
		"chapter": 3,
		"name": "The Hall of the Ancients",
		"description": "The sacred dais of the earth builders. The colossal Ruin Guardian Titan awakens across 3 cataclysmic combat phases!",
		"enemy_id": "ruin_guardian",
		"enemy_name": "The Ruin Guardian Titan",
		"enemy_hp": 320,
		"is_boss": true,
		"theme": "ruins",
		"loot": [
			{"type": "artifact", "id": "ancient_stone", "name": "Ancient Stone (Earth Relic)", "amount": 1, "chance": 1.0},
			{"type": "consumable", "id": "ancient_tonic", "name": "Ancient Tonic", "amount": 2, "chance": 1.0},
			{"type": "gold", "id": "gold", "name": "Gold", "amount": 350, "chance": 1.0}
		]
	}
]

# Chapter 4: The Final Stage — The Ancient Heart
const CHAPTER_4_STAGES: Array[Dictionary] = [
	{
		"stage_num": 1,
		"chapter": 4,
		"name": "The Jungle Ascent",
		"description": "Dense ancient jungle overgrown with sacred stone totems. A towering Rune Titan steps forward to block your path!",
		"enemy_id": "rune_titan",
		"enemy_name": "Rune Titan Golem",
		"enemy_hp": 130,
		"is_boss": false,
		"theme": "heart",
		"loot": [
			{"type": "consumable", "id": "healing_fruit", "name": "Healing Fruit", "amount": 2, "chance": 1.0},
			{"type": "collectible", "id": "ancient_leaf", "name": "Ancient Leaf", "amount": 2, "chance": 1.0},
			{"type": "gold", "id": "gold", "name": "Gold", "amount": 80, "chance": 1.0}
		]
	},
	{
		"stage_num": 2,
		"chapter": 4,
		"name": "The Masked Ritual Grounds",
		"description": "Corrupted ritual braziers burning with violet flame. A sinister Shadow Shaman unleashes dark staff hexes!",
		"enemy_id": "shadow_shaman",
		"enemy_name": "Shadow Shaman",
		"enemy_hp": 165,
		"is_boss": false,
		"theme": "heart",
		"loot": [
			{"type": "consumable", "id": "focus_leaf", "name": "Focus Leaf", "amount": 2, "chance": 1.0},
			{"type": "consumable", "id": "tropical_potion", "name": "Tropical Potion", "amount": 1, "chance": 1.0},
			{"type": "gold", "id": "gold", "name": "Gold", "amount": 120, "chance": 1.0}
		]
	},
	{
		"stage_num": 3,
		"chapter": 4,
		"name": "The Void Beast Lair",
		"description": "A dark subterranean cavern echoing with primal roars. A ferocious Void Crystal Panther leaps from the shadows!",
		"enemy_id": "crystal_panther",
		"enemy_name": "Void Crystal Panther",
		"enemy_hp": 210,
		"is_boss": false,
		"theme": "heart",
		"loot": [
			{"type": "consumable", "id": "healing_fruit", "name": "Healing Fruit", "amount": 3, "chance": 1.0},
			{"type": "consumable", "id": "ancient_tonic", "name": "Ancient Tonic", "amount": 1, "chance": 1.0},
			{"type": "gold", "id": "gold", "name": "Gold", "amount": 160, "chance": 1.0}
		]
	},
	{
		"stage_num": 4,
		"chapter": 4,
		"name": "The Ancient Heart Sanctum",
		"description": "The sacred altar atop the ancient temple. The Corrupted Empress Naga Queen guards the Ancient Heart across 3 devastating phases!",
		"enemy_id": "naga_queen",
		"enemy_name": "Empress Naga (Ancient Heart Guardian)",
		"enemy_hp": 450,
		"is_boss": true,
		"theme": "heart",
		"loot": [
			{"type": "artifact", "id": "ancient_heart", "name": "The Ancient Heart (Ultimate Sacred Relic)", "amount": 1, "chance": 1.0},
			{"type": "consumable", "id": "ancient_tonic", "name": "Ancient Tonic", "amount": 3, "chance": 1.0},
			{"type": "gold", "id": "gold", "name": "Gold", "amount": 500, "chance": 1.0}
		]
	}
]

var selected_character_id: String = "mangyan"
var current_health: int = 100
var is_game_active: bool = false
var is_game_paused: bool = false
var current_level_path: String = ADVENTURE_MAP_PATH

# Multi-Chapter Stage Progression
var current_chapter: int = 1
var max_unlocked_chapter: int = 1
var chapter_1_unlocked_stage: int = 1
var chapter_2_unlocked_stage: int = 1
var chapter_3_unlocked_stage: int = 1
var chapter_4_unlocked_stage: int = 1
var completed_stages_ch1: Array[int] = []
var completed_stages_ch2: Array[int] = []
var completed_stages_ch3: Array[int] = []
var completed_stages_ch4: Array[int] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	print("[GameManager] Initialized successfully.")

func select_character(char_id: String) -> void:
	if CHARACTERS.has(char_id):
		selected_character_id = char_id
		var data: Dictionary = CHARACTERS[char_id]
		current_health = data["max_health"]
		character_selected.emit(char_id)
		print("[GameManager] Character selected: %s" % data["name"])

func get_selected_character_data() -> Dictionary:
	return CHARACTERS.get(selected_character_id, CHARACTERS["mangyan"])

func start_new_game(char_id: String = "mangyan") -> void:
	select_character(char_id)
	if InventoryManager:
		InventoryManager.reset_inventory()
	
	current_chapter = 1
	max_unlocked_chapter = 1
	chapter_1_unlocked_stage = 1
	chapter_2_unlocked_stage = 1
	chapter_3_unlocked_stage = 1
	chapter_4_unlocked_stage = 1
	completed_stages_ch1.clear()
	completed_stages_ch2.clear()
	completed_stages_ch3.clear()
	completed_stages_ch4.clear()
	
	is_game_active = true
	is_game_paused = false
	get_tree().paused = false
	change_level(ADVENTURE_MAP_PATH)

func change_level(level_scene_path: String) -> void:
	current_level_path = level_scene_path
	is_game_paused = false
	get_tree().paused = false
	level_changed.emit(level_scene_path)
	get_tree().change_scene_to_file(level_scene_path)

func get_chapter_stages(chapter_num: int = -1) -> Array[Dictionary]:
	var ch = current_chapter if chapter_num <= 0 else chapter_num
	if ch == 4:
		return CHAPTER_4_STAGES
	elif ch == 3:
		return CHAPTER_3_STAGES
	elif ch == 2:
		return CHAPTER_2_STAGES
	return CHAPTER_1_STAGES

func get_stage_data(stage_num: int, chapter_num: int = -1) -> Dictionary:
	var stages = get_chapter_stages(chapter_num)
	for stg in stages:
		if stg["stage_num"] == stage_num:
			return stg
	return stages[0]

func complete_stage(stage_num: int, chapter_num: int = -1) -> void:
	var ch = current_chapter if chapter_num <= 0 else chapter_num
	if ch == 1:
		if not completed_stages_ch1.has(stage_num):
			completed_stages_ch1.append(stage_num)
		if stage_num >= chapter_1_unlocked_stage:
			chapter_1_unlocked_stage = stage_num + 1
		if stage_num == 4:
			if InventoryManager:
				InventoryManager.collect_artifact("forest_relic")
			if max_unlocked_chapter < 2:
				max_unlocked_chapter = 2
				print("[GameManager] Chapter 2 Unlocked: The Sunken Coast!")
	elif ch == 2:
		if not completed_stages_ch2.has(stage_num):
			completed_stages_ch2.append(stage_num)
		if stage_num >= chapter_2_unlocked_stage:
			chapter_2_unlocked_stage = stage_num + 1
		if stage_num == 4:
			if InventoryManager:
				InventoryManager.collect_artifact("water_relic")
			if max_unlocked_chapter < 3:
				max_unlocked_chapter = 3
				print("[GameManager] Chapter 3 Unlocked: The Forgotten Ruins!")
	elif ch == 3:
		if not completed_stages_ch3.has(stage_num):
			completed_stages_ch3.append(stage_num)
		if stage_num >= chapter_3_unlocked_stage:
			chapter_3_unlocked_stage = stage_num + 1
		if stage_num == 4:
			if InventoryManager:
				InventoryManager.collect_artifact("ancient_stone")
			if max_unlocked_chapter < 4:
				max_unlocked_chapter = 4
				print("[GameManager] Final Stage Unlocked: The Ancient Heart!")
	elif ch == 4:
		if not completed_stages_ch4.has(stage_num):
			completed_stages_ch4.append(stage_num)
		if stage_num >= chapter_4_unlocked_stage:
			chapter_4_unlocked_stage = stage_num + 1
		if stage_num == 4:
			if InventoryManager:
				InventoryManager.collect_artifact("ancient_heart")
			print("[GameManager] 👑 ALL 4 SACRED ARTIFACTS CLAIMED! THE ANCIENT HEART RESTORED!")
			
	stage_completed.emit(ch, stage_num)

func is_stage_completed(stage_num: int, chapter_num: int = -1) -> bool:
	var ch = current_chapter if chapter_num <= 0 else chapter_num
	if ch == 4:
		return completed_stages_ch4.has(stage_num)
	elif ch == 3:
		return completed_stages_ch3.has(stage_num)
	elif ch == 2:
		return completed_stages_ch2.has(stage_num)
	return completed_stages_ch1.has(stage_num)

func get_max_unlocked_stage(chapter_num: int = -1) -> int:
	var ch = current_chapter if chapter_num <= 0 else chapter_num
	if ch == 4:
		return chapter_4_unlocked_stage
	elif ch == 3:
		return chapter_3_unlocked_stage
	elif ch == 2:
		return chapter_2_unlocked_stage
	return chapter_1_unlocked_stage

func switch_chapter(chapter_num: int) -> void:
	if chapter_num <= max_unlocked_chapter:
		current_chapter = chapter_num
		chapter_changed.emit(chapter_num)
		print("[GameManager] Switched to Chapter %d" % chapter_num)

func toggle_pause() -> void:
	is_game_paused = !is_game_paused
	get_tree().paused = is_game_paused
	game_paused.emit(is_game_paused)

func trigger_game_over() -> void:
	is_game_active = false
	game_over_triggered.emit()
	print("[GameManager] Game Over.")

func trigger_victory() -> void:
	is_game_active = false
	victory_triggered.emit()
	print("[GameManager] Victory achieved!")
