extends Node

## InventoryManager.gd - Tracks artifacts, consumables, and collectibles

signal artifact_collected(artifact_id: String, artifact_name: String)
signal consumable_added(item_id: String, count: int)
signal consumable_used(item_id: String)
signal collectible_collected(collectible_id: String, current_count: int)
signal inventory_updated()

# Artifact Database
const ARTIFACT_DEFINITIONS: Dictionary = {
	"forest_relic": {
		"id": "forest_relic",
		"name": "Forest Relic",
		"location": "Stage 1 — The Coastal Village",
		"description": "An ancient wooden relic pulsing with primal nature magic. Unlocks active skill: Forest's Blessing (Doubles the damage of 5+ letter words once per battle).",
		"icon_path": "res://assets/items/forest_relic.png",
		"active_skill": "Forest's Blessing"
	},
	"water_relic": {
		"id": "water_relic",
		"name": "Ocean Pearl (Water Relic)",
		"location": "Stage 2 — The Sunken Coast",
		"description": "A radiant sacred pearl that commands the tides. Water words deal +50% bonus damage and heal the player.",
		"icon_path": "res://assets/items/water_relic.png",
		"active_skill": "Ocean's Blessing"
	},
	"pearl_shell": {
		"id": "pearl_shell",
		"name": "Pearl Shell",
		"location": "Stage 2 — The Sunken Coast",
		"description": "A lustrous shell humming with ocean currents. Grants passive Water word damage bonus.",
		"icon_path": "res://assets/items/lost_shell.png",
		"active_skill": "Tidal Surge"
	},
	"ancient_stone": {
		"id": "ancient_stone",
		"name": "The Ancient Stone (Earth Relic)",
		"location": "Stage 3 — The Forgotten Ruins",
		"description": "An intricately carved monolith resonant with forgotten earth magic. Earth & ancient words deal +60% bonus damage!",
		"icon_path": "res://assets/items/ancient_stone_relic.png",
		"active_skill": "Earth Tremor"
	},
	"ancient_heart": {
		"id": "ancient_heart",
		"name": "The Ancient Heart (Ultimate Sacred Relic)",
		"location": "Final Stage — The Ancient Heart",
		"description": "The primordial source of balance and life. Empowers all elemental words with +100% damage and restores harmony to the Pearl of the South!",
		"icon_path": "res://assets/items/ancient_heart_relic.png",
		"active_skill": "Heart of Creation"
	}
}

# Consumable items for battle and exploration
const CONSUMABLE_DEFINITIONS: Dictionary = {
	"healing_fruit": {
		"id": "healing_fruit",
		"name": "Healing Fruit",
		"description": "A sweet tropical fruit that restores 35 HP.",
		"heal_amount": 35,
		"effect": "heal"
	},
	"tropical_potion": {
		"id": "tropical_potion",
		"name": "Tropical Potion",
		"description": "A restorative herbal brew that restores 80 HP.",
		"heal_amount": 80,
		"effect": "heal"
	},
	"focus_leaf": {
		"id": "focus_leaf",
		"name": "Focus Leaf",
		"description": "Empowers your focus, boosting the next word's attack damage by +50%.",
		"effect": "damage_boost"
	},
	"ancient_tonic": {
		"id": "ancient_tonic",
		"name": "Ancient Tonic",
		"description": "Maxes out the word combo multiplier for your next attack.",
		"effect": "combo_max"
	}
}

# State
var collected_artifacts: Dictionary = {
	"forest_relic": false,
	"water_relic": false,
	"pearl_shell": false,
	"ancient_stone": false,
	"ancient_heart": false
}

var consumable_counts: Dictionary = {
	"healing_fruit": 2,
	"tropical_potion": 1,
	"focus_leaf": 1,
	"ancient_tonic": 1
}

var collectible_counts: Dictionary = {
	"ancient_leaf": 0,
	"lost_shell": 0,
	"stone_fragment": 0
}

var gold: int = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	print("[InventoryManager] Initialized successfully.")

# --- Artifact Methods ---

func collect_artifact(artifact_id: String) -> bool:
	if ARTIFACT_DEFINITIONS.has(artifact_id):
		if not collected_artifacts.get(artifact_id, false):
			collected_artifacts[artifact_id] = true
			var artifact_name: String = ARTIFACT_DEFINITIONS[artifact_id]["name"]
			artifact_collected.emit(artifact_id, artifact_name)
			inventory_updated.emit()
			print("[InventoryManager] Artifact Acquired: %s" % artifact_name)
			if has_node("/root/SaveManager"):
				get_node("/root/SaveManager").save_game()
			return true
	return false

func has_artifact(artifact_id: String) -> bool:
	return collected_artifacts.get(artifact_id, false)

func get_collected_count() -> int:
	var count: int = 0
	for key in collected_artifacts:
		if collected_artifacts[key]:
			count += 1
	return count

# --- Consumables Methods ---

func add_consumable(item_id: String, amount: int = 1) -> void:
	consumable_counts[item_id] = consumable_counts.get(item_id, 0) + amount
	consumable_added.emit(item_id, consumable_counts[item_id])
	inventory_updated.emit()

func use_consumable(item_id: String) -> bool:
	if consumable_counts.get(item_id, 0) > 0:
		consumable_counts[item_id] -= 1
		consumable_used.emit(item_id)
		inventory_updated.emit()
		return true
	return false

func get_consumable_count(item_id: String) -> int:
	return consumable_counts.get(item_id, 0)

# --- Collectibles Methods ---

func add_collectible(collectible_type: String, amount: int = 1) -> void:
	var key: String = collectible_type.to_lower()
	collectible_counts[key] = collectible_counts.get(key, 0) + amount
	collectible_collected.emit(key, collectible_counts[key])
	inventory_updated.emit()

func get_collectible_count(collectible_type: String) -> int:
	return collectible_counts.get(collectible_type.to_lower(), 0)

func reset_inventory() -> void:
	collected_artifacts = {
		"forest_relic": false,
		"pearl_shell": false,
		"ancient_stone": false
	}
	consumable_counts = {
		"healing_fruit": 2,
		"tropical_potion": 1,
		"focus_leaf": 1,
		"ancient_tonic": 1
	}
	collectible_counts = {
		"ancient_leaf": 0,
		"lost_shell": 0,
		"stone_fragment": 0
	}
	gold = 0
	inventory_updated.emit()
	print("[InventoryManager] Inventory reset to initial state.")
