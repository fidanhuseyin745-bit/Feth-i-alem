extends Node2D

const Utils = preload("res://scenes/scripts/Utils.gd")

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
	var required_nodes = {
		"end_turn_btn": end_turn_btn,
		"attack_btn": attack_btn,
		"diplomacy_btn": diplomacy_btn,
		"build_btn": build_btn,
		"gold_label": gold_label,
		"turn_label": turn_label,
		"regions_node": regions_node,
		"region_panel": region_panel,
		"region_name": region_name,
		"region_info": region_info,
	}
	for node_name in required_nodes:
		if not required_nodes[node_name]:
			push_error("WorldMap._ready: required node '%s' not found — check scene tree" % node_name)
			return
	end_turn_btn.pressed.connect(_on_end_turn)
	attack_btn.pressed.connect(_on_attack)
	diplomacy_btn.pressed.connect(_on_diplomacy)
	build_btn.pressed.connect(_on_build)
	_draw_map()
	_update_hud()

func _draw_map():
	if not regions_node:
		push_error("WorldMap._draw_map: regions_node is null")
		return
	for child in regions_node.get_children():
		child.queue_free()
	for region_id in regions:
		var data = regions[region_id]
		var btn = Button.new()
		btn.text = data["name"]
		btn.position = data["position"] - Vector2(55, 25)
		btn.custom_minimum_size = Vector2(110, 50)
		var style = Utils.create_style_box(data["color_owner"], 8, Color(1, 1, 1, 0.5), 2)
		btn.add_theme_stylebox_override("normal", style)
		btn.add_theme_font_size_override("font_size", 12)
		btn.pressed.connect(_on_region_pressed.bind(region_id))
		regions_node.add_child(btn)

func _on_region_pressed(region_id: String):
	if not regions.has(region_id):
		push_error("WorldMap._on_region_pressed: unknown region_id '%s'" % region_id)
		return
	game_state["selected_region"] = region_id
	var data = regions[region_id]
	var owner_key = data["owner"]
	var fname = factions[owner_key]["name"] if factions.has(owner_key) else owner_key
	if not region_name or not region_info:
		push_error("WorldMap._on_region_pressed: region panel labels are null")
		return
	region_name.text = data["name"]
	region_info.text = "Sahip: %s\nAsker: %d\nGelir: %d/tur" % [fname, data["troops"], data["income"]]
	attack_btn.visible = owner_key != "ottoman"
	diplomacy_btn.visible = owner_key != "ottoman"
	build_btn.visible = owner_key == "ottoman"
	region_panel.visible = true

func _get_selected_region() -> String:
	var rid = game_state["selected_region"]
	if rid == "":
		push_warning("WorldMap: no region selected")
		return ""
	if not regions.has(rid):
		push_error("WorldMap: selected region '%s' not found in regions" % rid)
		return ""
	return rid

func _on_attack():
	var rid = _get_selected_region()
	if rid == "": return
	var data = regions[rid]
	if data["owner"] == "ottoman":
		push_warning("WorldMap._on_attack: cannot attack own region '%s'" % rid)
		return
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
	var rid = _get_selected_region()
	if rid == "": return
	if Utils.try_spend_gold(game_state, 500):
		_show_msg("Elçi gönderildi! İlişkiler iyileşti.")
	else:
		_show_msg("Yetersiz altın! (500 gerekli)")
	_update_hud()

func _on_build():
	var rid = _get_selected_region()
	if rid == "": return
	if regions[rid]["owner"] != "ottoman":
		push_warning("WorldMap._on_build: cannot build in non-Ottoman region '%s'" % rid)
		return
	if Utils.try_spend_gold(game_state, 300):
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
		if not factions.has(faction):
			push_warning("WorldMap._on_end_turn: unknown faction '%s' in AI loop" % faction)
			continue
		if randf() < 0.15:
			for rid in regions:
				if regions[rid]["owner"] == "ottoman" and randf() < 0.3:
					var at = 0
					for r in regions.values():
						if r["owner"] == faction: at += r["troops"]
					if at == 0:
						break
					if randf() < float(at) / float(at + regions[rid]["troops"] + 1) * 0.4:
						regions[rid]["owner"] = faction
						regions[rid]["color_owner"] = factions[faction]["color"]
					break
	_update_hud()
	_draw_map()
	region_panel.visible = false
	_show_msg("Tur %d — +%d altın" % [game_state["turn"], income])

func _update_hud():
	if not gold_label or not turn_label:
		push_error("WorldMap._update_hud: HUD label nodes are null")
		return
	gold_label.text = "🪙 %d" % game_state["gold"]
	turn_label.text = "Tur: %d" % game_state["turn"]

func _show_msg(msg: String):
	Utils.show_toast($UI, self, msg)
