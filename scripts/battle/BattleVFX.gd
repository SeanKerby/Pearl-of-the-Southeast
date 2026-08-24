extends RefCounted
class_name BattleVFX

## BattleVFX.gd - Visual spell animations, particle effects, and floating combat text

static func play_spell_effect(parent: Node, target_pos: Vector2, element: String = "NONE", is_crit: bool = false) -> void:
	match element:
		"NATURE":
			_spawn_nature_vfx(parent, target_pos, is_crit)
		"WATER":
			_spawn_water_vfx(parent, target_pos, is_crit)
		"FIRE":
			_spawn_fire_vfx(parent, target_pos, is_crit)
		"ANCIENT":
			_spawn_ancient_vfx(parent, target_pos, is_crit)
		"WIND":
			_spawn_wind_vfx(parent, target_pos, is_crit)
		_:
			_spawn_physical_vfx(parent, target_pos, is_crit)

static func show_floating_text(parent: Node, pos: Vector2, text: String, color: Color = Color.WHITE, size: int = 18) -> void:
	var label = Label.new()
	label.text = text
	label.z_index = 100
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.add_theme_font_size_override("font_size", size)
	label.position = pos - Vector2(50, 20)
	parent.add_child(label)

	var tween = label.create_tween().set_parallel(true)
	tween.tween_property(label, "position:y", pos.y - 65.0, 0.75).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "scale", Vector2(1.2, 1.2), 0.15).from(Vector2(0.6, 0.6))
	tween.chain().tween_property(label, "modulate:a", 0.0, 0.35).set_delay(0.3)
	tween.chain().tween_callback(label.queue_free)

static func _spawn_nature_vfx(parent: Node, pos: Vector2, is_crit: bool) -> void:
	for i in range(12 if is_crit else 7):
		var leaf = ColorRect.new()
		leaf.size = Vector2(8, 8)
		leaf.color = Color(0.2, 0.85, 0.3) if i % 2 == 0 else Color(0.4, 0.95, 0.2)
		leaf.position = pos + Vector2(randf_range(-15, 15), randf_range(-15, 15))
		leaf.z_index = 50
		parent.add_child(leaf)

		var angle = randf() * TAU
		var target_offset = Vector2(cos(angle), sin(angle)) * randf_range(40, 90)
		var tween = leaf.create_tween().set_parallel(true)
		tween.tween_property(leaf, "position", leaf.position + target_offset, 0.55).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(leaf, "rotation", randf_range(-3.0, 3.0), 0.55)
		tween.tween_property(leaf, "modulate:a", 0.0, 0.55)
		tween.chain().tween_callback(leaf.queue_free)

static func _spawn_water_vfx(parent: Node, pos: Vector2, is_crit: bool) -> void:
	for i in range(14 if is_crit else 8):
		var drop = ColorRect.new()
		drop.size = Vector2(6, 10)
		drop.color = Color(0.2, 0.65, 0.95) if i % 2 == 0 else Color(0.6, 0.9, 1.0)
		drop.position = pos + Vector2(randf_range(-20, 20), randf_range(10, 30))
		drop.z_index = 50
		parent.add_child(drop)

		var tween = drop.create_tween().set_parallel(true)
		tween.tween_property(drop, "position:y", drop.position.y - randf_range(50, 110), 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(drop, "position:x", drop.position.x + randf_range(-30, 30), 0.45)
		tween.tween_property(drop, "scale", Vector2(1.5, 0.5), 0.45)
		tween.tween_property(drop, "modulate:a", 0.0, 0.45)
		tween.chain().tween_callback(drop.queue_free)

static func _spawn_fire_vfx(parent: Node, pos: Vector2, is_crit: bool) -> void:
	for i in range(16 if is_crit else 9):
		var ember = ColorRect.new()
		ember.size = Vector2(10, 10)
		ember.color = Color(1.0, 0.3, 0.1) if i % 2 == 0 else Color(1.0, 0.8, 0.1)
		ember.position = pos + Vector2(randf_range(-10, 10), randf_range(-10, 10))
		ember.z_index = 50
		parent.add_child(ember)

		var tween = ember.create_tween().set_parallel(true)
		tween.tween_property(ember, "position:y", ember.position.y - randf_range(30, 80), 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(ember, "position:x", ember.position.x + randf_range(-35, 35), 0.5)
		tween.tween_property(ember, "scale", Vector2(0.1, 0.1), 0.5)
		tween.tween_property(ember, "modulate:a", 0.0, 0.5)
		tween.chain().tween_callback(ember.queue_free)

static func _spawn_ancient_vfx(parent: Node, pos: Vector2, is_crit: bool) -> void:
	for i in range(12 if is_crit else 6):
		var rune = ColorRect.new()
		rune.size = Vector2(12, 12)
		rune.color = Color(0.2, 0.9, 1.0) if i % 2 == 0 else Color(0.8, 0.4, 1.0)
		rune.position = pos + Vector2(randf_range(-30, 30), randf_range(-30, 30))
		rune.z_index = 50
		rune.rotation = randf() * TAU
		parent.add_child(rune)

		var tween = rune.create_tween().set_parallel(true)
		tween.tween_property(rune, "scale", Vector2(2.0, 2.0), 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(rune, "rotation", rune.rotation + 3.0, 0.6)
		tween.tween_property(rune, "modulate:a", 0.0, 0.6)
		tween.chain().tween_callback(rune.queue_free)

static func _spawn_wind_vfx(parent: Node, pos: Vector2, is_crit: bool) -> void:
	for i in range(10 if is_crit else 5):
		var blade = ColorRect.new()
		blade.size = Vector2(24, 4)
		blade.color = Color(0.85, 0.95, 1.0, 0.85)
		blade.position = pos + Vector2(randf_range(-40, 40), randf_range(-20, 20))
		blade.z_index = 50
		blade.rotation = randf_range(-0.5, 0.5)
		parent.add_child(blade)

		var tween = blade.create_tween().set_parallel(true)
		tween.tween_property(blade, "position:x", blade.position.x + randf_range(60, 100), 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(blade, "modulate:a", 0.0, 0.35)
		tween.chain().tween_callback(blade.queue_free)

static func _spawn_physical_vfx(parent: Node, pos: Vector2, is_crit: bool) -> void:
	for i in range(8 if is_crit else 4):
		var spark = ColorRect.new()
		spark.size = Vector2(6, 6)
		spark.color = Color(1.0, 1.0, 0.6)
		spark.position = pos
		spark.z_index = 50
		parent.add_child(spark)

		var angle = randf() * TAU
		var target = pos + Vector2(cos(angle), sin(angle)) * randf_range(25, 60)
		var tween = spark.create_tween().set_parallel(true)
		tween.tween_property(spark, "position", target, 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(spark, "modulate:a", 0.0, 0.35)
		tween.chain().tween_callback(spark.queue_free)
