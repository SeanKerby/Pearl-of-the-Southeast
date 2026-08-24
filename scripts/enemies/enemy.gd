extends CharacterBody2D

## enemy.gd - Overworld enemy that triggers Word Battle on contact (TROPICAL WORD ADVENTURE)

enum State { PATROL, CHASE, IN_BATTLE, DEAD }

@export var max_health: int = 60
@export var move_speed: float = 70.0
@export var patrol_radius: float = 80.0
@export var patrol_speed: float = 45.0
@export var detection_range: float = 140.0

@export var enemy_id: String = "crab"
@export var enemy_name: String = "Forest Crab"
@export var is_boss: bool = false

var current_health: int = 60
var current_state: State = State.PATROL
var patrol_origin: Vector2 = Vector2.ZERO
var patrol_target: Vector2 = Vector2.ZERO
var player_ref: CharacterBody2D = null
var is_defeated: bool = false
var battle_triggered: bool = false

@onready var anim_sprite: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D")
@onready var sprite2d: Sprite2D = get_node_or_null("Sprite2D")
@onready var detection_area: Area2D = get_node_or_null("DetectionArea")
@onready var collision: CollisionShape2D = get_node_or_null("CollisionShape2D")

var visual_node: CanvasItem = null

signal enemy_died()
signal boss_defeated()

func _ready() -> void:
	add_to_group("enemies")
	visual_node = anim_sprite if anim_sprite else sprite2d
	current_health = max_health
	patrol_origin = global_position
	patrol_target = _random_patrol_point()

	if detection_area:
		detection_area.body_entered.connect(_on_player_detected)
		detection_area.body_exited.connect(_on_player_left)

func _physics_process(_delta: float) -> void:
	if current_state == State.DEAD or current_state == State.IN_BATTLE:
		return

	match current_state:
		State.PATROL:
			_do_patrol()
		State.CHASE:
			_do_chase()

	move_and_slide()

func _do_patrol() -> void:
	var dist_to_target = global_position.distance_to(patrol_target)
	if dist_to_target < 8.0:
		patrol_target = _random_patrol_point()

	var direction = (patrol_target - global_position).normalized()
	velocity = direction * patrol_speed
	_play_walk(direction)

func _do_chase() -> void:
	if not is_instance_valid(player_ref):
		current_state = State.PATROL
		return

	var dist = global_position.distance_to(player_ref.global_position)

	if dist > detection_range * 1.5:
		current_state = State.PATROL
		player_ref = null
		return

	# Trigger battle when close enough
	if dist <= 28.0 and not battle_triggered:
		_trigger_word_battle()
		return

	var direction = (player_ref.global_position - global_position).normalized()
	velocity = direction * move_speed
	_play_walk(direction)

func _on_player_detected(body: Node2D) -> void:
	if body.is_in_group("player") and not is_defeated and not battle_triggered:
		player_ref = body
		if current_state != State.DEAD and current_state != State.IN_BATTLE:
			current_state = State.CHASE

func _on_player_left(body: Node2D) -> void:
	if body.is_in_group("player") and current_state == State.CHASE:
		current_state = State.PATROL

# ─── Word Battle Integration ──────────────────────────────────────────────────

func _trigger_word_battle() -> void:
	if battle_triggered or is_defeated:
		return
	battle_triggered = true
	current_state = State.IN_BATTLE
	velocity = Vector2.ZERO

	# Briefly freeze the player too
	if is_instance_valid(player_ref) and player_ref.has_method("set_battle_frozen"):
		player_ref.set_battle_frozen(true)

	print("[Enemy] %s triggers Word Battle!" % enemy_name)

	# Load & instantiate BattleScreen
	var battle_scene: PackedScene = load("res://scenes/battle/BattleScreen.tscn")
	if not battle_scene:
		push_error("[Enemy] BattleScreen.tscn not found!")
		_restore_after_battle(false)
		return

	var battle = battle_scene.instantiate()
	get_tree().root.add_child(battle)

	# Gather player stats from GameManager
	var char_id: String = GameManager.selected_character_id if GameManager else "mangyan"
	var p_hp: int = GameManager.current_health if GameManager else 100
	var p_max_hp: int = GameManager.get_selected_character_data().get("max_health", 100) if GameManager else 100

	battle.setup_battle(char_id, p_hp, p_max_hp, enemy_id, enemy_name, max_health, is_boss, "forest")
	battle.battle_completed.connect(_on_battle_completed)

func _on_battle_completed(victory: bool, _rewards: Dictionary) -> void:
	_restore_after_battle(victory)

func _restore_after_battle(victory: bool) -> void:
	if is_instance_valid(player_ref) and player_ref.has_method("set_battle_frozen"):
		player_ref.set_battle_frozen(false)

	if victory:
		_die()
	else:
		# Player lost, enemy stays; reset so battle can trigger again on next contact
		battle_triggered = false
		current_state = State.PATROL

func _die() -> void:
	is_defeated = true
	current_state = State.DEAD
	velocity = Vector2.ZERO
	enemy_died.emit()
	if is_boss:
		boss_defeated.emit()
	print("[Enemy] %s Defeated." % enemy_name)

	if visual_node:
		var tween = create_tween()
		tween.tween_property(visual_node, "modulate:a", 0.0, 0.5)
		await tween.finished
	queue_free()

# Legacy support: direct damage pathway (unused in word-battle mode, kept for compatibility)
func take_damage(amount: int, _knockback_dir: Vector2 = Vector2.ZERO) -> void:
	if is_defeated or current_state == State.DEAD:
		return
	current_health -= amount
	if current_health <= 0:
		_die()

func _random_patrol_point() -> Vector2:
	var angle = randf() * TAU
	var radius = randf_range(20.0, patrol_radius)
	return patrol_origin + Vector2(cos(angle), sin(angle)) * radius

func _play_walk(dir: Vector2) -> void:
	if not anim_sprite or not anim_sprite.sprite_frames:
		if sprite2d and abs(dir.x) > 0.1:
			sprite2d.flip_h = dir.x < 0
		return
	var anim = "walk"
	if anim_sprite.sprite_frames.has_animation(anim):
		anim_sprite.play(anim)
	elif anim_sprite.sprite_frames.has_animation("idle"):
		anim_sprite.play("idle")
