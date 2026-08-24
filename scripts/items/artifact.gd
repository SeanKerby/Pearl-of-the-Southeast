extends Area2D

## Artifact.gd - Collectible artifact item for PEARL OF SOUTHEAST

@export var artifact_id: String = "forest_relic"
@export var artifact_name: String = "Forest Relic"

@onready var sprite: Sprite2D = $Sprite2D
@onready var label: Label = $Label

var collected: bool = false

func _ready() -> void:
	add_to_group("interactable")
	collision_layer = 8
	collision_mask = 2
	body_entered.connect(_on_body_entered)
	_start_bob_animation()

func _start_bob_animation() -> void:
	var tween = create_tween().set_loops()
	tween.tween_property(sprite, "position:y", -5.0, 0.75).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_property(sprite, "position:y", 0.0, 0.75).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and not collected:
		collect()

func interact(_caller: Node) -> void:
	if not collected:
		collect()

func collect() -> void:
	if collected:
		return
	collected = true

	if InventoryManager:
		InventoryManager.collect_artifact(artifact_id)

	# Pop + fade collection animation
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.5, 1.5), 0.12)
	tween.tween_property(self, "scale", Vector2(0.0, 0.0), 0.22)
	tween.tween_property(self, "modulate:a", 0.0, 0.15)
	await tween.finished
	queue_free()
