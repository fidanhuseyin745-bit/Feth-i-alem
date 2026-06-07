class_name GameState
extends RefCounted

## Pure game-logic class with no Godot-node dependencies.
## Extracted so that it can be unit-tested with GUT.

signal turn_ended(turn: int, income: int)
signal region_conquered(region_id: String, region_name: String)
signal region_lost(region_id: String, faction: String)
signal message(text: String)

var turn: int = 1
var gold: int = 5000
var selected_region: String = ""

var regions: Dictionary = {}
var factions: Dictionary = {}


func _init() -> void:
	_init_factions()
	_init_regions()


func _init_factions() -> void:
	factions = {
		"ottoman": {"name": "Osmanli", "color": Color(0.9, 0.7, 0.1)},
		"byzantine": {"name": "Bizans", "color": Color(0.3, 0.5, 0.9)},
		"karamanid": {"name": "Karamanoglu", "color": Color(0.2, 0.7, 0.4)},
		"albania": {"name": "Arnavutluk", "color": Color(0.85, 0.2, 0.2)},
		"venice": {"name": "Venedik", "color": Color(0.6, 0.3, 0.8)},
		"akkoyunlu": {"name": "Akkoyunlu", "color": Color(0.9, 0.5, 0.1)},
	}


func _init_regions() -> void:
	regions = {
		"istanbul": {"name": "Istanbul", "owner": "byzantine", "troops": 3000, "income": 500},
		"edirne": {"name": "Edirne", "owner": "ottoman", "troops": 5000, "income": 300},
		"bursa": {"name": "Bursa", "owner": "ottoman", "troops": 2000, "income": 200},
		"selanik": {"name": "Selanik", "owner": "ottoman", "troops": 1500, "income": 180},
		"karaman": {"name": "Karaman", "owner": "karamanid", "troops": 2500, "income": 160},
		"arnavutluk": {"name": "Arnavutluk", "owner": "albania", "troops": 1800, "income": 100},
		"venedik_adalar": {"name": "Ege Adalari", "owner": "venice", "troops": 1200, "income": 250},
		"akkoyunlu": {"name": "Akkoyunlu", "owner": "akkoyunlu", "troops": 4000, "income": 200},
	}


# ── Queries ──────────────────────────────────────────────────────────────

func get_ottoman_total_troops() -> int:
	var total := 0
	for r in regions.values():
		if r["owner"] == "ottoman":
			total += r["troops"]
	return total


func get_ottoman_income() -> int:
	var income := 0
	for r in regions.values():
		if r["owner"] == "ottoman":
			income += r["income"]
	return income


func get_faction_total_troops(faction: String) -> int:
	var total := 0
	for r in regions.values():
		if r["owner"] == faction:
			total += r["troops"]
	return total


func get_regions_owned_by(faction: String) -> Array:
	var owned: Array = []
	for rid in regions:
		if regions[rid]["owner"] == faction:
			owned.append(rid)
	return owned


func get_faction_display_name(faction_id: String) -> String:
	if factions.has(faction_id):
		return factions[faction_id]["name"]
	return faction_id


func get_region_info_text(region_id: String) -> String:
	if not regions.has(region_id):
		return ""
	var data: Dictionary = regions[region_id]
	var fname := get_faction_display_name(data["owner"])
	return "Sahip: %s\nAsker: %d\nGelir: %d/tur" % [fname, data["troops"], data["income"]]


func gold_label_text() -> String:
	return "🪙 %d" % gold


func turn_label_text() -> String:
	return "Tur: %d" % turn


# ── Win-probability (deterministic helper for testing) ───────────────────

func compute_win_probability(region_id: String) -> float:
	if not regions.has(region_id):
		return 0.0
	var defender_troops: int = regions[region_id]["troops"]
	var attacker_troops: int = get_ottoman_total_troops()
	return float(attacker_troops) / float(attacker_troops + defender_troops + 1)


# ── Actions ──────────────────────────────────────────────────────────────

func end_turn() -> void:
	turn += 1
	var income := get_ottoman_income()
	gold += income
	turn_ended.emit(turn, income)
	message.emit("Tur %d — +%d altin" % [turn, income])


func try_attack(region_id: String, rng_roll: float) -> bool:
	if region_id == "" or not regions.has(region_id):
		return false
	var data: Dictionary = regions[region_id]
	if data["owner"] == "ottoman":
		return false
	var win_prob := compute_win_probability(region_id)
	if rng_roll < win_prob:
		data["owner"] = "ottoman"
		data["color_owner"] = factions["ottoman"]["color"]
		gold += 200
		region_conquered.emit(region_id, data["name"])
		if region_id == "istanbul":
			message.emit("ISTANBUL FETHEDILDI! BUYUK ZAFER!")
		else:
			message.emit("Zafer! %s fethedildi!" % data["name"])
		return true
	else:
		message.emit("Yenilgi! Ordular geri cekildi.")
		return false


func try_diplomacy(region_id: String) -> bool:
	if region_id == "" or not regions.has(region_id):
		return false
	if gold >= 500:
		gold -= 500
		message.emit("Elci gonderildi! Iliskiler iyilesti.")
		return true
	else:
		message.emit("Yetersiz altin! (500 gerekli)")
		return false


func try_build(region_id: String) -> bool:
	if region_id == "" or not regions.has(region_id):
		return false
	var data: Dictionary = regions[region_id]
	if data["owner"] != "ottoman":
		return false
	if gold >= 300:
		gold -= 300
		data["troops"] += 500
		data["income"] += 50
		message.emit("Insaat tamam! Asker ve gelir artti.")
		return true
	else:
		message.emit("Yetersiz altin! (300 gerekli)")
		return false


func simulate_enemy_turn(rng_attack_chance: float, rng_target_chance: float, rng_win_roll: float) -> void:
	for faction in ["byzantine", "karamanid", "albania", "venice", "akkoyunlu"]:
		if rng_attack_chance < 0.15:
			for rid in regions:
				if regions[rid]["owner"] == "ottoman" and rng_target_chance < 0.3:
					var attacker_troops := get_faction_total_troops(faction)
					var defender_troops: int = regions[rid]["troops"]
					var threshold := float(attacker_troops) / float(attacker_troops + defender_troops + 1) * 0.4
					if rng_win_roll < threshold:
						regions[rid]["owner"] = faction
						if factions.has(faction):
							regions[rid]["color_owner"] = factions[faction]["color"]
						region_lost.emit(rid, faction)
					break
