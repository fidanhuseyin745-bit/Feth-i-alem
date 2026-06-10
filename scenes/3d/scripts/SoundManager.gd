extends Node
class_name SoundManager

## Ses yönetim sistemi - SFX ve müzik

signal music_changed(track: String)
signal sfx_played(sound: String)

var master_volume: float = 1.0
var music_volume: float = 0.7
var sfx_volume: float = 0.8

var current_music: String = ""
var is_music_playing: bool = false

var music_player: AudioStreamPlayer
var sfx_players: Array = []
var max_sfx_players: int = 8

# Ses dosyaları (placeholder - gerçek dosyalar eklenecek)
var sfx_library: Dictionary = {
	# Savaş sesleri
	"sword_hit": "res://assets/sounds/sword_hit.wav",
	"arrow_fire": "res://assets/sounds/arrow_fire.wav",
	"shield_block": "res://assets/sounds/shield_block.wav",
	"battle_cry": "res://assets/sounds/battle_cry.wav",
	"horse_gallop": "res://assets/sounds/horse_gallop.wav",
	"death": "res://assets/sounds/death.wav",
	
	# UI sesleri
	"click": "res://assets/sounds/click.wav",
	"select": "res://assets/sounds/select.wav",
	"error": "res://assets/sounds/error.wav",
	"success": "res://assets/sounds/success.wav",
	"notification": "res://assets/sounds/notification.wav",
	
	# Çevre sesleri
	"wind": "res://assets/sounds/wind.wav",
	"birds": "res://assets/sounds/birds.wav",
	"water": "res://assets/sounds/water.wav",
	"campfire": "res://assets/sounds/campfire.wav",
	
	# Şehir sesleri
	"city_captured": "res://assets/sounds/city_captured.wav",
	"siege_start": "res://assets/sounds/siege_start.wav",
	"horn": "res://assets/sounds/horn.wav",
	"march": "res://assets/sounds/march.wav",
	
	# Ticaret
	"coin": "res://assets/sounds/coin.wav",
	"market": "res://assets/sounds/market.wav"
}

var music_library: Dictionary = {
	"menu": "res://assets/music/menu_theme.wav",
	"battle": "res://assets/music/battle_theme.wav",
	"peace": "res://assets/music/peace_theme.wav",
	"exploration": "res://assets/music/exploration_theme.wav",
	"victory": "res://assets/music/victory_theme.wav",
	"defeat": "res://assets/music/defeat_theme.wav",
	"city": "res://assets/music/city_theme.wav"
}

func _ready():
	_setup_audio_players()

func _setup_audio_players():
	# Müzik çalar
	music_player = AudioStreamPlayer.new()
	music_player.volume_db = linear_to_db(music_volume)
	add_child(music_player)
	
	# SFX çalarlar
	for i in max_sfx_players:
		var player = AudioStreamPlayer.new()
		player.volume_db = linear_to_db(sfx_volume)
		sfx_players.append(player)
		add_child(player)

func play_music(track: String, fade: bool = true):
	if not music_library.has(track):
		return
	
	# Aynı müzik çalıyorsa devam et
	if current_music == track and is_music_playing:
		return
	
	if fade and is_music_playing:
		_fade_out_music(0.5)
		await get_tree().create_timer(0.5).timeout
	
	# Müziği yükle ve çal
	var stream = load(music_library[track])
	if stream:
		music_player.stream = stream
		music_player.volume_db = linear_to_db(music_volume)
		music_player.play()
		current_music = track
		is_music_playing = true
		music_changed.emit(track)

func stop_music(fade: bool = true):
	if fade:
		_fade_out_music(1.0)
		await get_tree().create_timer(1.0).timeout
	
	music_player.stop()
	is_music_playing = false
	current_music = ""

func _fade_out_music(duration: float):
	var tween = create_tween()
	tween.tween_property(music_player, "volume_db", -80, duration)

func play_sfx(sound: String, volume_modifier: float = 1.0):
	if not sfx_library.has(sound):
		return
	
	# Boş bir SFX çalar bul
	var player = _get_available_sfx_player()
	if not player:
		return
	
	var stream = load(sfx_library[sound])
	if stream:
		player.stream = stream
		player.volume_db = linear_to_db(sfx_volume * volume_modifier)
		player.play()
		sfx_played.emit(sound)

func _get_available_sfx_player() -> AudioStreamPlayer:
	for player in sfx_players:
		if not player.playing:
			return player
	# Tüm çalarlar meşgulse ilkini kullan
	return sfx_players[0]

func set_master_volume(volume: float):
	master_volume = clamp(volume, 0, 1)
	_update_volumes()

func set_music_volume(volume: float):
	music_volume = clamp(volume, 0, 1)
	if music_player:
		music_player.volume_db = linear_to_db(music_volume * master_volume)

func set_sfx_volume(volume: float):
	sfx_volume = clamp(volume, 0, 1)
	for player in sfx_players:
		player.volume_db = linear_to_db(sfx_volume * master_volume)

func _update_volumes():
	if music_player:
		music_player.volume_db = linear_to_db(music_volume * master_volume)
	for player in sfx_players:
		player.volume_db = linear_to_db(sfx_volume * master_volume)

# ── Özel Ses Efektleri ─────────────────────────────────────────────────────

func play_battle_sfx():
	play_sfx("battle_cry")
	play_sfx("sword_hit", 0.7)

func play_attack_sfx():
	var attacks = ["sword_hit", "arrow_fire"]
	play_sfx(attacks[randi() % attacks.size()])

func play_ui_sfx(sfx_type: String):
	match sfx_type:
		"click":
			play_sfx("click")
		"select":
			play_sfx("select")
		"error":
			play_sfx("error")
		"success":
			play_sfx("success")
		"notification":
			play_sfx("notification")

func play_city_captured_sfx():
	play_sfx("city_captured")
	play_sfx("horn", 1.2)

func play_siege_sfx():
	play_sfx("siege_start")
	play_sfx("horn", 0.8)

func play_coin_sfx():
	play_sfx("coin")

func play_march_sfx():
	play_sfx("march")

# ── Ses Kategorileri ────────────────────────────────────────────────────────

func play_ambient_sound(sound: String, loop: bool = true):
	# Ortam sesleri (rüzgar, kuş, su)
	pass

func stop_ambient_sounds():
	# Tüm ortam seslerini durdur
	pass

# ── Prosedürel Sesler (Placeholder) ────────────────────────────────────────

func play_procedural_step():
	# Adım sesi (placeholder)
	pass

func play_procedural_hit():
	# Darbe sesi (placeholder)
	pass

func play_procedural_death():
	# Ölüm sesi (placeholder)
	pass

# ── Kayıt / Yükleme ────────────────────────────────────────────────────────

func save_settings() -> Dictionary:
	return {
		"master_volume": master_volume,
		"music_volume": music_volume,
		"sfx_volume": sfx_volume
	}

func load_settings(data: Dictionary):
	master_volume = data.get("master_volume", 1.0)
	music_volume = data.get("music_volume", 0.7)
	sfx_volume = data.get("sfx_volume", 0.8)
	_update_volumes()