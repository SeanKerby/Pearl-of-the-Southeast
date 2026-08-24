extends CanvasLayer

## HUD.gd - Player Heads-Up Display for TROPICAL WORD ADVENTURE

@onready var hp_bar: ProgressBar = %HPBar
@onready var hp_label: Label = %HPLabel
@onready var artifacts_label: Label = %ArtifactsLabel
@onready var objective_label: Label = %ObjectiveLabel
@onready var notification_panel: PanelContainer = %NotificationPanel
@onready var notification_label: Label = %NotificationLabel
@onready var dialog_panel: PanelContainer = %DialogPanel
@onready var speaker_label: Label = %SpeakerLabel
@onready var speaker_portrait: TextureRect = %SpeakerPortrait
@onready var dialog_text: Label = %DialogText
@onready var collectibles_label: Label = %CollectiblesLabel

var notification_tween: Tween
var inventory_node: CanvasLayer = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("hud")
	notification_panel.visible = false
	if dialog_panel:
		dialog_panel.visible = false

	# Connect InventoryManager signals
	if InventoryManager:
		InventoryManager.artifact_collected.connect(_on_artifact_collected)
		InventoryManager.inventory_updated.connect(_update_all_displays)
		InventoryManager.collectible_collected.connect(_on_collectible_collected)

	_update_all_displays()

	# Spawn Inventory as sibling
	var inv_scene = load("res://scenes/ui/Inventory.tscn")
	if inv_scene:
		inventory_node = inv_scene.instantiate()
		get_parent().call_deferred("add_child", inventory_node)

	call_deferred("_connect_player")

func _connect_player() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player:
		setup_player_connections(player)

func setup_player_connections(player: Node) -> void:
	if player and player.has_signal("health_changed"):
		if not player.health_changed.is_connected(_on_player_health_changed):
			player.health_changed.connect(_on_player_health_changed)
		_on_player_health_changed(player.current_health, player.max_health)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("inventory") and not event.is_echo():
		if inventory_node and inventory_node.has_method("toggle"):
			inventory_node.toggle()
			get_viewport().set_input_as_handled()

func _on_player_health_changed(current: int, max_val: int) -> void:
	if hp_bar:
		hp_bar.max_value = max_val
		hp_bar.value = current
	if hp_label:
		hp_label.text = "HP: %d / %d" % [current, max_val]

func _update_all_displays() -> void:
	_update_artifacts_display()
	_update_collectibles_display()

func _update_artifacts_display() -> void:
	if artifacts_label and InventoryManager:
		artifacts_label.text = "ARTIFACTS: %d / 3" % InventoryManager.get_collected_count()

func _update_collectibles_display() -> void:
	if collectibles_label and InventoryManager:
		var leaves = InventoryManager.get_collectible_count("ancient_leaf")
		var shells = InventoryManager.get_collectible_count("lost_shell")
		var stones = InventoryManager.get_collectible_count("stone_fragment")
		collectibles_label.text = "🍃%d  🐚%d  🪨%d" % [leaves, shells, stones]

func set_objective(text: String) -> void:
	if objective_label:
		objective_label.text = "OBJECTIVE:\n%s" % text

func _on_artifact_collected(_artifact_id: String, artifact_name: String) -> void:
	show_notification("✦ ARTIFACT ACQUIRED!\n%s" % artifact_name)
	_update_artifacts_display()

func _on_collectible_collected(collectible_id: String, total_count: int) -> void:
	_update_collectibles_display()
	print("[HUD] Collectible: %s (total: %d)" % [collectible_id, total_count])

func show_notification(text: String) -> void:
	if not notification_label or not notification_panel:
		return
	notification_label.text = text
	notification_panel.visible = true
	notification_panel.modulate.a = 0.0

	if notification_tween and notification_tween.is_valid():
		notification_tween.kill()

	notification_tween = create_tween()
	notification_tween.tween_property(notification_panel, "modulate:a", 1.0, 0.3)
	notification_tween.tween_interval(2.5)
	notification_tween.tween_property(notification_panel, "modulate:a", 0.0, 0.5)
	notification_tween.tween_callback(func(): notification_panel.visible = false)

func show_dialog(speaker: String, text: String, portrait_tex: Texture2D = null) -> void:
	if dialog_panel and speaker_label and dialog_text:
		speaker_label.text = speaker
		dialog_text.text = text
		if speaker_portrait:
			if portrait_tex:
				speaker_portrait.texture = portrait_tex
				speaker_portrait.visible = true
			else:
				speaker_portrait.visible = false
		dialog_panel.visible = true

func hide_dialog() -> void:
	if dialog_panel:
		dialog_panel.visible = false
