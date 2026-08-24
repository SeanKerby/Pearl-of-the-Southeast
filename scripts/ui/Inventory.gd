extends CanvasLayer

## Inventory.gd - Artifact inventory display for PEARL OF SOUTHEAST

@onready var panel: PanelContainer = %InventoryPanel
@onready var close_btn: Button = %CloseButton
@onready var artifact_count_label: Label = %ArtifactCountLabel

@onready var relic_row: HBoxContainer = %ForestRelicRow
@onready var pearl_row: HBoxContainer = %PearlShellRow
@onready var stone_row: HBoxContainer = %AncientStoneRow

@onready var relic_status: Label = %ForestRelicStatus
@onready var pearl_status: Label = %PearlShellStatus
@onready var stone_status: Label = %AncientStoneStatus

var is_open: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	panel.visible = false
	add_to_group("inventory_ui")

	close_btn.pressed.connect(toggle)

	if InventoryManager:
		InventoryManager.inventory_updated.connect(refresh)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("inventory") and not event.is_echo():
		toggle()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("pause") and not event.is_echo() and is_open:
		toggle()
		get_viewport().set_input_as_handled()

func toggle() -> void:
	is_open = !is_open
	panel.visible = is_open
	if is_open:
		refresh()

func refresh() -> void:
	if not InventoryManager:
		return

	var count = InventoryManager.get_collected_count()
	artifact_count_label.text = "ARTIFACTS FOUND: %d / 3" % count

	_update_row(relic_status, InventoryManager.has_artifact("forest_relic"))
	_update_row(pearl_status, InventoryManager.has_artifact("pearl_shell"))
	_update_row(stone_status, InventoryManager.has_artifact("ancient_stone"))

func _update_row(status_label: Label, collected: bool) -> void:
	if collected:
		status_label.text = "✔ COLLECTED"
		status_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.5, 1))
	else:
		status_label.text = "✘ NOT FOUND"
		status_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6, 1))
