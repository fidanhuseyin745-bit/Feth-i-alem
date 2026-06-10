extends Node2D

const Utils = preload("res://scenes/scripts/Utils.gd")

@onready var new_game_btn = $UI/MenuContainer/NewGameBtn
@onready var faction_btn = $UI/MenuContainer/FactionBtn
@onready var history_btn = $UI/MenuContainer/HistoryBtn
@onready var continue_btn = $UI/MenuContainer/ContinueBtn

var has_save: bool = false

func _ready():
	new_game_btn.pressed.connect(_start_new_game)
	faction_btn.pressed.connect(_show_faction_select)
	history_btn.pressed.connect(_show_history)
	continue_btn.pressed.connect(_continue_game)
	
	_style_buttons()
	_check_save_exists()

func _style_buttons():
	Utils.apply_button_style(
		new_game_btn,
		Color(0.9, 0.7, 0.1),
		Color(0.05, 0.03, 0.01)
	)
	var secondary_bg = Color(0.15, 0.12, 0.06)
	var secondary_fg = Color(0.9, 0.78, 0.5)
	var secondary_border = Color(0.9, 0.7, 0.1, 0.5)
	Utils.apply_button_style(faction_btn, secondary_bg, secondary_fg, 10, secondary_border, 1)
	Utils.apply_button_style(history_btn, secondary_bg, secondary_fg, 10, secondary_border, 1)
	Utils.apply_button_style(continue_btn, secondary_bg, secondary_fg, 10, secondary_border, 1)

func _check_save_exists():
	# Kayıtlı oyun kontrolü
	if has_save:
		continue_btn.disabled = false
		continue_btn.modulate = Color(1, 1, 1)
	else:
		continue_btn.disabled = true
		continue_btn.modulate = Color(0.5, 0.5, 0.5)

func _start_new_game():
	# Yeni oyun başlat - 3D sahneye geç
	get_tree().change_scene_to_file("res://scenes/3d/scenes/MainGame3D.tscn")

func _continue_game():
	# Kayıtlı oyunu yükle
	if has_save:
		get_tree().change_scene_to_file("res://scenes/3d/scenes/MainGame3D.tscn")

func _show_faction_select():
	Utils.show_dialog(
		$UI,
		"Fraksiyon Seç",
		"☽ Osmanlı Devleti\n✝ Bizans İmparatorluğu\n⚜ Venedik Cumhuriyeti\n🗡 Karamanoğulları\n⛰ Arnavutluk\n🐴 Akkoyunlular",
		Vector2(500, 400)
	)

func _show_history():
	Utils.show_dialog(
		$UI,
		"Tarihî Notlar",
		"1453 — İstanbul'un Fethi\n\n21 yaşındaki Fatih Sultan Mehmet\n53 günlük kuşatmanın ardından\n29 Mayıs 1453'te İstanbul'u fethetti.\n\n⚔ Birlikler:\nYeniçeri — Seçkin piyade\nSipahi — Atlı savaşçı\nAkıncı — Hafif süvari\nŞahi Top — Surları yıkan top",
		Vector2(500, 500)
	)
