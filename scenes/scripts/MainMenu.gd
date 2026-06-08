extends Node2D

const UITheme = preload("res://scenes/scripts/UITheme.gd")

@onready var new_game_btn = $UI/MenuContainer/NewGameBtn
@onready var faction_btn = $UI/MenuContainer/FactionBtn
@onready var history_btn = $UI/MenuContainer/HistoryBtn

func _ready():
	var vp_size = get_viewport_rect().size
	$Background.size = vp_size
	$ParchmentOverlay.size = vp_size
	$Vignette.size = vp_size
	new_game_btn.pressed.connect(_start_game)
	faction_btn.pressed.connect(_show_faction_select)
	history_btn.pressed.connect(_show_history)
	_style_buttons()

func _style_buttons():
	UITheme.style_button(new_game_btn, true)
	new_game_btn.add_theme_font_size_override("font_size", 24)
	UITheme.style_button(faction_btn)
	faction_btn.add_theme_font_size_override("font_size", 20)
	UITheme.style_button(history_btn)
	history_btn.add_theme_font_size_override("font_size", 20)

func _start_game():
	get_tree().change_scene_to_file("res://scenes/GameScreen.tscn")

func _show_faction_select():
	var text = ""
	for fid in GameData.factions:
		var f = GameData.factions[fid]
		text += "%s %s\n  Lider: %s\n  %s\n\n" % [f["symbol"], f["name"], f.get("leader", ""), f.get("description", "")]
	_show_dialog("Fraksiyon Seç", text)

func _show_history():
	_show_dialog(
		"Tarihî Notlar",
		"1453 — İstanbul'un Fethi\n\n21 yaşındaki Fatih Sultan Mehmet\n53 günlük kuşatmanın ardından\n29 Mayıs 1453'te İstanbul'u fethetti.\n\n⚔ Birlikler:\nYeniçeri — Seçkin piyade\nSipahi — Atlı savaşçı\nAkıncı — Hafif süvari\nŞahi Top — Surları yıkan top\nTopçu — Ateşli silahlar birliği"
	)

func _show_dialog(title: String, text: String):
	var dialog = AcceptDialog.new()
	dialog.title = title
	dialog.dialog_text = text
	$UI.add_child(dialog)
	dialog.popup_centered(Vector2(800, 600))
