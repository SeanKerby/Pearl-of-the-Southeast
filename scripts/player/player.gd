extends CharacterBody2D
class_name Player

## player.gd - Core player controller for PEARL OF SOUTHEAST

enum State { IDLE, WALK, ATTACK, HURT, DEAD }

@export var character_id: String = "mangyan"

# Dynamic stats from GameManager
var max_health: int = 100
var current_health: int = 100
var move_speed: float = 150.0
var attack_damage: int = 20
var special_ability: String = ""

# State & Direction
var current_state: State = State.IDLE
var facing_direction: Vector2 = Vector2.DOWN
var facing_name: String = "down"
var is_attacking: bool = false
var is_invulnerable: bool = false

# Cooldowns & Timers
var attack_cooldown: float = 0.35
var attack_timer: float = 0.0
var hurt_timer: float = 0.0
var invulnerability_duration: float = 0.6

# Nodes
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var attack_area: Area2D = $AttackArea
@onready var attack_collision: CollisionShape2D = $AttackArea/CollisionShape2D
@onready var interaction_area: Area2D = $InteractionArea
@onready var camera: Camera2D = $Camera2D

# Signals
signal health_changed(current: int, max_val: int)
signal player_died()

func _ready() -> void:
	add_to_group("player")
	_initialize_character()
	_update_attack_area_offset()
	if attack_collision:
		attack_collision.disabled = true

func _initialize_character() -> void:
	if GameManager:
		character_id = GameManager.selected_character_id
		var data = GameManager.get_selected_character_data()
		max_health = data.get("max_health", 100)
		current_health = GameManager.current_health if GameManager.current_health > 0 else max_health
		move_speed = data.get("speed", 150.0)
		attack_damage = data.get("attack_damage", 20)
		special_ability = data.get("special_ability", "")
	else:
		current_health = max_health

	_build_sprite_frames(character_id)
	health_changed.emit(current_health, max_health)
	_play_animation("idle")

func _build_sprite_frames(char_id: String) -> void:
	var base_path: String = "res://characters/%s/" % char_id
	if not DirAccess.dir_exists_absolute("res://characters/" + char_id) and DirAccess.dir_exists_absolute("res://assets/characters/" + char_id):
		base_path = "res://assets/characters/%s/" % char_id

	var frames: SpriteFrames = SpriteFrames.new()

	var actions = ["idle", "walk", "attack", "hurt", "death"]
	var directions = ["down", "up", "left", "right"]

	for act in actions:
		for dir in directions:
			var anim_name = "%s_%s" % [act, dir]
			var file_path = "%s%s_%s.png" % [base_path, act, dir]
			if not ResourceLoader.exists(file_path):
				file_path = "res://assets/characters/%s/%s_%s.png" % [char_id, act, dir]
			
			if ResourceLoader.exists(file_path):
				var tex: Texture2D = load(file_path)
				frames.add_animation(anim_name)
				frames.set_animation_speed(anim_name, 6.0 if act == "walk" else 5.0)
				frames.set_animation_loop(anim_name, act in ["idle", "walk"])
				frames.add_frame(anim_name, tex)

	# Global death animation alias
	if frames.has_animation("death_down"):
		frames.add_animation("death")
		var death_tex = load("%sdeath_down.png" % base_path)
		if death_tex:
			frames.add_frame("death", death_tex)

	animated_sprite.sprite_frames = frames

func _physics_process(delta: float) -> void:
	if current_state == State.DEAD:
		return
	if is_battle_frozen:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	# Handle cooldown timers
	if attack_timer > 0:
		attack_timer -= delta
		if attack_timer <= 0:
			_end_attack()

	if hurt_timer > 0:
		hurt_timer -= delta
		if hurt_timer <= 0:
			is_invulnerable = false
			if current_state == State.HURT:
				current_state = State.IDLE

	# 1. Direct Movement Input (WASD, Arrow keys, UI actions, Joypad)
	var dir := Vector2.ZERO
	if Input.is_action_pressed("move_left") or Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		dir.x -= 1.0
	if Input.is_action_pressed("move_right") or Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		dir.x += 1.0
	if Input.is_action_pressed("move_up") or Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		dir.y -= 1.0
	if Input.is_action_pressed("move_down") or Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		dir.y += 1.0

	if dir != Vector2.ZERO:
		velocity = dir.normalized() * move_speed
		_update_facing(dir)
		if not is_attacking and current_state != State.HURT:
			current_state = State.WALK
			_play_animation("walk")
	else:
		velocity = Vector2.ZERO
		if not is_attacking and current_state != State.HURT:
			current_state = State.IDLE
			_play_animation("idle")

	# 2. Attack Input (Space, J, or attack action)
	if (InputMap.has_action("attack") and Input.is_action_just_pressed("attack")) or Input.is_action_just_pressed("ui_accept"):
		if attack_timer <= 0 and current_state != State.HURT and not is_attacking:
			_perform_attack()

	# 3. Interact Input (E key or interact action)
	if InputMap.has_action("interact") and Input.is_action_just_pressed("interact"):
		if current_state != State.ATTACK:
			_check_interaction()

	move_and_slide()

var is_battle_frozen: bool = false

func set_battle_frozen(frozen: bool) -> void:
	is_battle_frozen = frozen
	if frozen:
		velocity = Vector2.ZERO

func _unhandled_input(event: InputEvent) -> void:
	if is_battle_frozen:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_E or event.physical_keycode == KEY_E:
			if current_state != State.ATTACK:
				_check_interaction()
				get_viewport().set_input_as_handled()

func _update_facing(dir: Vector2) -> void:
	if abs(dir.x) > abs(dir.y):
		if dir.x > 0:
			facing_direction = Vector2.RIGHT
			facing_name = "right"
		else:
			facing_direction = Vector2.LEFT
			facing_name = "left"
	else:
		if dir.y > 0:
			facing_direction = Vector2.DOWN
			facing_name = "down"
		else:
			facing_direction = Vector2.UP
			facing_name = "up"

	_update_attack_area_offset()

func _update_attack_area_offset() -> void:
	if attack_area:
		attack_area.position = facing_direction * 24.0

func _perform_attack() -> void:
	is_attacking = true
	current_state = State.ATTACK
	velocity = Vector2.ZERO
	attack_timer = attack_cooldown
	_play_animation("attack")

	if attack_collision:
		attack_collision.disabled = false

	# Detect damage to enemies
	var overlapping_areas = attack_area.get_overlapping_areas()
	for area in overlapping_areas:
		if area.is_in_group("enemy_hurtbox") or area.get_parent().is_in_group("enemies"):
			var target = area.get_parent() if area.is_in_group("enemy_hurtbox") else area
			if target.has_method("take_damage"):
				target.take_damage(attack_damage, facing_direction)

	var overlapping_bodies = attack_area.get_overlapping_bodies()
	for body in overlapping_bodies:
		if body.is_in_group("enemies") and body.has_method("take_damage"):
			body.take_damage(attack_damage, facing_direction)

func _end_attack() -> void:
	is_attacking = false
	if attack_collision:
		attack_collision.disabled = true
	current_state = State.IDLE
	_play_animation("idle")

func _check_interaction() -> void:
	var overlapping_areas = interaction_area.get_overlapping_areas()
	for area in overlapping_areas:
		if area.is_in_group("interactable") or area.has_method("interact"):
			area.interact(self)
			return

	var overlapping_bodies = interaction_area.get_overlapping_bodies()
	for body in overlapping_bodies:
		if body.is_in_group("interactable") or body.has_method("interact"):
			body.interact(self)
			return

func take_damage(amount: int, knockback_dir: Vector2 = Vector2.ZERO) -> void:
	if is_invulnerable or current_state == State.DEAD:
		return

	# Igorot special resistance
	if character_id == "igorot":
		amount = int(round(amount * 0.8))

	current_health = max(0, current_health - amount)
	GameManager.current_health = current_health
	health_changed.emit(current_health, max_health)

	is_invulnerable = true
	hurt_timer = invulnerability_duration
	current_state = State.HURT

	if knockback_dir != Vector2.ZERO:
		velocity = knockback_dir.normalized() * 180.0

	_play_animation("hurt")

	# Flash effect
	var tween = create_tween()
	tween.tween_property(animated_sprite, "modulate", Color(1, 0.3, 0.3, 0.7), 0.1)
	tween.tween_property(animated_sprite, "modulate", Color(1, 1, 1, 1), 0.1)

	if current_health <= 0:
		_die()

func _die() -> void:
	current_state = State.DEAD
	velocity = Vector2.ZERO
	_play_animation("death")
	player_died.emit()
	print("[Player] Defeated.")
	await get_tree().create_timer(1.2).timeout
	GameManager.trigger_game_over()

func _play_animation(action: String) -> void:
	if animated_sprite and animated_sprite.sprite_frames:
		var anim = "%s_%s" % [action, facing_name]
		if animated_sprite.sprite_frames.has_animation(anim):
			animated_sprite.play(anim)
		elif animated_sprite.sprite_frames.has_animation(action):
			animated_sprite.play(action)
