extends Node

## AudioManager.gd - Global audio, procedural sound effects, and tropical synthesizer music

var music_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer

var music_volume_db: float = -6.0
var sfx_volume_db: float = 0.0

var _bgm_generator: AudioStreamGeneratorPlayback = null
var _bgm_thread_active: bool = false
var _sample_rate: float = 22050.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	music_player = AudioStreamPlayer.new()
	music_player.name = "MusicPlayer"
	music_player.bus = "Master"
	music_player.volume_db = music_volume_db
	add_child(music_player)

	sfx_player = AudioStreamPlayer.new()
	sfx_player.name = "SFXPlayer"
	sfx_player.bus = "Master"
	sfx_player.volume_db = sfx_volume_db
	add_child(sfx_player)

	print("[AudioManager] Initialized successfully with Procedural Synthesizer.")
	start_ambient_tropical_music()

func play_music(stream: AudioStream) -> void:
	if stream == null:
		return
	music_player.stop()
	music_player.stream = stream
	music_player.volume_db = music_volume_db
	music_player.play()

func stop_music() -> void:
	music_player.stop()

func play_sfx(stream: AudioStream) -> void:
	if stream == null:
		return
	var p = AudioStreamPlayer.new()
	p.stream = stream
	p.volume_db = sfx_volume_db
	add_child(p)
	p.play()
	p.finished.connect(func(): p.queue_free())

# --- Procedural Sound Effects ---

func play_tile_click() -> void:
	var wav = _create_synth_wav(650.0, 0.04, "sine", 0.8, 1.2)
	play_sfx(wav)

func play_tile_deselect() -> void:
	var wav = _create_synth_wav(380.0, 0.05, "sine", 0.6, 0.7)
	play_sfx(wav)

func play_word_valid() -> void:
	# Uplifting double chime
	var wav = _create_arpeggio_wav([523.25, 659.25, 783.99, 1046.5], 0.06, "triangle")
	play_sfx(wav)

func play_word_invalid() -> void:
	# Low buzz
	var wav = _create_synth_wav(140.0, 0.18, "sawtooth", 0.9, 0.4)
	play_sfx(wav)

func play_attack_spell(element: String = "NONE", is_crit: bool = false) -> void:
	match element:
		"NATURE":
			var wav = _create_arpeggio_wav([330.0, 440.0, 554.37, 659.25, 880.0], 0.07, "sine")
			play_sfx(wav)
		"WATER":
			var wav = _create_arpeggio_wav([440.0, 587.33, 659.25, 880.0, 1174.66], 0.06, "triangle")
			play_sfx(wav)
		"FIRE":
			var wav = _create_noise_burst_wav(0.28, 400.0, 120.0)
			play_sfx(wav)
		"ANCIENT":
			var wav = _create_arpeggio_wav([261.63, 392.0, 523.25, 783.99, 1046.5, 1318.5], 0.08, "sine")
			play_sfx(wav)
		"WIND":
			var wav = _create_noise_burst_wav(0.22, 900.0, 300.0)
			play_sfx(wav)
		_:
			var wav = _create_synth_wav(520.0 if not is_crit else 780.0, 0.15, "square", 0.8, 0.1)
			play_sfx(wav)

func play_enemy_hit() -> void:
	var wav = _create_synth_wav(180.0, 0.14, "square", 0.9, 0.1)
	play_sfx(wav)

func play_player_hurt() -> void:
	var wav = _create_synth_wav(110.0, 0.22, "sawtooth", 1.0, 0.2)
	play_sfx(wav)

func play_combo_up(combo_level: int = 1) -> void:
	var base_freq = 440.0 + (combo_level * 80.0)
	var wav = _create_arpeggio_wav([base_freq, base_freq * 1.25, base_freq * 1.5], 0.07, "triangle")
	play_sfx(wav)

func play_victory_fanfare() -> void:
	var notes = [523.25, 659.25, 783.99, 1046.5, 783.99, 1046.5, 1318.5]
	var wav = _create_arpeggio_wav(notes, 0.12, "triangle")
	play_sfx(wav)

func play_item_use() -> void:
	var wav = _create_arpeggio_wav([600.0, 750.0, 900.0, 1200.0], 0.05, "sine")
	play_sfx(wav)

# --- Procedural Audio Generator Helpers ---

func _create_synth_wav(freq: float, duration: float, wave_type: String = "sine", start_vol: float = 0.8, end_vol: float = 0.0) -> AudioStreamWAV:
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = 22050
	wav.stereo = false
	
	var total_samples: int = int(round(duration * 22050))
	var data: PackedByteArray = PackedByteArray()
	data.resize(total_samples * 2)
	
	for i in range(total_samples):
		var t: float = float(i) / 22050.0
		var env: float = lerp(start_vol, end_vol, float(i) / float(total_samples))
		var sample_val: float = 0.0
		
		match wave_type:
			"sine":
				sample_val = sin(TAU * freq * t)
			"square":
				sample_val = 1.0 if sin(TAU * freq * t) > 0.0 else -1.0
			"triangle":
				sample_val = 2.0 * abs(2.0 * (t * freq - floor(t * freq + 0.5))) - 1.0
			"sawtooth":
				sample_val = 2.0 * (t * freq - floor(t * freq + 0.5))
				
		var final_int: int = int(clamp(sample_val * env * 30000.0, -32767.0, 32767.0))
		data.encode_s16(i * 2, final_int)
		
	wav.data = data
	return wav

func _create_arpeggio_wav(freqs: Array, note_duration: float, wave_type: String = "sine") -> AudioStreamWAV:
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = 22050
	wav.stereo = false
	
	var total_duration: float = note_duration * freqs.size()
	var total_samples: int = int(round(total_duration * 22050))
	var samples_per_note: int = int(round(note_duration * 22050))
	
	var data: PackedByteArray = PackedByteArray()
	data.resize(total_samples * 2)
	
	for i in range(total_samples):
		var note_idx = mini(int(i / samples_per_note), freqs.size() - 1)
		var freq: float = freqs[note_idx]
		var note_local_sample = i % samples_per_note
		var t_local: float = float(note_local_sample) / 22050.0
		var note_env: float = 1.0 - (float(note_local_sample) / float(samples_per_note))
		
		var sample_val: float = 0.0
		match wave_type:
			"sine":
				sample_val = sin(TAU * freq * t_local)
			"triangle":
				sample_val = 2.0 * abs(2.0 * (t_local * freq - floor(t_local * freq + 0.5))) - 1.0
			"square":
				sample_val = 0.8 if sin(TAU * freq * t_local) > 0.0 else -0.8
				
		var final_int: int = int(clamp(sample_val * note_env * 28000.0, -32767.0, 32767.0))
		data.encode_s16(i * 2, final_int)
		
	wav.data = data
	return wav

func _create_noise_burst_wav(duration: float, start_freq: float, end_freq: float) -> AudioStreamWAV:
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = 22050
	wav.stereo = false
	
	var total_samples: int = int(round(duration * 22050))
	var data: PackedByteArray = PackedByteArray()
	data.resize(total_samples * 2)
	
	var phase: float = 0.0
	for i in range(total_samples):
		var progress: float = float(i) / float(total_samples)
		var current_freq = lerp(start_freq, end_freq, progress)
		phase += TAU * current_freq / 22050.0
		var env: float = 1.0 - progress
		var noise: float = randf_range(-0.5, 0.5)
		var sample_val: float = (sin(phase) * 0.6 + noise * 0.4) * env
		
		var final_int: int = int(clamp(sample_val * 28000.0, -32767.0, 32767.0))
		data.encode_s16(i * 2, final_int)
		
	wav.data = data
	return wav

# Ambient Tropical Loop Generator
func start_ambient_tropical_music() -> void:
	# Create a warm 8-second looped musical phrase (pentatonic tropical island melody)
	var melody = [
		523.25, 0.0, 659.25, 783.99, 880.0, 783.99, 659.25, 0.0,
		587.33, 659.25, 783.99, 1046.5, 880.0, 783.99, 659.25, 523.25
	]
	var loop_wav = AudioStreamWAV.new()
	loop_wav.format = AudioStreamWAV.FORMAT_16_BITS
	loop_wav.mix_rate = 22050
	loop_wav.stereo = false
	loop_wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	
	var step_duration: float = 0.35
	var total_samples: int = int(round(step_duration * melody.size() * 22050))
	var samples_per_step: int = int(round(step_duration * 22050))
	
	var data: PackedByteArray = PackedByteArray()
	data.resize(total_samples * 2)
	
	for i in range(total_samples):
		var step_idx = (i / samples_per_step) % melody.size()
		var freq: float = melody[step_idx]
		var local_sample = i % samples_per_step
		var t: float = float(local_sample) / 22050.0
		var env: float = max(0.0, 1.0 - (float(local_sample) / float(samples_per_step))) * 0.35
		
		var val: float = 0.0
		if freq > 0.0:
			val = sin(TAU * freq * t) * env
			# Add gentle warm harmonic
			val += sin(TAU * (freq * 0.5) * t) * (env * 0.4)
			
		var final_int: int = int(clamp(val * 14000.0, -32767.0, 32767.0))
		data.encode_s16(i * 2, final_int)
		
	loop_wav.data = data
	loop_wav.loop_begin = 0
	loop_wav.loop_end = total_samples
	
	music_player.stream = loop_wav
	music_player.volume_db = music_volume_db
	music_player.play()

func set_music_volume(linear_val: float) -> void:
	music_volume_db = linear_to_db(clamp(linear_val, 0.0001, 1.0))
	music_player.volume_db = music_volume_db

func set_sfx_volume(linear_val: float) -> void:
	sfx_volume_db = linear_to_db(clamp(linear_val, 0.0001, 1.0))
