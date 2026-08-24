extends Node

## DamageCalculator.gd - Word battle damage, elemental multipliers, combo scaling, and buffs

const BASE_DAMAGE_TABLE: Dictionary = {
	2: 8,
	3: 14,
	4: 24,
	5: 42,
	6: 68,
	7: 102,
	8: 145,
	9: 195,
	10: 250
}

const ELEMENTAL_MULTIPLIERS: Dictionary = {
	"NATURE": 1.25,
	"WATER": 1.25,
	"FIRE": 1.30,
	"ANCIENT": 1.35,
	"WIND": 1.20,
	"NONE": 1.0
}

const COMBO_MULTIPLIERS: Array[float] = [
	1.0,   # Combo 1 (base)
	1.25,  # Combo 2
	1.50,  # Combo 3
	2.00,  # Combo 4
	2.50   # Combo 5+
]

func calculate_attack(
	word: String,
	combo_count: int,
	character_id: String = "mangyan",
	has_focus_leaf: bool = false,
	has_forest_blessing: bool = false
) -> Dictionary:
	var clean_word: String = word.strip_edges().to_upper()
	var word_length: int = clean_word.length()
	
	# 1. Base Damage by length
	var base_dmg: int = BASE_DAMAGE_TABLE.get(word_length, 8)
	if word_length > 10:
		base_dmg = 250 + (word_length - 10) * 50
		
	# 2. Letter score bonus
	var letter_score: int = 0
	if WordValidator:
		letter_score = WordValidator.get_word_score(clean_word)
	var letter_bonus: int = int(round(letter_score * 1.5))
	
	# 3. Rare Letter Bonus (+12 per rare letter)
	var rare_count: int = 0
	if WordValidator:
		rare_count = WordValidator.get_rare_letter_count(clean_word)
	var rare_bonus: int = rare_count * 12
	
	# 4. Elemental Category
	var element_category: String = "NONE"
	if WordValidator:
		element_category = WordValidator.get_word_category(clean_word)
	var element_multiplier: float = ELEMENTAL_MULTIPLIERS.get(element_category, 1.0)
	
	# Character Affinity Bonus
	var char_affinity_multiplier: float = 1.0
	match character_id:
		"mangyan":
			if element_category == "NATURE":
				char_affinity_multiplier = 1.15
		"badjao":
			if element_category == "WATER":
				char_affinity_multiplier = 1.15
		"igorot":
			if element_category == "ANCIENT":
				char_affinity_multiplier = 1.15
				
	# 5. Combo Multiplier
	var clamped_combo_idx = clamp(combo_count - 1, 0, COMBO_MULTIPLIERS.size() - 1)
	var combo_multiplier: float = COMBO_MULTIPLIERS[clamped_combo_idx]
	
	# 6. Item Buff Multiplier (Focus Leaf: +50%)
	var item_multiplier: float = 1.5 if has_focus_leaf else 1.0
	
	# 7. Artifact Skill (Forest Blessing: 2x damage on 5+ letter words)
	var artifact_multiplier: float = 2.0 if (has_forest_blessing and word_length >= 5) else 1.0
	
	# Total Calculation
	var raw_damage: float = (float(base_dmg) + float(letter_bonus) + float(rare_bonus))
	var total_multiplier: float = element_multiplier * char_affinity_multiplier * combo_multiplier * item_multiplier * artifact_multiplier
	var final_damage: int = int(round(raw_damage * total_multiplier))
	
	# Rating label
	var rating: String = "GOOD WORD!"
	if word_length >= 7:
		rating = "MASTER WORD!"
	elif word_length >= 6:
		rating = "SUPERB WORD!"
	elif word_length >= 5:
		rating = "GREAT WORD!"
	elif word_length >= 4:
		rating = "NICE WORD!"
		
	# Healing / Secondary perks
	var hp_heal: int = 0
	if element_category == "NATURE" and word_length >= 4:
		hp_heal = 6 + (word_length - 4) * 4
		
	return {
		"word": clean_word,
		"length": word_length,
		"base_damage": base_dmg,
		"letter_bonus": letter_bonus,
		"rare_count": rare_count,
		"rare_bonus": rare_bonus,
		"element": element_category,
		"element_multiplier": element_multiplier,
		"combo_multiplier": combo_multiplier,
		"total_multiplier": total_multiplier,
		"final_damage": final_damage,
		"rating": rating,
		"hp_heal": hp_heal,
		"is_critical": (word_length >= 6 or rare_count > 0 or has_forest_blessing)
	}
