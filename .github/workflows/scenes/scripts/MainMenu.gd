extends Node2D

@onready var new_game_btn = $UI/MenuContainer/NewGameBtn
@onready var faction_btn = $UI/MenuContainer/FactionBtn
@onready var history_btn = $UI/MenuContainer/HistoryBtn

func _ready():
	if not new_game_btn or not faction_btn or not history_btn:
		push_error("MainMenu: one or more menu buttons not found — check scene tree")
		return
	new_game_btn.pressed.connect(_start_game)
	faction_btn.pressed.connect(_show_faction_select)
	history_btn.pressed.connect(_show_history)
	_style_buttons()

func _style_buttons():
	if not new_game_btn or not faction_btn or not history_btn:
		push_error("MainMenu._style_buttons: button nodes are null, skipping styling")
		return
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.9, 0.7, 0.1)
	style.set_corner_radius_all(10)
	new_game_btn.add_theme_stylebox_override("normal", style)
	new_game_btn.add_theme_color_override("font_color", Color(0.05, 0.03, 0.01))
	var style2 = StyleBoxFlat.new()
	style2.bg_color = Color(0.15, 0.12, 0.06)
	style2.border_color = Color(0.9, 0.7, 0.1, 0.5)
	style2.set_border_width_all(1)
	style2.set_corner_radius_all(10)
	faction_btn.add_theme_stylebox_override("normal", style2)
	history_btn.add_theme_stylebox_override("normal", style2)
	faction_btn.add_theme_color_override("font_color", Color(0.9, 0.78, 0.5))
	history_btn.add_theme_color_override("font_color", Color(0.9, 0.78, 0.5))

func _start_game():
	var scene_path = "res://scenes/WorldMap.tscn"
	if not ResourceLoader.exists(scene_path):
		push_error("MainMenu._start_game: scene not found at '%s'" % scene_path)
		return
	var err = get_tree().change_scene_to_file(scene_path)
	if err != OK:
		push_error("MainMenu._start_game: failed to change scene (error %d)" % err)

func _show_faction_select():
	var ui = get_node_or_null("UI")
	if not ui:
		push_error("MainMenu._show_faction_select: UI node not found")
		return
	var dialog = AcceptDialog.new()
	dialog.title = "Fraksiyon Seç"
	dialog.dialog_text = "☽ Osmanlı Devleti\n✝ Bizans İmparatorluğu\n⚜ Venedik Cumhuriyeti\n🗡 Karamanoğulları\n⛰ Arnavutluk\n🐴 Akkoyunlular"
	ui.add_child(dialog)
	dialog.popup_centered(Vector2(500, 400))

func _show_history():
	var ui = get_node_or_null("UI")
	if not ui:
		push_error("MainMenu._show_history: UI node not found")
		return
	var dialog = AcceptDialog.new()
	dialog.title = "Tarihî Notlar"
	dialog.dialog_text = "1453 — İstanbul'un Fethi\n\n21 yaşındaki Fatih Sultan Mehmet\n53 günlük kuşatmanın ardından\n29 Mayıs 1453'te İstanbul'u fethetti.\n\n⚔ Birlikler:\nYeniçeri — Seçkin piyade\nSipahi — Atlı savaşçı\nAkıncı — Hafif süvari\nŞahi Top — Surları yıkan top"
	ui.add_child(dialog)
	dialog.popup_centered(Vector2(500, 500))
