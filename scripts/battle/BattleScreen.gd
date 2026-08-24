extends CanvasLayer

## BattleScreen.gd - Turn-based Word Combat Controller

signal battle_completed(victory: bool, rewards: Dictionary)

enum TurnState { PLAYER_TURN, PLAYER_ANIMATING, ENEMY_TURN, ENEMY_ANIMATING, BATTLE_END }

# UI Node References
@onready var background_rect: ColorRect = $Background
@onready var hero_sprite: AnimatedSprite2D = %HeroSprite
@onready var hero_hp_bar: ProgressBar = %HeroHPBar
@onready var hero_hp_label: Label = %HeroHPLabel
@onready var hero_name_label: Label = %HeroNameLabel
@onready var hero_buff_label: Label = %HeroBuffLabel

@onready var enemy_sprite: AnimatedSprite2D = %EnemySprite
@onready var enemy_static_sprite: Sprite2D = %EnemyStaticSprite
@onready var enemy_hp_bar: ProgressBar = %EnemyHPBar
@onready var enemy_hp_label: Label = %EnemyHPLabel
@onready var enemy_name_label: Label = %EnemyNameLabel
@onready var enemy_intent_label: Label = %EnemyIntentLabel
@onready var enemy_phase_label: Label = %EnemyPhaseLabel

@onready var word_display: Label = %WordDisplay
@onready var word_preview_label: Label = %WordPreviewLabel
@onready var rating_label: Label = %RatingLabel
@onready var combo_label: Label = %ComboLabel

@onready var letter_grid: GridContainer = %LetterGrid
@onready var attack_button: Button = %AttackButton
@onready var clear_button: Button = %ClearButton
@onready var scramble_button: Button = %ScrambleButton
@onready var items_button: Button = %ItemsButton
@onready var blessing_button: Button = %BlessingButton
@onready var items_panel: PanelContainer = %ItemsPanel
@onready var items_container: VBoxContainer = %ItemsContainer

@onready var toast_panel: PanelContainer = %ToastPanel
@onready var toast_label: Label = %ToastLabel
@onready var victory_panel: PanelContainer = %VictoryPanel
@onready var victory_text: Label = %VictoryText

# Battle Data
var character_id: String = "mangyan"
var player_max_hp: int = 100
var player_current_hp: int = 100

var enemy_id: String = "crab"
var enemy_name: String = "Forest Crab"
var enemy_max_hp: int = 45
var enemy_current_hp: int = 45
var enemy_is_boss: bool = false
var boss_phase: int = 1

var current_turn: TurnState = TurnState.PLAYER_TURN
var current_combo: int = 1
var has_focus_leaf: bool = false
var has_forest_blessing: bool = false
var blessing_used_this_battle: bool = false
var enemy_charging: bool = false
var enemy_defense_buff: float = 1.0

# Letter Pool & Selection
var letter_pool: Array[String] = []
var selected_tile_indices: Array[int] = []
var locked_tile_indices: Array[int] = []
var letter_buttons: Array[Button] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	items_panel.visible = false
	toast_panel.visible = false
	victory_panel.visible = false
	
	attack_button.pressed.connect(_on_attack_pressed)
	clear_button.pressed.connect(_on_clear_pressed)
	scramble_button.pressed.connect(_on_scramble_pressed)
	items_button.pressed.connect(_on_items_button_pressed)
	blessing_button.pressed.connect(_on_blessing_pressed)

var stage_index: int = 1
var stage_chapter: int = 1

func setup_battle(
	char_id: String,
	p_hp: int,
	p_max_hp: int,
	e_id: String,
	e_name: String,
	e_hp: int,
	e_boss: bool = false,
	_bg_theme: String = "forest",
	stg_num: int = 1,
	stg_chap: int = 1
) -> void:
	stage_index = stg_num
	stage_chapter = stg_chap
	character_id = char_id
	player_current_hp = p_hp
	player_max_hp = p_max_hp
	
	enemy_id = e_id
	enemy_name = e_name
	enemy_max_hp = e_hp
	enemy_current_hp = e_hp
	enemy_is_boss = e_boss
	boss_phase = 1
	
	current_combo = 1
	has_focus_leaf = false
	has_forest_blessing = false
	blessing_used_this_battle = false
	enemy_charging = false
	enemy_defense_buff = 1.0
	locked_tile_indices.clear()
	
	_setup_hero_visuals()
	_setup_enemy_visuals()
	_update_ui()
	_generate_letters()
	_update_word_preview()
	_prepare_enemy_intent()
	
	# Update Blessing button visibility based on Inventory
	if InventoryManager and InventoryManager.has_artifact("forest_relic"):
		blessing_button.visible = true
		blessing_button.disabled = false
	else:
		blessing_button.visible = false
		
	show_toast("Word Battle Started! Create words to strike!")

func _setup_hero_visuals() -> void:
	hero_name_label.text = GameManager.get_selected_character_data().get("name", "Explorer")
	_build_hero_spritesheet(character_id)
	_play_hero_anim("idle")

func _setup_enemy_visuals() -> void:
	enemy_name_label.text = enemy_name
	enemy_phase_label.visible = enemy_is_boss
	if enemy_is_boss:
		enemy_phase_label.text = "PHASE 1/3"
		
	# Setup enemy animations / frames
	var frames = SpriteFrames.new()
	frames.add_animation("idle")
	
	match enemy_id:
		"crab":
			for i in range(1, 5):
				var path = "res://assets/enemies/crab_walk_%d.png" % i
				if ResourceLoader.exists(path):
					frames.add_frame("idle", load(path))
		"coral_crab":
			for i in range(1, 5):
				var path = "res://assets/enemies/coral_crab_walk_%d.png" % i
				if ResourceLoader.exists(path):
					frames.add_frame("idle", load(path))
		"boar":
			for i in range(1, 5):
				var path = "res://assets/enemies/boar_walk_%d.png" % i
				if ResourceLoader.exists(path):
					frames.add_frame("idle", load(path))
		"jellyfish":
			for i in range(1, 5):
				var path = "res://assets/enemies/jellyfish_walk_%d.png" % i
				if ResourceLoader.exists(path):
					frames.add_frame("idle", load(path))
		"spirit":
			for i in range(1, 5):
				var path = "res://assets/enemies/spirit_walk_%d.png" % i
				if ResourceLoader.exists(path):
					frames.add_frame("idle", load(path))
		"sea_serpent":
			for i in range(1, 5):
				var path = "res://assets/enemies/sea_serpent_walk_%d.png" % i
				if ResourceLoader.exists(path):
					frames.add_frame("idle", load(path))
		"boss":
			for i in range(1, 5):
				var path = "res://assets/enemies/boss_walk_%d.png" % i
				if ResourceLoader.exists(path):
					frames.add_frame("idle", load(path))
		"water_guardian":
			for i in range(1, 5):
				var path = "res://assets/enemies/water_guardian_walk_%d.png" % i
				if ResourceLoader.exists(path):
					frames.add_frame("idle", load(path))
		"skeleton_warrior":
			for i in range(1, 5):
				var path = "res://assets/enemies/skeleton_warrior_walk_%d.png" % i
				if ResourceLoader.exists(path):
					frames.add_frame("idle", load(path))
		"ruin_bat":
			for i in range(1, 5):
				var path = "res://assets/enemies/ruin_bat_walk_%d.png" % i
				if ResourceLoader.exists(path):
					frames.add_frame("idle", load(path))
		"stone_golem":
			for i in range(1, 5):
				var path = "res://assets/enemies/stone_golem_walk_%d.png" % i
				if ResourceLoader.exists(path):
					frames.add_frame("idle", load(path))
		"ruin_guardian":
			for i in range(1, 5):
				var path = "res://assets/enemies/ruin_guardian_walk_%d.png" % i
				if ResourceLoader.exists(path):
					frames.add_frame("idle", load(path))
					
	if frames.has_animation("idle") and frames.get_frame_count("idle") > 0:
		frames.set_animation_speed("idle", 4.0)
		frames.set_animation_loop("idle", true)
		enemy_sprite.sprite_frames = frames
		enemy_sprite.play("idle")
		enemy_sprite.visible = true
		if enemy_static_sprite:
			enemy_static_sprite.visible = false
	else:
		# Fallback to static sprite
		var fallback_path = "res://assets/enemies/%s.png" % enemy_id
		if ResourceLoader.exists(fallback_path):
			enemy_static_sprite.texture = load(fallback_path)
			enemy_static_sprite.visible = true
			enemy_sprite.visible = false

func _build_hero_spritesheet(char_id: String) -> void:
	var base_path: String = "res://characters/%s/" % char_id
	var frames: SpriteFrames = SpriteFrames.new()
	
	var actions = ["idle", "walk", "attack", "hurt", "death"]
	for act in actions:
		var file_path = "%s%s_right.png" % [base_path, act]
		if not ResourceLoader.exists(file_path):
			file_path = "%s%s_down.png" % [base_path, act]
		if ResourceLoader.exists(file_path):
			frames.add_animation(act)
			frames.set_animation_speed(act, 5.0)
			frames.set_animation_loop(act, act in ["idle", "walk"])
			frames.add_frame(act, load(file_path))
			
	hero_sprite.sprite_frames = frames

func _play_hero_anim(anim: String) -> void:
	if hero_sprite and hero_sprite.sprite_frames and hero_sprite.sprite_frames.has_animation(anim):
		hero_sprite.play(anim)

# --- Letter Generation & Management ---

func _generate_letters() -> void:
	for child in letter_grid.get_children():
		child.queue_free()
	letter_buttons.clear()
	selected_tile_indices.clear()
	
	if WordValidator:
		letter_pool = WordValidator.generate_letter_pool(16)
	else:
		letter_pool = ["T", "R", "E", "E", "W", "A", "T", "E", "R", "F", "I", "R", "E", "S", "U", "N"]
		
	for i in range(letter_pool.size()):
		var btn = Button.new()
		var letter = letter_pool[i]
		var score = WordValidator.LETTER_SCORES.get(letter, 1) if WordValidator else 1
		btn.text = "%s\n%d" % [letter, score]
		btn.custom_minimum_size = Vector2(56, 56)
		btn.add_theme_font_size_override("font_size", 16)
		
		# Custom tropical button styling
		var is_rare = WordValidator.RARE_LETTERS.has(letter) if WordValidator else false
		if is_rare:
			btn.modulate = Color(1.0, 0.9, 0.4) # Gold highlight for rare letters
		
		var idx = i
		btn.pressed.connect(func(): _on_tile_pressed(idx))
		letter_grid.add_child(btn)
		letter_buttons.append(btn)
		
	_apply_locked_tiles()

func _apply_locked_tiles() -> void:
	for i in range(letter_buttons.size()):
		if locked_tile_indices.has(i):
			letter_buttons[i].disabled = true
			letter_buttons[i].modulate = Color(0.6, 0.4, 0.8) # Purple entangled
		else:
			var letter = letter_pool[i]
			var is_rare = WordValidator.RARE_LETTERS.has(letter) if WordValidator else false
			letter_buttons[i].disabled = selected_tile_indices.has(i)
			letter_buttons[i].modulate = Color(1.0, 0.9, 0.4) if is_rare else (Color(0.5, 0.5, 0.5) if selected_tile_indices.has(i) else Color.WHITE)

func _on_tile_pressed(index: int) -> void:
	if current_turn != TurnState.PLAYER_TURN:
		return
	if locked_tile_indices.has(index):
		return
		
	if selected_tile_indices.has(index):
		# Deselect
		selected_tile_indices.erase(index)
		AudioManager.play_tile_deselect()
	else:
		# Select
		selected_tile_indices.append(index)
		AudioManager.play_tile_click()
		
	_apply_locked_tiles()
	_update_word_preview()

func _unhandled_input(event: InputEvent) -> void:
	if current_turn != TurnState.PLAYER_TURN:
		return
		
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_BACKSPACE:
			if selected_tile_indices.size() > 0:
				selected_tile_indices.pop_back()
				AudioManager.play_tile_deselect()
				_apply_locked_tiles()
				_update_word_preview()
				get_viewport().set_input_as_handled()
		elif event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
			_on_attack_pressed()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_ESCAPE:
			_on_clear_pressed()
			get_viewport().set_input_as_handled()
		else:
			# Check letter typing
			var char_typed = OS.get_keycode_string(event.keycode).to_upper()
			if char_typed.length() == 1 and char_typed >= "A" and char_typed <= "Z":
				# Find first unselected matching tile
				for i in range(letter_pool.size()):
					if letter_pool[i] == char_typed and not selected_tile_indices.has(i) and not locked_tile_indices.has(i):
						selected_tile_indices.append(i)
						AudioManager.play_tile_click()
						_apply_locked_tiles()
						_update_word_preview()
						get_viewport().set_input_as_handled()
						break

func _get_current_word() -> String:
	var word: String = ""
	for idx in selected_tile_indices:
		word += letter_pool[idx]
	return word

func _update_word_preview() -> void:
	var word = _get_current_word()
	word_display.text = word if word != "" else "[ SELECT LETTERS ]"
	
	if word == "":
		word_preview_label.text = "Select letters to form a word."
		rating_label.text = ""
		attack_button.disabled = true
		return
		
	var is_valid = WordValidator.is_valid_word(word) if WordValidator else (word.length() >= 3)
	if is_valid:
		attack_button.disabled = false
		var calc = DamageCalculator.calculate_attack(word, current_combo, character_id, has_focus_leaf, has_forest_blessing)
		var elem_tag = " [%s +%d%%]" % [calc["element"], int((calc["element_multiplier"] - 1.0) * 100)] if calc["element"] != "NONE" else ""
		var rare_tag = " [RARE +%d]" % calc["rare_bonus"] if calc["rare_bonus"] > 0 else ""
		var buff_tag = " [FOCUS +50%]" if has_focus_leaf else ""
		var relic_tag = " [BLESSING x2]" if (has_forest_blessing and word.length() >= 5) else ""
		
		word_preview_label.text = "Damage: %d%s%s%s%s (Combo x%.2f)" % [
			calc["final_damage"],
			elem_tag,
			rare_tag,
			buff_tag,
			relic_tag,
			calc["combo_multiplier"]
		]
		rating_label.text = calc["rating"]
		word_display.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))
	else:
		attack_button.disabled = (word.length() < 3)
		word_preview_label.text = "Invalid word (not in dictionary)"
		rating_label.text = ""
		word_display.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))

# --- Actions & Attack Execution ---

func _on_attack_pressed() -> void:
	if current_turn != TurnState.PLAYER_TURN:
		return
		
	var word = _get_current_word()
	if word.length() < 2:
		show_toast("Form a word with 2 or more letters!")
		AudioManager.play_word_invalid()
		return
		
	var is_valid = WordValidator.is_valid_word(word) if WordValidator else false
	if not is_valid:
		show_toast("'%s' is not a recognized word!" % word)
		AudioManager.play_word_invalid()
		return
		
	_execute_player_attack(word)

func _execute_player_attack(word: String) -> void:
	current_turn = TurnState.PLAYER_ANIMATING
	_disable_buttons(true)
	
	var calc = DamageCalculator.calculate_attack(word, current_combo, character_id, has_focus_leaf, has_forest_blessing)
	var final_damage = int(round(calc["final_damage"] * enemy_defense_buff))
	
	# Consume buffs
	if has_focus_leaf:
		has_focus_leaf = false
	if has_forest_blessing:
		has_forest_blessing = false
		
	# Play attack animation
	AudioManager.play_word_valid()
	_play_hero_anim("attack")
	
	# Word pop effect on UI
	var tween = create_tween()
	tween.tween_property(word_display, "scale", Vector2(1.3, 1.3), 0.15)
	tween.tween_property(word_display, "scale", Vector2(1.0, 1.0), 0.15)
	
	await get_tree().create_timer(0.4).timeout
	
	# Play elemental FX and sound
	AudioManager.play_attack_spell(calc["element"], calc["is_critical"])
	BattleVFX.play_spell_effect(self, enemy_sprite.global_position if enemy_sprite.visible else enemy_static_sprite.global_position, calc["element"], calc["is_critical"])
	
	# Floating damage number
	var dmg_color = Color(1.0, 0.9, 0.2) if calc["is_critical"] else Color.WHITE
	BattleVFX.show_floating_text(self, enemy_sprite.global_position if enemy_sprite.visible else enemy_static_sprite.global_position, "-%d" % final_damage, dmg_color, 24 if calc["is_critical"] else 18)
	
	# Enemy reaction
	_damage_enemy(final_damage)
	
	# Heal hero if Nature bonus
	if calc["hp_heal"] > 0:
		player_current_hp = mini(player_max_hp, player_current_hp + calc["hp_heal"])
		BattleVFX.show_floating_text(self, hero_sprite.global_position, "+%d HP" % calc["hp_heal"], Color(0.3, 1.0, 0.4), 18)
		
	# Increment Combo
	current_combo += 1
	AudioManager.play_combo_up(current_combo)
	show_toast("%s! Combo x%d" % [calc["rating"], current_combo])
	
	# Clear used letters & replenish board
	_replenish_used_letters()
	_update_ui()
	_play_hero_anim("idle")
	
	await get_tree().create_timer(0.8).timeout
	
	if enemy_current_hp <= 0:
		_on_battle_victory()
	else:
		_start_enemy_turn()

func _replenish_used_letters() -> void:
	# Replace used tiles with new random letters
	var new_letters = WordValidator.generate_letter_pool(selected_tile_indices.size()) if WordValidator else []
	for i in range(selected_tile_indices.size()):
		var idx = selected_tile_indices[i]
		letter_pool[idx] = new_letters[i] if i < new_letters.size() else "E"
		
	selected_tile_indices.clear()
	
	# If boss had locked tiles and player made a great word (5+), unlock some
	if locked_tile_indices.size() > 0:
		locked_tile_indices.pop_back()
		
	# Refresh button labels
	for i in range(letter_buttons.size()):
		var letter = letter_pool[i]
		var score = WordValidator.LETTER_SCORES.get(letter, 1) if WordValidator else 1
		letter_buttons[i].text = "%s\n%d" % [letter, score]
		
	_apply_locked_tiles()
	_update_word_preview()

func _on_clear_pressed() -> void:
	if current_turn != TurnState.PLAYER_TURN:
		return
	selected_tile_indices.clear()
	AudioManager.play_tile_deselect()
	_apply_locked_tiles()
	_update_word_preview()

func _on_scramble_pressed() -> void:
	if current_turn != TurnState.PLAYER_TURN:
		return
	letter_pool.shuffle()
	selected_tile_indices.clear()
	AudioManager.play_tile_click()
	
	for i in range(letter_buttons.size()):
		var letter = letter_pool[i]
		var score = WordValidator.LETTER_SCORES.get(letter, 1) if WordValidator else 1
		letter_buttons[i].text = "%s\n%d" % [letter, score]
		
	_apply_locked_tiles()
	_update_word_preview()
	show_toast("Letter pool scrambled!")

func _on_blessing_pressed() -> void:
	if blessing_used_this_battle:
		show_toast("Forest's Blessing already used this battle!")
		return
	if not has_forest_blessing:
		has_forest_blessing = true
		blessing_used_this_battle = true
		blessing_button.disabled = true
		AudioManager.play_item_use()
		show_toast("Forest's Blessing Activated! Next 5+ letter word deals DOUBLE damage!")
		_update_word_preview()

# --- Items System ---

func _on_items_button_pressed() -> void:
	items_panel.visible = !items_panel.visible
	if items_panel.visible:
		_populate_items_list()

func _populate_items_list() -> void:
	for c in items_container.get_children():
		c.queue_free()
		
	if not InventoryManager:
		return
		
	for item_id in InventoryManager.CONSUMABLE_DEFINITIONS:
		var count = InventoryManager.get_consumable_count(item_id)
		if count > 0:
			var def = InventoryManager.CONSUMABLE_DEFINITIONS[item_id]
			var btn = Button.new()
			btn.text = "%s x%d (%s)" % [def["name"], count, def["description"]]
			btn.pressed.connect(func(): _use_item(item_id))
			items_container.add_child(btn)
			
	if items_container.get_child_count() == 0:
		var lbl = Label.new()
		lbl.text = "No consumables in bag."
		items_container.add_child(lbl)

func _use_item(item_id: String) -> void:
	if not InventoryManager.use_consumable(item_id):
		return
		
	items_panel.visible = false
	AudioManager.play_item_use()
	
	match item_id:
		"healing_fruit":
			player_current_hp = mini(player_max_hp, player_current_hp + 35)
			BattleVFX.show_floating_text(self, hero_sprite.global_position, "+35 HP", Color(0.2, 1.0, 0.4), 20)
			show_toast("Used Healing Fruit! Restored 35 HP.")
		"tropical_potion":
			player_current_hp = mini(player_max_hp, player_current_hp + 80)
			BattleVFX.show_floating_text(self, hero_sprite.global_position, "+80 HP", Color(0.2, 1.0, 0.4), 22)
			show_toast("Used Tropical Potion! Restored 80 HP.")
		"focus_leaf":
			has_focus_leaf = true
			show_toast("Used Focus Leaf! Next attack deals +50% DMG.")
		"ancient_tonic":
			current_combo = 4
			show_toast("Used Ancient Tonic! Word Combo set to Max!")
			
	_update_ui()
	_update_word_preview()
# --- Enemy Turn & Boss AI ---

func _prepare_enemy_intent() -> void:
	match enemy_id:
		"crab", "coral_crab":
			if randf() < 0.35:
				enemy_intent_label.text = "Intent: Harden Shell (Defend)"
			else:
				enemy_intent_label.text = "Intent: Claw Snap (~10 DMG)"
		"boar":
			if enemy_charging:
				enemy_intent_label.text = "Intent: UNLEASH CHARGE! (~28 DMG!)"
			elif randf() < 0.4:
				enemy_intent_label.text = "Intent: Preparing Charge..."
			else:
				enemy_intent_label.text = "Intent: Tusk Gore (~14 DMG)"
		"jellyfish":
			if randf() < 0.45:
				enemy_intent_label.text = "Intent: Bio-Electric Shock (Lock 2 Tiles)"
			else:
				enemy_intent_label.text = "Intent: Stinging Tentacles (~12 DMG)"
		"spirit":
			if randf() < 0.45:
				enemy_intent_label.text = "Intent: Spore Confusion (Lock Tiles)"
			else:
				enemy_intent_label.text = "Intent: Mystic Orb (~12 DMG)"
		"sea_serpent":
			if randf() < 0.4:
				enemy_intent_label.text = "Intent: Tidal Maelstrom (~20 DMG)"
			else:
				enemy_intent_label.text = "Intent: Abyssal Bite (~15 DMG)"
		"boss":
			match boss_phase:
				1:
					enemy_intent_label.text = "Intent: Ancient Root Whip (~16 DMG)"
				2:
					enemy_intent_label.text = "Intent: Entangling Roots (Vines Lock)"
				3:
					enemy_intent_label.text = "Intent: TITAN GROUND SLAM (~30 DMG!)"
		"water_guardian":
			match boss_phase:
				1:
					enemy_intent_label.text = "Intent: Tidal Wave Barrier (~18 DMG)"
				2:
					enemy_intent_label.text = "Intent: Whirlpool Maelstrom (Locks 3 Tiles)"
				3:
					enemy_intent_label.text = "Intent: TSUNAMI STRIKE (~34 DMG!)"
		"skeleton_warrior":
			if randf() < 0.35:
				enemy_intent_label.text = "Intent: Bone Shield (+50% Defense)"
			else:
				enemy_intent_label.text = "Intent: Cleaving Bone Slash (~14 DMG)"
		"ruin_bat":
			if randf() < 0.4:
				enemy_intent_label.text = "Intent: Ultrasonic Screech (Locks 2 Tiles)"
			else:
				enemy_intent_label.text = "Intent: Shadow Leech (~12 DMG + Heals)"
		"stone_golem":
			if randf() < 0.4:
				enemy_intent_label.text = "Intent: Heavy Boulder Toss (~20 DMG!)"
			else:
				enemy_intent_label.text = "Intent: Stone Fortify (+50% Defense)"
		"ruin_guardian":
			match boss_phase:
				1:
					enemy_intent_label.text = "Intent: Colossal Earth Stomp (~20 DMG)"
				2:
					enemy_intent_label.text = "Intent: Ruin Cave-In (Locks 4 Tiles)"
				3:
					enemy_intent_label.text = "Intent: CATACLYSMIC TITAN SMASH (~40 DMG!)"

func _start_enemy_turn() -> void:
	current_turn = TurnState.ENEMY_TURN
	_disable_buttons(true)
	show_toast("%s's Turn..." % enemy_name)
	
	await get_tree().create_timer(0.9).timeout
	_execute_enemy_action()

func _execute_enemy_action() -> void:
	var enemy_node: Node2D = enemy_sprite if enemy_sprite.visible else enemy_static_sprite
	
	# Lunge enemy towards hero
	var original_pos = enemy_node.position
	var tween = create_tween()
	tween.tween_property(enemy_node, "position:x", original_pos.x - 40, 0.15)
	tween.tween_property(enemy_node, "position:x", original_pos.x, 0.15)
	
	# Check boss phase progression based on HP
	if enemy_is_boss:
		var hp_percent = float(enemy_current_hp) / float(enemy_max_hp)
		if hp_percent <= 0.33 and boss_phase < 3:
			boss_phase = 3
			enemy_phase_label.text = "PHASE 3/3 (ENRAGED)"
			show_toast("%s enters Phase 3! Enraged Titan Fury Awakened!" % enemy_name)
		elif hp_percent <= 0.66 and boss_phase < 2:
			boss_phase = 2
			enemy_phase_label.text = "PHASE 2/3"
			show_toast("%s enters Phase 2! Earthquakes Rock the Ruins!" % enemy_name)
			
	# Determine damage & ability
	var enemy_damage: int = 10
	var special_effect: String = ""
	
	match enemy_id:
		"crab", "coral_crab":
			if enemy_intent_label.text.contains("Harden"):
				enemy_defense_buff = 0.55
				show_toast("%s hardens its shell! (+45%% Defense)" % enemy_name)
				special_effect = "defend"
				enemy_damage = 0
			else:
				enemy_damage = randi_range(8, 13)
				enemy_defense_buff = 1.0
		"boar":
			if enemy_charging:
				enemy_damage = randi_range(24, 32)
				enemy_charging = false
				show_toast("Jungle Boar crashes in with a devastating CHARGE!")
			elif enemy_intent_label.text.contains("Preparing"):
				enemy_charging = true
				enemy_damage = 0
				show_toast("Jungle Boar is scraping the ground, preparing to CHARGE next turn!")
			else:
				enemy_damage = randi_range(11, 15)
		"jellyfish":
			if enemy_intent_label.text.contains("Shock"):
				enemy_damage = randi_range(7, 10)
				_lock_random_tiles(2)
				show_toast("Abyssal Jellyfish discharges electric shocks! 2 tiles locked!")
			else:
				enemy_damage = randi_range(11, 15)
		"spirit":
			if enemy_intent_label.text.contains("Confusion"):
				enemy_damage = randi_range(5, 8)
				_lock_random_tiles(2)
				show_toast("Forest Spirit scatters confusion spores! 2 tiles locked!")
			else:
				enemy_damage = randi_range(10, 14)
		"sea_serpent":
			if enemy_intent_label.text.contains("Maelstrom"):
				enemy_damage = randi_range(18, 24)
				show_toast("Tide Serpent unleashes a furious tidal surge!")
			else:
				enemy_damage = randi_range(13, 17)
		"boss":
			match boss_phase:
				1:
					enemy_damage = randi_range(14, 18)
				2:
					enemy_damage = randi_range(12, 16)
					_lock_random_tiles(3)
					show_toast("Roots erupted from the ground, entangling 3 tiles!")
				3:
					enemy_damage = randi_range(24, 32)
					show_toast("Forest Guardian slams the earth in a titanic shockwave!")
		"water_guardian":
			match boss_phase:
				1:
					enemy_damage = randi_range(16, 20)
				2:
					enemy_damage = randi_range(14, 18)
					_lock_random_tiles(3)
					show_toast("Whirlpool Maelstrom sweeps the arena, locking 3 tiles!")
				3:
					enemy_damage = randi_range(28, 36)
					show_toast("THE WATER GUARDIAN CRASHES DOWN WITH A CATASTROPHIC TSUNAMI!")
		"skeleton_warrior":
			if enemy_intent_label.text.contains("Shield"):
				enemy_defense_buff = 0.5
				show_toast("Skeleton Warrior raises ancient bone shield! (+50% Defense)")
				enemy_damage = 0
			else:
				enemy_damage = randi_range(12, 16)
				enemy_defense_buff = 1.0
		"ruin_bat":
			if enemy_intent_label.text.contains("Screech"):
				enemy_damage = randi_range(6, 9)
				_lock_random_tiles(2)
				show_toast("Cave Bat lets out a piercing screech! 2 tiles locked!")
			else:
				enemy_damage = randi_range(11, 14)
				enemy_current_hp = mini(enemy_max_hp, enemy_current_hp + 10)
				show_toast("Cave Bat leeches health (+10 HP)!")
		"stone_golem":
			if enemy_intent_label.text.contains("Fortify"):
				enemy_defense_buff = 0.45
				show_toast("Stone Golem hardens into solid granite! (+55% Defense)")
				enemy_damage = 0
			else:
				enemy_damage = randi_range(18, 24)
				enemy_defense_buff = 1.0
				show_toast("Stone Golem hurled a massive boulder!")
		"ruin_guardian":
			match boss_phase:
				1:
					enemy_damage = randi_range(18, 24)
					show_toast("Ruin Guardian Titan shakes the floor with a heavy stomp!")
				2:
					enemy_damage = randi_range(16, 20)
					_lock_random_tiles(4)
					show_toast("Ruin Cave-In! Falling stones lock 4 tiles!")
				3:
					enemy_damage = randi_range(32, 42)
					show_toast("THE RUIN GUARDIAN UNLEASHES A TITAN EARTH-SHATTERS IMPACT!")
					
	if enemy_damage > 0:
		# Player takes damage
		if character_id == "igorot":
			enemy_damage = int(round(enemy_damage * 0.8)) # Igorot passive resilience
			
		player_current_hp = max(0, player_current_hp - enemy_damage)
		AudioManager.play_player_hurt()
		_play_hero_anim("hurt")
		BattleVFX.show_floating_text(self, hero_sprite.global_position, "-%d" % enemy_damage, Color(1.0, 0.3, 0.3), 20)
		
		# Reset combo on heavy hits
		if enemy_damage >= 20:
			current_combo = 1
			show_toast("Heavy Hit! Word Combo Reset.")
			
	_update_ui()
	await get_tree().create_timer(0.6).timeout
	_play_hero_anim("idle")
	
	if player_current_hp <= 0:
		_on_battle_defeat()
	else:
		_prepare_enemy_intent()
		current_turn = TurnState.PLAYER_TURN
		_disable_buttons(false)

func _lock_random_tiles(count: int) -> void:
	var available_indices: Array[int] = []
	for i in range(letter_pool.size()):
		if not locked_tile_indices.has(i):
			available_indices.append(i)
			
	available_indices.shuffle()
	for i in range(mini(count, available_indices.size())):
		locked_tile_indices.append(available_indices[i])
		
	_apply_locked_tiles()

func _damage_enemy(amount: int) -> void:
	enemy_current_hp = max(0, enemy_current_hp - amount)
	AudioManager.play_enemy_hit()
	
	var enemy_node = enemy_sprite if enemy_sprite.visible else enemy_static_sprite
	var tween = create_tween()
	tween.tween_property(enemy_node, "modulate", Color(1, 0.2, 0.2), 0.1)
	tween.tween_property(enemy_node, "modulate", Color.WHITE, 0.15)
	_update_ui()

# --- UI Helpers & End States ---

func _update_ui() -> void:
	hero_hp_bar.max_value = player_max_hp
	hero_hp_bar.value = player_current_hp
	hero_hp_label.text = "HP: %d / %d" % [player_current_hp, player_max_hp]
	
	enemy_hp_bar.max_value = enemy_max_hp
	enemy_hp_bar.value = enemy_current_hp
	enemy_hp_label.text = "HP: %d / %d" % [enemy_current_hp, enemy_max_hp]
	
	combo_label.text = "COMBO: x%d" % current_combo
	
	var buffs: Array[String] = []
	if has_focus_leaf:
		buffs.append("FOCUS +50%")
	if has_forest_blessing:
		buffs.append("BLESSING x2")
	hero_buff_label.text = "BUFFS: " + (", ".join(buffs) if buffs.size() > 0 else "None")

func _disable_buttons(disable: bool) -> void:
	attack_button.disabled = disable or (_get_current_word().length() < 2)
	clear_button.disabled = disable
	scramble_button.disabled = disable
	items_button.disabled = disable
	if not blessing_used_this_battle and InventoryManager and InventoryManager.has_artifact("forest_relic"):
		blessing_button.disabled = disable

func show_toast(text: String) -> void:
	toast_label.text = text
	toast_panel.visible = true
	toast_panel.modulate.a = 1.0
	
	var tween = create_tween()
	tween.tween_interval(1.8)
	tween.tween_property(toast_panel, "modulate:a", 0.0, 0.4)
	tween.tween_callback(func(): toast_panel.visible = false)

func _on_battle_victory() -> void:
	current_turn = TurnState.BATTLE_END
	_disable_buttons(true)
	AudioManager.play_victory_fanfare()
	_play_hero_anim("idle")
	
	# Mark stage complete in GameManager
	if GameManager:
		GameManager.complete_stage(stage_index, stage_chapter)
		GameManager.current_health = player_current_hp
		
	# Gather stage loot drops
	var loot_lines: Array[String] = []
	var stage_data: Dictionary = GameManager.get_stage_data(stage_index, stage_chapter) if GameManager else {}
	var loot_table: Array = stage_data.get("loot", [])
	
	for drop in loot_table:
		var chance: float = drop.get("chance", 1.0)
		if randf() <= chance:
			var dtype: String = drop.get("type", "consumable")
			var did: String = drop.get("id", "")
			var dname: String = drop.get("name", "Item")
			var damount: int = drop.get("amount", 1)
			
			match dtype:
				"consumable":
					if InventoryManager:
						InventoryManager.add_consumable(did, damount)
					loot_lines.append("🧪 +%dx %s" % [damount, dname])
				"collectible":
					if InventoryManager:
						InventoryManager.add_collectible(did, damount)
					var emoji = "🍃" if did.contains("leaf") else ("🐚" if did.contains("shell") else "🪨")
					loot_lines.append("%s +%dx %s" % [emoji, damount, dname])
				"artifact":
					if InventoryManager:
						InventoryManager.collect_artifact(did)
					loot_lines.append("👑 +SACRED RELIC: %s!" % dname)
				"gold":
					if InventoryManager:
						InventoryManager.gold += damount
					loot_lines.append("🪙 +%d Gold" % damount)
					
	var exp_gained: int = 50 if not enemy_is_boss else 250
	loot_lines.push_front("⭐ +%d EXP" % exp_gained)
	
	# Auto-save progress
	if SaveManager:
		SaveManager.save_game()
	
	victory_text.text = "🏆 VICTORY! 🏆\n\nDefeated: %s\n\n--- LOOT DROPS ---\n%s" % [
		enemy_name,
		"\n".join(loot_lines)
	]
	victory_panel.visible = true
	
	var continue_btn = victory_panel.get_node_or_null("%ContinueButton")
	if continue_btn:
		continue_btn.pressed.connect(func():
			battle_completed.emit(true, {"stage": stage_index, "chapter": stage_chapter, "enemy_id": enemy_id})
			queue_free()
			# If this was loaded directly as standalone scene
			if get_tree().current_scene == self:
				GameManager.change_level(GameManager.ADVENTURE_MAP_PATH)
		)

func _on_battle_defeat() -> void:
	current_turn = TurnState.BATTLE_END
	_disable_buttons(true)
	_play_hero_anim("death")
	show_toast("Defeated in battle...")
	
	await get_tree().create_timer(1.8).timeout
	battle_completed.emit(false, {})
	queue_free()
	if GameManager:
		GameManager.trigger_game_over()
