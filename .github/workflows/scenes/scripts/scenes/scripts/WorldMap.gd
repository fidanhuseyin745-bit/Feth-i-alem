extends Node2D

var game_state = {"turn": 1, "gold": 5000, "selected_region": ""}

var regions = {
	"istanbul": {"name": "İstanbul", "owner": "byzantine", "troops": 3000, "income": 500, "position": Vector2(520, 280), "color_owner": Color(0.3, 0.5, 0.9)},
	"edirne": {"name": "Edirne", "owner": "ottoman", "troops": 5000, "income": 300, "position": Vector2(400, 260), "color_owner": Color(0.9, 0.7, 0.1)},
	"bursa": {"name": "Bursa", "owner": "ottoman", "troops": 2000, "income": 200, "position": Vector2(570, 320), "color_owner": Color(0.9, 0.7, 0.1)},
	"selanik": {"name": "Selanik", "owner": "ottoman", "troops": 1500, "income": 180, "position": Vector2(380, 310), "color_owner": Color(0.9, 0.7, 0.1)},
	"karaman": {"name": "Karaman", "owner": "karamanid", "troops": 2500, "income": 160, "position": Vector2(620, 370), "color_owner": Color(0.2, 0.7, 0.4)},
	"arnavutluk": {"name": "Arnavutluk", "owner": "albania", "troops": 1800, "income": 100, "position": Vector2(310, 330), "color_owner": Color(0.85, 0.2, 0.2)},
	"venedik_adalar": {"name": "Ege Adaları", "owner": "venice", "troops": 1200, "income": 250, "position": Vector2(450, 380), "color_owner": Color(0.6, 0.3, 0.8)},
	"akkoyunlu": {"name": "Akkoyunlu", "owner": "akkoyunlu", "troops": 4000, "income": 200, "position": Vector2(750, 330), "color_owner": Color(0.9, 0.5, 0.1)}
}

var factions = {
	"ottoman": {"name": "Osmanlı", "color": Color(0.9, 0.7, 0.1)},
	"byzantine": {"name": "Bizans", "color": Color(0.3, 0.5, 0.9)},
	"karamanid": {"name": "Karamanoğlu", "color": Color(0.2, 0.7, 0.4)},
	"albania": {"name": "Arnavutluk", "color": Color(0.85, 0.2, 0.2)},
	"venice": {"name": "Venedik", "color": Color(0.6, 0.3, 0.8)},
	"akkoyunlu": {"name": "Akkoyunlu", "color": Color(0.9, 0.5, 0.1)}
}

@onready var gold_label = $UI/HUD/TopBar/TopBarContent/GoldLabel
@onready var turn_label = $UI/HUD/TopBar/TopBarContent/TurnLabel
@onready var end_turn_btn = $UI/HUD/TopBar/TopBarContent/EndTurnBtn
@onready var region_panel = $UI/HUD/RegionPanel
@onready var region_name = $UI/HUD/RegionPanel/RegionContent/RegionName
@onready var region_info = $UI/HUD/RegionPanel/RegionContent/RegionInfo
@onready var attack_btn = $UI/HUD/RegionPanel/RegionContent/ActionButtons/AttackBtn
@onready var diplomacy_btn = $UI/HUD/RegionPanel/RegionContent/ActionButtons/DiplomacyBtn
@onready var build_btn = $UI/HUD/RegionPanel/RegionContent/ActionButtons/BuildBtn
@onready var regions_node = $Regions

func _ready():
	end_turn_btn.pressed.connect(_on_end_turn)
	attack_btn.pressed.connect(_on_attack)
	diplomacy_btn.pressed.connect(_on_diplomacy)
	build_btn.pressed.connect(_on_build)
	_draw_map()
	_update_hud()

func _draw_map():
	for child in regions_node.get_children():
		child.queue_free()
	for region_id in regions:
		var data = regions[region_id]
		var btn = Button.new()
		btn.text = data["name"]
		btn.position = data["position"] - Vector2(55, 25)
		btn.custom_minimum_size = Vector2(110, 50)
		var style = StyleBoxFlat.new()
		style.bg_color = data["color_owner"]
		style.set_corner_radius_all(8)
		style.set_border_width_all(2)
		style.border_color = Color(1, 1, 1, 0.5)
		btn.add_theme_stylebox_override("normal", style)
		btn.add_theme_font_size_override("font_size", 12)
		btn.pressed.connect(_on_region_pressed.bind(region_id))
		regions_node.add_child(btn)

func _on_region_pressed(region_id: String):
	game_state["selected_region"] = region_id
	var data = regions[region_id]
	var fname = factions[data["owner"]]["name"] if factions.has(data["owner"]) else data["owner"]
	region_name.text = data["name"]
	region_info.text = "Sahip: %s\nAsker: %d\nGelir: %d/tur" % [fname, data["troops"], data["income"]]
	attack_btn.visible = data["owner"] != "ottoman"
	diplomacy_btn.visible = data["owner"] != "ottoman"
	build_btn.visible = data["owner"] == "ottoman"
	region_panel.visible = true

func _on_attack():
	var rid = game_state["selected_region"]
	if rid == "": return
	var data = regions[rid]
	var my_t = 0
	for r in regions.values():
		if r["owner"] == "ottoman": my_t += r["troops"]
	var win = float(my_t) / float(my_t + data["troops"] + 1)
	if randf() < win:
		data["owner"] = "ottoman"
		data["color_owner"] = factions["ottoman"]["color"]
		_show_msg("Zafer! %s fethedildi!" % data["name"])
		game_state["gold"] += 200
		if rid == "istanbul":
			_show_msg("☽ İSTANBUL FETHEDİLDİ! BÜYÜK ZAFER! ☽")
	else:
		_show_msg("Yenilgi! Ordular geri çekildi.")
	region_panel.visible = false
	_draw_map()
	_update_hud()

func _on_diplomacy():
	var rid = game_state["selected_region"]
	if rid == "": return
	if game_state["gold"] >= 500:
		game_state["gold"] -= 500
		_show_msg("Elçi gönderildi! İlişkiler iyileşti.")
	else:
		_show_msg("Yetersiz altın! (500 gerekli)")
	_update_hud()

func _on_build():
	var rid = game_state["selected_region"]
	if rid == "": return
	if game_state["gold"] >= 300:
		game_state["gold"] -= 300
		regions[rid]["troops"] += 500
		regions[rid]["income"] += 50
		_show_msg("İnşaat tamam! Asker ve gelir arttı.")
	else:
		_show_msg("Yetersiz altın! (300 gerekli)")
	_update_hud()

func _on_end_turn():
	game_state["turn"] += 1
	var income = 0
	for r in regions.values():
		if r["owner"] == "ottoman": income += r["income"]
	game_state["gold"] += income
	for faction in ["byzantine", "karamanid", "albania", "venice", "akkoyunlu"]:
		if randf() < 0.15:
			for rid in regions:
				if regions[rid]["owner"] == "ottoman" and randf() < 0.3:
					var at = 0
					for r in regions.values():
						if r["owner"] == faction: at += r["troops"]
					if randf() < float(at) / float(at + regions[rid]["troops"] + 1) * 0.4:
						regions[rid]["owner"] = faction
						regions[rid]["color_owner"] = factions[faction]["color"]
					break
	_update_hud()
	_draw_map()
	region_panel.visible = false
	_show_msg("Tur %d — +%d altın" % [game_state["turn"], income])

func _update_hud():
	gold_label.text = "🪙 %d" % game_state["gold"]
	turn_label.text = "Tur: %d" % game_state["turn"]

func _show_msg(msg: String):
	var lbl = Label.new()
	lbl.text = msg
	lbl.add_theme_font_size_override("font_size", 18)
	lbl.add_theme_color_override("font_color", Color(1, 0.9, 0.2))
	lbl.position = Vector2(150, 400)
	$UI.add_child(lbl)
	var tw = create_tween()
	tw.tween_property(lbl, "position:y", 340, 1.5)
	tw.parallel().tween_property(lbl, "modulate:a", 0.0, 1.5)
	tw.tween_callback(lbl.queue_free)
