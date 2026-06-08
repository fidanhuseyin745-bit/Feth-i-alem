extends Node
## Global game data autoload — Bannerlord-style game state manager.
## Manages settlements, armies, factions, diplomacy, economy, and character.

signal turn_ended(turn: int, income: int)
signal settlement_conquered(sid: String, sname: String)
signal settlement_lost(sid: String, faction: String)
signal battle_result(won: bool, details: Dictionary)
signal message(text: String)
signal gold_changed(new_gold: int)

# ── Time / Turn ─────────────────────────────────────────────────────────
var turn: int = 1
var gold: int = 5000
var time_speed: int = 1  # 0=paused, 1=normal, 2=fast, 4=vfast

# ── Player ──────────────────────────────────────────────────────────────
var player_faction: String = "ottoman"
var player_name: String = "Fatih Sultan Mehmet"
var player_stats: Dictionary = {
	"leadership": 5,
	"warfare": 6,
	"diplomacy": 3,
	"economy": 4,
}
var player_perks: Array = []

# ── Factions ────────────────────────────────────────────────────────────
var factions: Dictionary = {}

# ── Settlements ─────────────────────────────────────────────────────────
var settlements: Dictionary = {}

# ── Troop definitions ───────────────────────────────────────────────────
var troop_defs: Dictionary = {}

# ── Army (player's party) ──────────────────────────────────────────────
var army: Array = []  # [{troop_id, count}]
var army_max: int = 200
var army_morale: int = 75

# ── Diplomacy ───────────────────────────────────────────────────────────
var relations: Dictionary = {}  # faction_id -> int (-100..100)

# ── Buildings ───────────────────────────────────────────────────────────
var building_defs: Dictionary = {}

# ════════════════════════════════════════════════════════════════════════
#                           INITIALIZATION
# ════════════════════════════════════════════════════════════════════════

func _ready():
	_init_factions()
	_init_troop_defs()
	_init_building_defs()
	_init_settlements()
	_init_army()
	_init_relations()

func _init_factions():
	factions = {
		"ottoman": {
			"name": "Osmanlı Devleti", "color": Color(0.9, 0.7, 0.1),
			"symbol": "☽", "leader": "Sultan II. Mehmed",
			"description": "Anadolu ve Balkanlar'da yükselen güçlü Türk devleti."
		},
		"byzantine": {
			"name": "Bizans İmparatorluğu", "color": Color(0.3, 0.5, 0.9),
			"symbol": "✝", "leader": "XI. Konstantinos",
			"description": "Yüzyıllarca hüküm süren Roma'nın doğu varisi."
		},
		"karamanid": {
			"name": "Karamanoğulları", "color": Color(0.2, 0.7, 0.4),
			"symbol": "⚔", "leader": "İbrahim Bey",
			"description": "Anadolu'daki en güçlü Türkmen beyliği."
		},
		"albania": {
			"name": "Arnavutluk", "color": Color(0.85, 0.2, 0.2),
			"symbol": "⛰", "leader": "İskender Bey",
			"description": "Dağlık arazide direnen savaşçı halk."
		},
		"venice": {
			"name": "Venedik Cumhuriyeti", "color": Color(0.6, 0.3, 0.8),
			"symbol": "⚜", "leader": "Doge Francesco Foscari",
			"description": "Akdeniz'in en güçlü deniz ticaret devleti."
		},
		"akkoyunlu": {
			"name": "Akkoyunlu Devleti", "color": Color(0.9, 0.5, 0.1),
			"symbol": "🐴", "leader": "Uzun Hasan",
			"description": "Doğu Anadolu ve İran'daki Türkmen konfederasyonu."
		},
	}

func _init_troop_defs():
	troop_defs = {
		# Ottoman infantry line
		"acemi_oglan": {"name": "Acemi Oğlan", "tier": 1, "faction": "ottoman",
			"type": "infantry", "attack": 4, "defense": 3, "cost": 10,
			"upgrade_to": "yaya_askeri", "upgrade_cost": 30},
		"yaya_askeri": {"name": "Yaya Askeri", "tier": 2, "faction": "ottoman",
			"type": "infantry", "attack": 7, "defense": 6, "cost": 18,
			"upgrade_to": "kapikulu_piyade", "upgrade_cost": 60},
		"kapikulu_piyade": {"name": "Kapıkulu Piyade", "tier": 3, "faction": "ottoman",
			"type": "infantry", "attack": 12, "defense": 10, "cost": 30,
			"upgrade_to": "yeniceri", "upgrade_cost": 100},
		"yeniceri": {"name": "Yeniçeri", "tier": 4, "faction": "ottoman",
			"type": "infantry", "attack": 18, "defense": 15, "cost": 50,
			"upgrade_to": "", "upgrade_cost": 0},
		# Ottoman cavalry line
		"sipahi_adayi": {"name": "Sipahi Adayı", "tier": 1, "faction": "ottoman",
			"type": "cavalry", "attack": 5, "defense": 3, "cost": 15,
			"upgrade_to": "timarli_sipahi", "upgrade_cost": 40},
		"timarli_sipahi": {"name": "Tımarlı Sipahi", "tier": 2, "faction": "ottoman",
			"type": "cavalry", "attack": 10, "defense": 7, "cost": 25,
			"upgrade_to": "kapikulu_sipahi", "upgrade_cost": 80},
		"kapikulu_sipahi": {"name": "Kapıkulu Sipahi", "tier": 3, "faction": "ottoman",
			"type": "cavalry", "attack": 16, "defense": 12, "cost": 40,
			"upgrade_to": "sipahi_agasi", "upgrade_cost": 120},
		"sipahi_agasi": {"name": "Sipahi Ağası", "tier": 4, "faction": "ottoman",
			"type": "cavalry", "attack": 22, "defense": 16, "cost": 60,
			"upgrade_to": "", "upgrade_cost": 0},
		# Ottoman ranged line
		"okcu_acemi": {"name": "Okçu Acemi", "tier": 1, "faction": "ottoman",
			"type": "ranged", "attack": 5, "defense": 2, "cost": 12,
			"upgrade_to": "okcu", "upgrade_cost": 35},
		"okcu": {"name": "Okçu", "tier": 2, "faction": "ottoman",
			"type": "ranged", "attack": 9, "defense": 4, "cost": 22,
			"upgrade_to": "yeniceri_okcusu", "upgrade_cost": 70},
		"yeniceri_okcusu": {"name": "Yeniçeri Okçusu", "tier": 3, "faction": "ottoman",
			"type": "ranged", "attack": 15, "defense": 8, "cost": 38,
			"upgrade_to": "", "upgrade_cost": 0},
		# Ottoman special units
		"akinci": {"name": "Akıncı", "tier": 2, "faction": "ottoman",
			"type": "cavalry", "attack": 8, "defense": 4, "cost": 20,
			"upgrade_to": "deli", "upgrade_cost": 50},
		"deli": {"name": "Deli", "tier": 3, "faction": "ottoman",
			"type": "cavalry", "attack": 14, "defense": 6, "cost": 35,
			"upgrade_to": "", "upgrade_cost": 0},
		"topcu": {"name": "Topçu", "tier": 3, "faction": "ottoman",
			"type": "siege", "attack": 20, "defense": 3, "cost": 45,
			"upgrade_to": "sahi_topcusu", "upgrade_cost": 150},
		"sahi_topcusu": {"name": "Şahi Topçusu", "tier": 4, "faction": "ottoman",
			"type": "siege", "attack": 30, "defense": 5, "cost": 80,
			"upgrade_to": "", "upgrade_cost": 0},
		# Generic faction troops
		"byzantine_soldier": {"name": "Bizans Askeri", "tier": 2, "faction": "byzantine",
			"type": "infantry", "attack": 8, "defense": 9, "cost": 20,
			"upgrade_to": "", "upgrade_cost": 0},
		"varangian_guard": {"name": "Varangian Muhafızı", "tier": 4, "faction": "byzantine",
			"type": "infantry", "attack": 17, "defense": 18, "cost": 55,
			"upgrade_to": "", "upgrade_cost": 0},
		"karamanid_warrior": {"name": "Karaman Savaşçısı", "tier": 2, "faction": "karamanid",
			"type": "infantry", "attack": 8, "defense": 6, "cost": 18,
			"upgrade_to": "", "upgrade_cost": 0},
		"albanian_fighter": {"name": "Arnavut Savaşçısı", "tier": 2, "faction": "albania",
			"type": "infantry", "attack": 9, "defense": 5, "cost": 17,
			"upgrade_to": "", "upgrade_cost": 0},
		"venetian_crossbow": {"name": "Venedik Tatar Yayı", "tier": 3, "faction": "venice",
			"type": "ranged", "attack": 14, "defense": 7, "cost": 35,
			"upgrade_to": "", "upgrade_cost": 0},
		"akkoyunlu_horseman": {"name": "Akkoyunlu Atlısı", "tier": 2, "faction": "akkoyunlu",
			"type": "cavalry", "attack": 10, "defense": 5, "cost": 22,
			"upgrade_to": "", "upgrade_cost": 0},
	}

func _init_building_defs():
	building_defs = {
		"walls": {"name": "Kale Surları", "cost": 800, "turns": 3,
			"effect": {"defense_bonus": 30}, "icon": "🏰",
			"desc": "Yerleşimi kuşatmaya karşı güçlendirir."},
		"market": {"name": "Pazar", "cost": 500, "turns": 2,
			"effect": {"income_bonus": 100}, "icon": "🏪",
			"desc": "Ticaret gelirini artırır."},
		"training": {"name": "Eğitim Sahası", "cost": 600, "turns": 2,
			"effect": {"max_tier": 3, "train_speed": 1.5}, "icon": "⚔",
			"desc": "Daha yüksek kademeli asker eğitimi sağlar."},
		"watchtower": {"name": "Gözetleme Kulesi", "cost": 300, "turns": 1,
			"effect": {"vision_range": 2}, "icon": "🗼",
			"desc": "Çevre bölgeleri gözetler, sürpriz saldırıları önler."},
		"mosque": {"name": "Cami", "cost": 400, "turns": 2,
			"effect": {"morale_bonus": 10, "loyalty_bonus": 15}, "icon": "🕌",
			"desc": "Halkın moralini ve sadakatini artırır."},
		"shipyard": {"name": "Tersane", "cost": 1000, "turns": 4,
			"effect": {"naval": true}, "icon": "⚓",
			"desc": "Donanma inşa etmeyi sağlar. Sadece kıyı yerleşimlerinde."},
	}

func _init_settlements():
	settlements = {
		# === CITIES ===
		"istanbul": {
			"name": "İstanbul", "type": "city", "owner": "byzantine",
			"position": Vector2(445, 814),
			"garrison": [{"troop_id": "byzantine_soldier", "count": 80}, {"troop_id": "varangian_guard", "count": 20}],
			"buildings": ["walls"],
			"income": 500, "population": 50000, "loyalty": 90, "prosperity": 80,
			"coastal": true,
			"desc": "Dünyanın en büyük ve en zengin şehri. Fethin anahtarı."
		},
		"edirne": {
			"name": "Edirne", "type": "city", "owner": "ottoman",
			"position": Vector2(355, 686),
			"garrison": [{"troop_id": "yeniceri", "count": 40}, {"troop_id": "kapikulu_piyade", "count": 60}],
			"buildings": ["walls", "market", "training", "mosque"],
			"income": 300, "population": 25000, "loyalty": 95, "prosperity": 70,
			"coastal": false,
			"desc": "Osmanlı başkenti. Saray ve ordunun merkezi."
		},
		"bursa": {
			"name": "Bursa", "type": "city", "owner": "ottoman",
			"position": Vector2(449, 973),
			"garrison": [{"troop_id": "yaya_askeri", "count": 50}, {"troop_id": "okcu", "count": 30}],
			"buildings": ["market", "mosque"],
			"income": 200, "population": 18000, "loyalty": 90, "prosperity": 65,
			"coastal": false,
			"desc": "İlk Osmanlı başkenti. İpek ticaretinin merkezi."
		},
		"selanik": {
			"name": "Selanik", "type": "city", "owner": "ottoman",
			"position": Vector2(221, 887),
			"garrison": [{"troop_id": "yaya_askeri", "count": 40}, {"troop_id": "akinci", "count": 20}],
			"buildings": ["market"],
			"income": 180, "population": 15000, "loyalty": 75, "prosperity": 55,
			"coastal": true,
			"desc": "Ege kıyısında stratejik liman şehri."
		},
		"konya": {
			"name": "Konya", "type": "city", "owner": "karamanid",
			"position": Vector2(604, 1200),
			"garrison": [{"troop_id": "karamanid_warrior", "count": 70}],
			"buildings": ["walls", "mosque"],
			"income": 160, "population": 12000, "loyalty": 85, "prosperity": 50,
			"coastal": false,
			"desc": "Karamanoğulları başkenti. Selçuklu mirası."
		},
		"trabzon": {
			"name": "Trabzon", "type": "city", "owner": "byzantine",
			"position": Vector2(920, 750),
			"garrison": [{"troop_id": "byzantine_soldier", "count": 30}],
			"buildings": ["walls"],
			"income": 120, "population": 8000, "loyalty": 80, "prosperity": 45,
			"coastal": true,
			"desc": "Karadeniz kıyısında Rum kalesi."
		},
		# === CASTLES ===
		"rumeli_hisari": {
			"name": "Rumeli Hisarı", "type": "castle", "owner": "ottoman",
			"position": Vector2(430, 790),
			"garrison": [{"troop_id": "topcu", "count": 15}, {"troop_id": "yeniceri", "count": 25}],
			"buildings": ["walls"],
			"income": 50, "population": 500, "loyalty": 100, "prosperity": 40,
			"coastal": true,
			"desc": "Boğazı kontrol eden stratejik kale."
		},
		"gelibolu": {
			"name": "Gelibolu", "type": "castle", "owner": "ottoman",
			"position": Vector2(310, 820),
			"garrison": [{"troop_id": "kapikulu_piyade", "count": 30}, {"troop_id": "topcu", "count": 10}],
			"buildings": ["walls", "shipyard"],
			"income": 80, "population": 2000, "loyalty": 90, "prosperity": 50,
			"coastal": true,
			"desc": "Çanakkale Boğazı'nı kontrol eden deniz üssü."
		},
		"iznik": {
			"name": "İznik", "type": "castle", "owner": "ottoman",
			"position": Vector2(480, 900),
			"garrison": [{"troop_id": "yaya_askeri", "count": 25}],
			"buildings": [],
			"income": 60, "population": 3000, "loyalty": 85, "prosperity": 45,
			"coastal": false,
			"desc": "Tarihi kale şehri. İlk ekümenik konsillerin yeri."
		},
		"sinop": {
			"name": "Sinop", "type": "castle", "owner": "ottoman",
			"position": Vector2(750, 680),
			"garrison": [{"troop_id": "okcu", "count": 20}, {"troop_id": "yaya_askeri", "count": 15}],
			"buildings": ["shipyard"],
			"income": 70, "population": 4000, "loyalty": 80, "prosperity": 40,
			"coastal": true,
			"desc": "Karadeniz'in en güvenli limanı."
		},
		# === SPECIAL REGIONS ===
		"arnavutluk": {
			"name": "Arnavutluk", "type": "city", "owner": "albania",
			"position": Vector2(105, 950),
			"garrison": [{"troop_id": "albanian_fighter", "count": 60}],
			"buildings": ["walls"],
			"income": 100, "population": 10000, "loyalty": 95, "prosperity": 35,
			"coastal": true,
			"desc": "İskender Bey'in dağ kalesi. Kolay fethedilemez."
		},
		"ege_adalari": {
			"name": "Ege Adaları", "type": "castle", "owner": "venice",
			"position": Vector2(300, 1200),
			"garrison": [{"troop_id": "venetian_crossbow", "count": 25}],
			"buildings": ["shipyard"],
			"income": 250, "population": 5000, "loyalty": 85, "prosperity": 60,
			"coastal": true,
			"desc": "Venedik'in Ege'deki ticaret üsleri."
		},
		"akkoyunlu_toprak": {
			"name": "Akkoyunlu Toprakları", "type": "city", "owner": "akkoyunlu",
			"position": Vector2(893, 1103),
			"garrison": [{"troop_id": "akkoyunlu_horseman", "count": 80}],
			"buildings": ["training"],
			"income": 200, "population": 20000, "loyalty": 90, "prosperity": 50,
			"coastal": false,
			"desc": "Uzun Hasan'ın doğu toprakları."
		},
	}

func _init_army():
	army = [
		{"troop_id": "yeniceri", "count": 30},
		{"troop_id": "kapikulu_piyade", "count": 50},
		{"troop_id": "timarli_sipahi", "count": 40},
		{"troop_id": "okcu", "count": 30},
		{"troop_id": "akinci", "count": 25},
		{"troop_id": "topcu", "count": 10},
	]

func _init_relations():
	relations = {
		"byzantine": -80,
		"karamanid": -30,
		"albania": -50,
		"venice": -20,
		"akkoyunlu": -10,
	}

# ════════════════════════════════════════════════════════════════════════
#                            QUERIES
# ════════════════════════════════════════════════════════════════════════

func get_army_count() -> int:
	var total := 0
	for unit in army:
		total += unit["count"]
	return total

func get_army_power() -> int:
	var power := 0
	for unit in army:
		if troop_defs.has(unit["troop_id"]):
			var td = troop_defs[unit["troop_id"]]
			power += unit["count"] * (td["attack"] + td["defense"])
		else:
			power += unit["count"] * 5
	return power

func get_army_daily_cost() -> int:
	var cost := 0
	for unit in army:
		if troop_defs.has(unit["troop_id"]):
			cost += unit["count"] * troop_defs[unit["troop_id"]]["cost"]
	return cost / 10  # per turn cost = total wage / 10

func get_garrison_power(sid: String) -> int:
	if not settlements.has(sid):
		return 0
	var power := 0
	var s = settlements[sid]
	for unit in s["garrison"]:
		if troop_defs.has(unit["troop_id"]):
			var td = troop_defs[unit["troop_id"]]
			power += unit["count"] * (td["attack"] + td["defense"])
		else:
			power += unit["count"] * 5
	# Defense bonus from walls
	if "walls" in s["buildings"]:
		power = int(power * 1.3)
	return power

func get_garrison_count(sid: String) -> int:
	if not settlements.has(sid):
		return 0
	var total := 0
	for unit in settlements[sid]["garrison"]:
		total += unit["count"]
	return total

func get_total_income() -> int:
	var income := 0
	for sid in settlements:
		var s = settlements[sid]
		if s["owner"] == player_faction:
			var bonus := 0
			if "market" in s["buildings"]:
				bonus += building_defs["market"]["effect"]["income_bonus"]
			income += s["income"] + bonus
	return income

func get_total_expenses() -> int:
	return get_army_daily_cost()

func get_net_income() -> int:
	return get_total_income() - get_total_expenses()

func get_owned_settlements() -> Array:
	var owned: Array = []
	for sid in settlements:
		if settlements[sid]["owner"] == player_faction:
			owned.append(sid)
	return owned

func get_faction_settlements(faction: String) -> Array:
	var owned: Array = []
	for sid in settlements:
		if settlements[sid]["owner"] == faction:
			owned.append(sid)
	return owned

func get_relation_text(faction: String) -> String:
	var rel = relations.get(faction, 0)
	if rel <= -60: return "Savaş"
	if rel <= -20: return "Düşman"
	if rel <= 20: return "Tarafsız"
	if rel <= 60: return "Dostça"
	return "Müttefik"

func get_relation_color(faction: String) -> Color:
	var rel = relations.get(faction, 0)
	if rel <= -60: return Color(0.9, 0.15, 0.15)
	if rel <= -20: return Color(0.9, 0.5, 0.2)
	if rel <= 20: return Color(0.8, 0.8, 0.6)
	if rel <= 60: return Color(0.3, 0.8, 0.4)
	return Color(0.2, 0.6, 0.9)

func get_settlement_type_icon(stype: String) -> String:
	match stype:
		"city": return "🏙"
		"castle": return "🏰"
		"village": return "🏘"
		_: return "📍"

# ════════════════════════════════════════════════════════════════════════
#                            ACTIONS
# ════════════════════════════════════════════════════════════════════════

func end_turn():
	turn += 1
	var income = get_net_income()
	gold += income
	gold_changed.emit(gold)

	# AI expansion logic
	for faction_id in factions:
		if faction_id == player_faction:
			continue
		if randf() < 0.12:
			_ai_attempt_attack(faction_id)

	# Morale decay/recovery
	if gold < 0:
		army_morale = max(10, army_morale - 5)
	else:
		army_morale = min(100, army_morale + 2)

	turn_ended.emit(turn, income)
	message.emit("Tur %d — Net gelir: %d altın" % [turn, income])

func _ai_attempt_attack(faction_id: String):
	var my_sids = get_faction_settlements(faction_id)
	if my_sids.is_empty():
		return
	# Try to attack a neighboring player settlement
	for sid in settlements:
		if settlements[sid]["owner"] == player_faction and randf() < 0.25:
			var ai_power = 0
			for s in my_sids:
				ai_power += get_garrison_power(s)
			var def_power = get_garrison_power(sid)
			if def_power == 0:
				def_power = 50
			var win_chance = float(ai_power) / float(ai_power + def_power + 1) * 0.3
			if randf() < win_chance:
				settlements[sid]["owner"] = faction_id
				settlement_lost.emit(sid, faction_id)
				message.emit("%s, %s tarafından ele geçirildi!" % [settlements[sid]["name"], factions[faction_id]["name"]])
			break

func attack_settlement(sid: String) -> Dictionary:
	if not settlements.has(sid):
		return {"success": false, "reason": "invalid"}
	var s = settlements[sid]
	if s["owner"] == player_faction:
		return {"success": false, "reason": "own_settlement"}

	var att_power = get_army_power()
	var def_power = get_garrison_power(sid)
	if def_power == 0:
		def_power = 30

	# Leadership bonus
	var leadership_bonus = 1.0 + player_stats["leadership"] * 0.03
	att_power = int(att_power * leadership_bonus)

	var win_prob = float(att_power) / float(att_power + def_power + 1)
	var roll = randf()
	var won = roll < win_prob

	# Calculate losses
	var att_loss_ratio = 0.1 + (1.0 - win_prob) * 0.3
	var def_loss_ratio = 0.3 + win_prob * 0.4

	var result = {
		"success": won,
		"att_power": att_power,
		"def_power": def_power,
		"win_prob": win_prob,
		"att_losses": int(get_army_count() * att_loss_ratio),
		"def_losses": int(get_garrison_count(sid) * def_loss_ratio),
		"loot": 0,
		"settlement_name": s["name"],
	}

	if won:
		s["owner"] = player_faction
		gold += 200 + s["income"]
		result["loot"] = 200 + s["income"]
		gold_changed.emit(gold)
		settlement_conquered.emit(sid, s["name"])
		if sid == "istanbul":
			message.emit("☽ İSTANBUL FETHEDİLDİ! BÜYÜK ZAFER! ☽")
		else:
			message.emit("Zafer! %s fethedildi!" % s["name"])
	else:
		message.emit("Yenilgi! Ordular geri çekildi.")

	# Apply losses to army
	_apply_army_losses(result["att_losses"])
	# Apply losses to garrison
	_apply_garrison_losses(sid, result["def_losses"])

	battle_result.emit(won, result)
	return result

func _apply_army_losses(total_loss: int):
	var remaining_loss = total_loss
	for i in range(army.size() - 1, -1, -1):
		if remaining_loss <= 0:
			break
		var unit = army[i]
		var loss = min(unit["count"], remaining_loss)
		unit["count"] -= loss
		remaining_loss -= loss
		if unit["count"] <= 0:
			army.remove_at(i)

func _apply_garrison_losses(sid: String, total_loss: int):
	if not settlements.has(sid):
		return
	var garrison = settlements[sid]["garrison"]
	var remaining_loss = total_loss
	for i in range(garrison.size() - 1, -1, -1):
		if remaining_loss <= 0:
			break
		var unit = garrison[i]
		var loss = min(unit["count"], remaining_loss)
		unit["count"] -= loss
		remaining_loss -= loss
		if unit["count"] <= 0:
			garrison.remove_at(i)

func try_diplomacy(faction_id: String) -> bool:
	if not factions.has(faction_id) or faction_id == player_faction:
		return false
	var cost = 500
	if gold >= cost:
		gold -= cost
		relations[faction_id] = min(100, relations.get(faction_id, 0) + 20)
		gold_changed.emit(gold)
		message.emit("Elçi gönderildi! %s ile ilişkiler iyileşti." % factions[faction_id]["name"])
		return true
	else:
		message.emit("Yetersiz altın! (%d gerekli)" % cost)
		return false

func declare_war(faction_id: String):
	if factions.has(faction_id) and faction_id != player_faction:
		relations[faction_id] = -100
		message.emit("%s'a savaş ilan edildi!" % factions[faction_id]["name"])

func propose_peace(faction_id: String) -> bool:
	if not factions.has(faction_id) or faction_id == player_faction:
		return false
	var cost = 1000
	if gold >= cost:
		gold -= cost
		relations[faction_id] = 0
		gold_changed.emit(gold)
		message.emit("%s ile barış yapıldı." % factions[faction_id]["name"])
		return true
	message.emit("Yetersiz altın! (%d gerekli)" % cost)
	return false

func build_in_settlement(sid: String, building_id: String) -> bool:
	if not settlements.has(sid) or not building_defs.has(building_id):
		return false
	var s = settlements[sid]
	if s["owner"] != player_faction:
		return false
	if building_id in s["buildings"]:
		message.emit("Bu bina zaten mevcut!")
		return false
	var bdef = building_defs[building_id]
	if building_id == "shipyard" and not s.get("coastal", false):
		message.emit("Tersane sadece kıyı yerleşimlerinde inşa edilebilir!")
		return false
	if gold >= bdef["cost"]:
		gold -= bdef["cost"]
		s["buildings"].append(building_id)
		gold_changed.emit(gold)
		message.emit("%s inşa edildi: %s" % [bdef["name"], s["name"]])
		return true
	message.emit("Yetersiz altın! (%d gerekli)" % bdef["cost"])
	return false

func recruit_troops(sid: String, troop_id: String, count: int) -> bool:
	if not settlements.has(sid) or not troop_defs.has(troop_id):
		return false
	var s = settlements[sid]
	if s["owner"] != player_faction:
		return false
	var td = troop_defs[troop_id]
	var total_cost = td["cost"] * count
	if gold < total_cost:
		message.emit("Yetersiz altın! (%d gerekli)" % total_cost)
		return false
	if get_army_count() + count > army_max:
		message.emit("Ordu kapasitesi dolu! (Maks: %d)" % army_max)
		return false
	gold -= total_cost
	# Add to army
	var found = false
	for unit in army:
		if unit["troop_id"] == troop_id:
			unit["count"] += count
			found = true
			break
	if not found:
		army.append({"troop_id": troop_id, "count": count})
	gold_changed.emit(gold)
	message.emit("%d %s orduya katıldı!" % [count, td["name"]])
	return true

func upgrade_troops(troop_id: String, count: int) -> bool:
	if not troop_defs.has(troop_id):
		return false
	var td = troop_defs[troop_id]
	if td["upgrade_to"] == "":
		return false
	var total_cost = td["upgrade_cost"] * count
	if gold < total_cost:
		message.emit("Yetersiz altın! (%d gerekli)" % total_cost)
		return false
	# Find unit in army
	for unit in army:
		if unit["troop_id"] == troop_id:
			var actual = min(count, unit["count"])
			if actual <= 0:
				return false
			gold -= td["upgrade_cost"] * actual
			unit["count"] -= actual
			# Add upgraded troops
			var found = false
			for u2 in army:
				if u2["troop_id"] == td["upgrade_to"]:
					u2["count"] += actual
					found = true
					break
			if not found:
				army.append({"troop_id": td["upgrade_to"], "count": actual})
			# Remove empty entries
			if unit["count"] <= 0:
				army.erase(unit)
			gold_changed.emit(gold)
			message.emit("%d %s → %s yükseltildi!" % [actual, td["name"], troop_defs[td["upgrade_to"]]["name"]])
			return true
	return false
