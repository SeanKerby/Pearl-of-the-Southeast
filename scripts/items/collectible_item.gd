extends Area2D

## collectible_item.gd - Collectible items (Leaf, Shell, Stone Fragment) for TROPICAL WORD ADVENTURE

@export var item_id: String = "ancient_leaf"
@export var item_name: String = "Ancient Leaf"
@export var item_texture: Texture2D = null

# Map item_id prefix to InventoryManager collectible key
const COLLECTIBLE_KEY_MAP: Dictionary = {
	"ancient_leaf": "ancient_leaf",
	"lost_shell": "lost_shell",
	"stone_fragment": "stone_fragment"
}

@onready var sprite: Sprite2D = $Sprite2D
@onready var label: Label = $Label

var collected: bool = false

func _ready() -> void:
	add_to_group("collectibles")
	if item_texture and sprite:
		sprite.texture = item_texture
	if label:
		label.text = item_name

	body_entered.connect(_on_body_entered)
	_start_bob()

func _start_bob() -> void:
	if sprite:
		var tween = create_tween().set_loops()
		tween.tween_property(sprite, "position:y", -3.0, 0.6).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
		tween.tween_property(sprite, "position:y", 0.0, 0.6).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and not collected:
		collect()

func collect() -> void:
	if collected:
		return
	collected = true

	# Register with InventoryManager
	var collectible_key: String = _get_collectible_key()
	if InventoryManager and collectible_key != "":
		InventoryManager.add_collectible(collectible_key, 1)

	var hud = get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("show_notification"):
		hud.show_notification("✦ %s Found!" % item_name)

	# Pop animation
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.4, 1.4), 0.1)
	tween.tween_property(self, "scale", Vector2(0.0, 0.0), 0.2)
	tween.tween_property(self, "modulate:a", 0.0, 0.15)
	await tween.finished
	queue_free()

func _get_collectible_key() -> String:
	for prefix in COLLECTIBLE_KEY_MAP:
		if item_id.begins_with(prefix):
			return COLLECTIBLE_KEY_MAP[prefix]
	return ""
