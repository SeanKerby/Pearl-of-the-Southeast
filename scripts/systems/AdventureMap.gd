extends Control

## AdventureMap.gd - Multi-Chapter Bookworm Adventures map controller (Stages 1, 2, & 3)

@onready var map_texture_rect: TextureRect = %MapTextureRect
@onready var hero_token: Sprite2D = %HeroToken

# Stage Battle Modal
@onready var stage_modal: PanelContainer = %StageModal
@onready var modal_backdrop: ColorRect = %ModalBackdrop
@onready var stage_title_label: Label = %StageTitleLabel
@onready var stage_desc_label: Label = %StageDescLabel
@onready var enemy_name_label: Label = %EnemyNameLabel
@onready var enemy_preview_sprite: Sprite2D = %EnemyPreviewSprite
@onready var loot_list_label: Label = %LootListLabel
@onready var start_battle_button: Button = %StartBattleButton
@onready var close_modal_button: Button = %CloseModalButton

# Artifact Celebration Modal
@onready var artifact_modal: PanelContainer = %ArtifactModal
@onready var artifact_title_label: Label = %ArtifactTitleLabel
@onready var artifact_icon_sprite: Sprite2D = %ArtifactIconSprite
@onready var artifact_name_label: Label = %ArtifactNameLabel
@onready var artifact_desc_label: Label = %ArtifactDescLabel
@onready var proceed_next_stage_button: Button = %ProceedNextStageButton

# Header & Stats HUD
@onready var hero_name_label: Label = %HeroNameLabel
@onready var hero_hp_bar: ProgressBar = %HeroHPBar
@onready var hero_hp_label: Label = %HeroHPLabel
@onready var gold_label: Label = %GoldLabel
@onready var relics_label: Label = %RelicsLabel
@onready var collectibles_label: Label = %CollectiblesLabel

@onready var chapter_btn_1: Button = %ChapterBtn1
@onready var chapter_btn_2: Button = %ChapterBtn2
@onready var chapter_btn_3: Button = %ChapterBtn3

@onready var path_node_1: Button = %PathNode1
@onready var path_node_2: Button = %PathNode2
@onready var path_node_3: Button = %PathNode3
@onready var path_node_4: Button = %PathNode4

var path_buttons: Array[Button] = []
var selected_stage_num: int = 1
var current_celebration_chap: int = 1

# Node positions for Chapter 1 (stage 1.jpg)
const CH1_POSITIONS: Dictionary = {
	1: Vector2(250, 429),  # Coastal Village Huts
	2: Vector2(658, 373),  # Village Square / Market
	3: Vector2(1108, 506), # Coastal Docks Pier
	4: Vector2(1033, 183)  # Ancient Crystal Shrine (Boss)
}

# Node positions for Chapter 2 (stage2.jpg)
const CH2_POSITIONS: Dictionary = {
	1: Vector2(112, 471),  # Coastal Beach Village
	2: Vector2(400, 464),  # Wooden Footbridge / Pier
	3: Vector2(692, 302),  # Jungle Cliff Path / Stone Gateway
	4: Vector2(1017, 98)   # Ancient Sunken Temple Shrine (Boss)
}

# Node positions for Chapter 3 (stage3.jpg)
const CH3_POSITIONS: Dictionary = {
	1: Vector2(183, 541),  # Ruin Gateway Steps
	2: Vector2(300, 351),  # Pyramid Totem Bastion
	3: Vector2(700, 337),  # Waterfalls Stone Crossroads
	4: Vector2(625, 583)   # Ancient Glowing Portal Shrine (Boss)
}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	path_buttons = [path_node_1, path_node_2, path_node_3, path_node_4]
	
	# Connect path buttons
	for i in range(path_buttons.size()):
		var stg = i + 1
		path_buttons[i].pressed.connect(func(): _on_node_clicked(stg))
		
	# Connect chapter tab buttons
	chapter_btn_1.pressed.connect(func(): _switch_chapter(1))
	chapter_btn_2.pressed.connect(func(): _switch_chapter(2))
	chapter_btn_3.pressed.connect(func(): _switch_chapter(3))
	
	start_battle_button.pressed.connect(_on_start_battle_pressed)
	close_modal_button.pressed.connect(_close_stage_modal)
	proceed_next_stage_button.pressed.connect(_on_proceed_next_stage_pressed)
	
	if modal_backdrop:
		modal_backdrop.gui_input.connect(func(event):
			if event is InputEventMouseButton and event.pressed:
				_close_stage_modal()
		)
		
	stage_modal.visible = false
	artifact_modal.visible = false
	if modal_backdrop:
		modal_backdrop.visible = false
		
	_setup_hero_token()
	_update_header_stats()
	_load_current_chapter_map()
	
	if AudioManager:
		AudioManager.start_ambient_tropical_music()

func _setup_hero_token() -> void:
	var char_id = GameManager.selected_character_id if GameManager else "mangyan"
	var base_path = "res://assets/characters/%s/idle_down.png" % char_id
	if ResourceLoader.exists(base_path):
		hero_token.texture = load(base_path)
	elif ResourceLoader.exists("res://characters/%s/idle_down.png" % char_id):
		hero_token.texture = load("res://characters/%s/idle_down.png" % char_id)
		
	var tween = create_tween().set_loops()
	tween.tween_property(hero_token, "offset:y", -4.0, 0.65).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(hero_token, "offset:y", 0.0, 0.65).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _update_header_stats() -> void:
	var char_data = GameManager.get_selected_character_data() if GameManager else {}
	hero_name_label.text = char_data.get("name", "Explorer")
	
	var max_hp = char_data.get("max_health", 100)
	var cur_hp = GameManager.current_health if GameManager else max_hp
	hero_hp_bar.max_value = max_hp
	hero_hp_bar.value = cur_hp
	hero_hp_label.text = "%d / %d HP" % [cur_hp, max_hp]
	
	if InventoryManager:
		gold_label.text = "🪙 %d" % InventoryManager.gold
		var count = InventoryManager.get_collected_count()
		relics_label.text = "👑 %d / 3 Relics" % count
		var leaves = InventoryManager.get_collectible_count("ancient_leaf")
		var shells = InventoryManager.get_collectible_count("lost_shell")
		var stones = InventoryManager.get_collectible_count("stone_fragment")
		collectibles_label.text = "🍃%d  🐚%d  🪨%d" % [leaves, shells, stones]
		
	# Update chapter buttons state
	var max_chap = GameManager.max_unlocked_chapter if GameManager else 1
	var cur_chap = GameManager.current_chapter if GameManager else 1
	
	chapter_btn_1.disabled = false
	chapter_btn_2.disabled = max_chap < 2
	chapter_btn_3.disabled = max_chap < 3
	
	chapter_btn_1.modulate = Color(1.0, 0.9, 0.4) if cur_chap == 1 else Color(0.75, 0.75, 0.75)
	chapter_btn_2.modulate = Color(0.4, 0.85, 1.0) if cur_chap == 2 else (Color(1.0, 1.0, 1.0) if max_chap >= 2 else Color(0.45, 0.45, 0.45))
	chapter_btn_3.modulate = Color(0.85, 0.5, 1.0) if cur_chap == 3 else (Color(1.0, 1.0, 1.0) if max_chap >= 3 else Color(0.45, 0.45, 0.45))

func _switch_chapter(chapter_num: int) -> void:
	if GameManager:
		GameManager.switch_chapter(chapter_num)
	_load_current_chapter_map()

func _load_current_chapter_map() -> void:
	var cur_chap = GameManager.current_chapter if GameManager else 1
	var map_path = "res://assets/maps/stage 1.jpg"
	if cur_chap == 3:
		map_path = "res://assets/maps/stage3.jpg"
	elif cur_chap == 2:
		map_path = "res://assets/maps/stage2.jpg"
		
	if ResourceLoader.exists(map_path):
		map_texture_rect.texture = load(map_path)
		
	_refresh_nodes()
	_update_header_stats()
	
	var unlocked_stage = mini(GameManager.get_max_unlocked_stage(cur_chap), 4) if GameManager else 1
	_move_hero_to_stage(unlocked_stage, false)

func _get_current_positions() -> Dictionary:
	var cur_chap = GameManager.current_chapter if GameManager else 1
	if cur_chap == 3:
		return CH3_POSITIONS
	elif cur_chap == 2:
		return CH2_POSITIONS
	return CH1_POSITIONS

func _refresh_nodes() -> void:
	var cur_chap = GameManager.current_chapter if GameManager else 1
	var max_unlocked = GameManager.get_max_unlocked_stage(cur_chap) if GameManager else 1
	var positions = _get_current_positions()
	
	for i in range(4):
		var stg = i + 1
		var is_cleared = GameManager.is_stage_completed(stg, cur_chap) if GameManager else false
		var is_unlocked = stg <= max_unlocked
		var pbtn = path_buttons[i]
		
		# Position node button
		if positions.has(stg):
			var pos = positions[stg]
			pbtn.position = pos - Vector2(18, 18)
			
		pbtn.disabled = not is_unlocked
		if is_cleared:
			pbtn.text = "✓"
			pbtn.modulate = Color(0.35, 1.0, 0.45, 1.0)
		elif stg == max_unlocked:
			pbtn.text = "%d" % stg
			pbtn.modulate = Color(1.0, 0.92, 0.3, 1.0)
		else:
			pbtn.text = "🔒" if stg < 4 else "💀"
			pbtn.modulate = Color(0.7, 0.7, 0.7, 0.7)

func _on_node_clicked(stage_num: int) -> void:
	selected_stage_num = stage_num
	_move_hero_to_stage(stage_num, true)
	_open_stage_modal(stage_num)

func _move_hero_to_stage(stage_num: int, animate: bool = true) -> void:
	var positions = _get_current_positions()
	if positions.has(stage_num):
		var target_pos = positions[stage_num]
		if animate:
			var tween = create_tween()
			tween.tween_property(hero_token, "position", target_pos, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		else:
			hero_token.position = target_pos

func _open_stage_modal(stage_num: int) -> void:
	var cur_chap = GameManager.current_chapter if GameManager else 1
	var stage_data = GameManager.get_stage_data(stage_num, cur_chap) if GameManager else {}
	
	stage_title_label.text = "STAGE %d - NODE %d: %s" % [cur_chap, stage_num, stage_data.get("name", "Stage")]
	stage_desc_label.text = stage_data.get("description", "")
	enemy_name_label.text = "Target: %s (%d HP)" % [stage_data.get("enemy_name", "Enemy"), stage_data.get("enemy_hp", 50)]
	
	var enemy_id = stage_data.get("enemy_id", "crab")
	var enemy_tex_path = "res://assets/enemies/%s.png" % (enemy_id if enemy_id != "boss" else "guardian_boss")
	if ResourceLoader.exists(enemy_tex_path):
		enemy_preview_sprite.texture = load(enemy_tex_path)
		
	var loot_lines: Array[String] = []
	for drop in stage_data.get("loot", []):
		var dname = drop.get("name", "Item")
		var damount = drop.get("amount", 1)
		var dtype = drop.get("type", "consumable")
		var icon = "🧪" if dtype == "consumable" else ("👑" if dtype == "artifact" else ("🪙" if dtype == "gold" else "✨"))
		loot_lines.append("%s %dx %s" % [icon, damount, dname])
	loot_list_label.text = "Guaranteed Loot Drops:\n" + "\n".join(loot_lines)
	
	stage_modal.visible = true
	if modal_backdrop:
		modal_backdrop.visible = true
	
	stage_modal.scale = Vector2(0.85, 0.85)
	stage_modal.pivot_offset = stage_modal.size / 2.0
	var tween = create_tween()
	tween.tween_property(stage_modal, "scale", Vector2(1.0, 1.0), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _close_stage_modal() -> void:
	stage_modal.visible = false
	artifact_modal.visible = false
	if modal_backdrop:
		modal_backdrop.visible = false

func _show_artifact_celebration(chapter_completed: int) -> void:
	current_celebration_chap = chapter_completed
	stage_modal.visible = false
	
	if chapter_completed == 1:
		artifact_title_label.text = "👑 FIRST SACRED ARTIFACT ACQUIRED! 👑"
		artifact_name_label.text = "THE FOREST RELIC (ANCIENT HEART)"
		artifact_desc_label.text = "You defeated the Forest Guardian and claimed the 1st Sacred Artifact!\n\nThe power of ancient nature flows through your words, unlocking 'Forest's Blessing' in battle!\n\nStage 2: The Sunken Coast is now open!"
		if ResourceLoader.exists("res://assets/items/forest_relic.png"):
			artifact_icon_sprite.texture = load("res://assets/items/forest_relic.png")
		proceed_next_stage_button.text = "🌊 TRAVEL TO STAGE 2: THE SUNKEN COAST"
	elif chapter_completed == 2:
		artifact_title_label.text = "👑 SECOND SACRED ARTIFACT ACQUIRED! 👑"
		artifact_name_label.text = "THE OCEAN PEARL (WATER RELIC)"
		artifact_desc_label.text = "You defeated the mythical Water Guardian and claimed the 2nd Sacred Artifact!\n\nTidal currents empower your water vocabulary with +50% damage and healing!\n\nStage 3: The Forgotten Ruins is now unlocked!"
		if ResourceLoader.exists("res://assets/items/water_relic.png"):
			artifact_icon_sprite.texture = load("res://assets/items/water_relic.png")
		proceed_next_stage_button.text = "🏛️ TRAVEL TO STAGE 3: THE FORGOTTEN RUINS"
	elif chapter_completed == 3:
		artifact_title_label.text = "👑 THIRD SACRED ARTIFACT ACQUIRED! 👑"
		artifact_name_label.text = "THE ANCIENT STONE (EARTH RELIC)"
		artifact_desc_label.text = "You toppled the colossal Ruin Guardian Titan and claimed the 3rd Sacred Artifact!\n\nAll 3 Sacred Artifacts are now united! You have restored harmony to the Pearl of the South!"
		if ResourceLoader.exists("res://assets/items/ancient_stone_relic.png"):
			artifact_icon_sprite.texture = load("res://assets/items/ancient_stone_relic.png")
		proceed_next_stage_button.text = "🏆 RETURN TO WORLD MAP"
		
	artifact_modal.visible = true
	if modal_backdrop:
		modal_backdrop.visible = true
		
	AudioManager.play_victory_fanfare()
	artifact_modal.scale = Vector2(0.7, 0.7)
	artifact_modal.pivot_offset = artifact_modal.size / 2.0
	var tween = create_tween()
	tween.tween_property(artifact_modal, "scale", Vector2(1.0, 1.0), 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _on_proceed_next_stage_pressed() -> void:
	_close_stage_modal()
	if current_celebration_chap == 1:
		_switch_chapter(2)
	elif current_celebration_chap == 2:
		_switch_chapter(3)
	else:
		_refresh_nodes()

func _on_start_battle_pressed() -> void:
	_close_stage_modal()
	
	var cur_chap = GameManager.current_chapter if GameManager else 1
	var stage_data = GameManager.get_stage_data(selected_stage_num, cur_chap) if GameManager else {}
	var battle_scene = load("res://scenes/battle/BattleScreen.tscn")
	if not battle_scene:
		push_error("BattleScreen.tscn not found!")
		return
		
	var battle = battle_scene.instantiate()
	add_child(battle)
	
	var char_id = GameManager.selected_character_id if GameManager else "mangyan"
	var p_hp = GameManager.current_health if GameManager else 100
	var p_max_hp = GameManager.get_selected_character_data().get("max_health", 100) if GameManager else 100
	
	var theme_name = "ruins" if cur_chap == 3 else ("coastal" if cur_chap == 2 else "forest")
	
	battle.setup_battle(
		char_id,
		p_hp,
		p_max_hp,
		stage_data.get("enemy_id", "crab"),
		stage_data.get("enemy_name", "Enemy"),
		stage_data.get("enemy_hp", 50),
		stage_data.get("is_boss", false),
		theme_name,
		selected_stage_num,
		cur_chap
	)
	
	battle.battle_completed.connect(func(victory: bool, data: Dictionary):
		if victory:
			_update_header_stats()
			_refresh_nodes()
			
			if selected_stage_num == 4:
				_show_artifact_celebration(cur_chap)
			else:
				var next_stg = selected_stage_num + 1
				if next_stg <= 4:
					_move_hero_to_stage(next_stg, true)
	)
